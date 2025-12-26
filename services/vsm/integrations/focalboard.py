"""
Focalboard integration for VSM service.

This module provides webhook handlers and API integration for bidirectional
sync between Focalboard boards and VSM work items.

Note: This is an initial implementation. The Focalboard API client functions
(_fetch_focalboard_cards, sync_work_item_to_focalboard) are placeholder
implementations that need to be completed with actual HTTP API calls to
Focalboard/Mattermost.
"""
import logging
from datetime import datetime, timezone
from typing import Optional, Dict, Any, List
from enum import Enum

import httpx  # Required for future Focalboard API integration
from fastapi import APIRouter, HTTPException, Depends, BackgroundTasks
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import WorkItem, Stage, StageTransition, WorkItemType
from app.schemas import WorkItemCreate

logger = logging.getLogger(__name__)

# Focalboard configuration
FOCALBOARD_API_URL = "http://mattermost.fawkes.svc:8065/api/v2"  # Focalboard is bundled with Mattermost

# Create router for Focalboard integration
router = APIRouter(prefix="/api/v1/focalboard", tags=["Focalboard Integration"])


class FocalboardCardAction(str, Enum):
    """Focalboard card webhook actions."""

    CREATED = "card.created"
    UPDATED = "card.updated"
    MOVED = "card.moved"
    DELETED = "card.deleted"


class FocalboardColumnStageMapping:
    """Map Focalboard columns to VSM stages."""

    # Default column to stage mapping
    COLUMN_TO_STAGE = {
        "backlog": "Backlog",
        "design": "Design",
        "development": "Development",
        "code review": "Code Review",
        "testing": "Testing",
        "deployment approval": "Deployment Approval",
        "deploy": "Deploy",
        "production": "Production",
        "done": "Production",
        "to do": "Backlog",
        "in progress": "Development",
        "in review": "Code Review",
    }

    @classmethod
    def get_stage(cls, column_name: str) -> Optional[str]:
        """
        Get VSM stage name from Focalboard column name.

        Args:
            column_name: Focalboard column name (case-insensitive)

        Returns:
            VSM stage name or None if not mapped
        """
        normalized = column_name.lower().strip()
        return cls.COLUMN_TO_STAGE.get(normalized)

    @classmethod
    def get_column(cls, stage_name: str) -> Optional[str]:
        """
        Get Focalboard column name from VSM stage name.

        Args:
            stage_name: VSM stage name

        Returns:
            Focalboard column name or None if not mapped
        """
        # Reverse lookup
        for column, stage in cls.COLUMN_TO_STAGE.items():
            if stage == stage_name:
                return column.title()
        return None


# Webhook payload schemas
class FocalboardCard(BaseModel):
    """Focalboard card model."""

    id: str = Field(..., description="Card ID")
    title: str = Field(..., description="Card title")
    board_id: str = Field(..., alias="boardId", description="Board ID")
    status: str = Field(..., description="Column/status name")
    type: Optional[str] = Field(None, description="Card type")
    created_at: int = Field(..., alias="createAt", description="Creation timestamp (ms)")
    updated_at: int = Field(..., alias="updateAt", description="Update timestamp (ms)")

    class Config:
        populate_by_name = True


class FocalboardWebhookPayload(BaseModel):
    """Focalboard webhook payload."""

    action: str = Field(..., description="Webhook action")
    card: FocalboardCard = Field(..., description="Card data")
    board_id: str = Field(..., alias="boardId", description="Board ID")
    workspace_id: str = Field(..., alias="workspaceId", description="Workspace ID")

    class Config:
        populate_by_name = True


class FocalboardSyncRequest(BaseModel):
    """Request to sync a specific Focalboard board."""

    board_id: str = Field(..., description="Focalboard board ID to sync")
    workspace_id: Optional[str] = Field(None, description="Workspace ID")


class FocalboardSyncResponse(BaseModel):
    """Response from board sync operation."""

    status: str = Field(..., description="Sync status")
    synced_count: int = Field(..., description="Number of cards synced")
    failed_count: int = Field(0, description="Number of cards that failed to sync")
    details: List[str] = Field(default_factory=list, description="Sync details")


@router.post("/webhook", status_code=200)
async def handle_focalboard_webhook(
    payload: FocalboardWebhookPayload, background_tasks: BackgroundTasks, db: Session = Depends(get_db)
):
    """
    Handle incoming Focalboard webhooks.

    This endpoint receives webhooks from Focalboard when cards are created,
    updated, moved, or deleted, and syncs them to VSM work items.

    Args:
        payload: Webhook payload from Focalboard
        background_tasks: FastAPI background tasks
        db: Database session

    Returns:
        Acknowledgment response
    """
    try:
        logger.info(f"Received Focalboard webhook: action={payload.action}, card={payload.card.id}")

        # Process webhook based on action
        if payload.action == FocalboardCardAction.CREATED:
            await _handle_card_created(payload.card, db)
        elif payload.action == FocalboardCardAction.MOVED:
            await _handle_card_moved(payload.card, db)
        elif payload.action == FocalboardCardAction.UPDATED:
            await _handle_card_updated(payload.card, db)
        elif payload.action == FocalboardCardAction.DELETED:
            await _handle_card_deleted(payload.card, db)
        else:
            logger.warning(f"Unknown webhook action: {payload.action}")

        return {"status": "success", "message": f"Webhook processed: {payload.action}", "card_id": payload.card.id}

    except Exception as e:
        logger.error(f"Failed to process Focalboard webhook: {e}", exc_info=True)
        # Return 200 to avoid webhook retries for unrecoverable errors
        return {"status": "error", "message": str(e), "card_id": payload.card.id}


async def _handle_card_created(card: FocalboardCard, db: Session):
    """
    Handle card creation webhook.

    Creates a new VSM work item for the Focalboard card.
    """
    # Map card type to work item type
    work_item_type = WorkItemType.TASK
    if card.type:
        type_lower = card.type.lower()
        if "feature" in type_lower:
            work_item_type = WorkItemType.FEATURE
        elif "bug" in type_lower:
            work_item_type = WorkItemType.BUG
        elif "epic" in type_lower:
            work_item_type = WorkItemType.EPIC

    # Create work item
    work_item = WorkItem(title=card.title, type=work_item_type)
    db.add(work_item)
    db.commit()
    db.refresh(work_item)

    # Map Focalboard column to VSM stage and create initial transition
    stage_name = FocalboardColumnStageMapping.get_stage(card.status)
    if not stage_name:
        stage_name = "Backlog"  # Default to Backlog if mapping not found

    stage = db.query(Stage).filter(Stage.name == stage_name).first()
    if stage:
        transition = StageTransition(work_item_id=work_item.id, from_stage_id=None, to_stage_id=stage.id)
        db.add(transition)
        db.commit()

    logger.info(f"Created work item {work_item.id} from Focalboard card {card.id}")


async def _handle_card_moved(card: FocalboardCard, db: Session):
    """
    Handle card movement webhook.

    Updates the VSM work item stage when a card is moved between columns.
    """
    # Find work item by matching title (Focalboard card ID could be stored in future)
    work_item = db.query(WorkItem).filter(WorkItem.title == card.title).first()

    if not work_item:
        logger.warning(f"Work item not found for Focalboard card: {card.id}")
        # Create new work item if not exists
        await _handle_card_created(card, db)
        return

    # Get current stage
    current_transition = (
        db.query(StageTransition)
        .filter(StageTransition.work_item_id == work_item.id)
        .order_by(StageTransition.timestamp.desc())
        .first()
    )

    # Map new column to stage
    new_stage_name = FocalboardColumnStageMapping.get_stage(card.status)
    if not new_stage_name:
        logger.warning(f"No stage mapping found for column: {card.status}")
        return

    new_stage = db.query(Stage).filter(Stage.name == new_stage_name).first()
    if not new_stage:
        logger.error(f"Stage not found: {new_stage_name}")
        return

    # Check if already in target stage
    if current_transition and current_transition.to_stage_id == new_stage.id:
        logger.info(f"Work item {work_item.id} already in stage {new_stage_name}")
        return

    # Create transition
    from_stage_id = current_transition.to_stage_id if current_transition else None
    transition = StageTransition(work_item_id=work_item.id, from_stage_id=from_stage_id, to_stage_id=new_stage.id)
    db.add(transition)

    # Update work item timestamp
    work_item.updated_at = datetime.now(timezone.utc)

    db.commit()

    logger.info(f"Moved work item {work_item.id} to stage {new_stage_name}")


async def _handle_card_updated(card: FocalboardCard, db: Session):
    """
    Handle card update webhook.

    Updates the VSM work item when a card is updated.
    """
    # Find work item by title
    work_item = db.query(WorkItem).filter(WorkItem.title == card.title).first()

    if not work_item:
        logger.warning(f"Work item not found for Focalboard card: {card.id}")
        return

    # Update work item timestamp
    work_item.updated_at = datetime.now(timezone.utc)
    db.commit()

    logger.info(f"Updated work item {work_item.id} from Focalboard card {card.id}")


async def _handle_card_deleted(card: FocalboardCard, db: Session):
    """
    Handle card deletion webhook.

    Note: We don't delete VSM work items when Focalboard cards are deleted
    to preserve historical data. We could add a 'deleted' flag in the future.
    """
    logger.info(f"Card deleted in Focalboard: {card.id}. VSM work item preserved for history.")


@router.post("/sync", response_model=FocalboardSyncResponse)
async def sync_focalboard_board(request: FocalboardSyncRequest, db: Session = Depends(get_db)):
    """
    Manually sync a Focalboard board to VSM.

    This endpoint allows manual synchronization of all cards from a
    Focalboard board to VSM work items.

    Args:
        request: Sync request with board ID
        db: Database session

    Returns:
        Sync status and statistics
    """
    try:
        logger.info(f"Starting manual sync for Focalboard board: {request.board_id}")

        # Fetch cards from Focalboard API
        cards = await _fetch_focalboard_cards(request.board_id)

        synced_count = 0
        failed_count = 0
        details = []

        for card_data in cards:
            try:
                card = FocalboardCard(**card_data)

                # Check if work item already exists
                existing = db.query(WorkItem).filter(WorkItem.title == card.title).first()

                if existing:
                    details.append(f"Card '{card.title}' already exists as work item {existing.id}")
                else:
                    await _handle_card_created(card, db)
                    synced_count += 1
                    details.append(f"Created work item for card '{card.title}'")

            except Exception as e:
                failed_count += 1
                details.append(f"Failed to sync card: {str(e)}")
                logger.error(f"Failed to sync card: {e}", exc_info=True)

        return FocalboardSyncResponse(
            status="completed", synced_count=synced_count, failed_count=failed_count, details=details
        )

    except Exception as e:
        logger.error(f"Failed to sync Focalboard board: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Sync failed: {str(e)}")


async def _fetch_focalboard_cards(board_id: str) -> List[Dict[str, Any]]:
    """
    Fetch cards from Focalboard API.

    TODO: Implement actual Focalboard API integration using httpx.
    This requires:
    1. Focalboard/Mattermost API authentication (token or session)
    2. GET request to /api/v2/boards/{board_id}/cards
    3. Error handling for network/API failures
    4. Pagination support for large boards

    Args:
        board_id: Focalboard board ID

    Returns:
        List of card data dictionaries

    Example implementation:
        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"{FOCALBOARD_API_URL}/boards/{board_id}/cards",
                headers={"Authorization": f"Bearer {api_token}"}
            )
            response.raise_for_status()
            return response.json()
    """
    # PLACEHOLDER: Return empty list until API integration is implemented
    logger.warning("Focalboard API integration not fully implemented - returning empty list")
    return []


@router.get("/work-items/{work_item_id}/sync-to-focalboard")
async def sync_work_item_to_focalboard(work_item_id: int, db: Session = Depends(get_db)):
    """
    Sync a VSM work item to Focalboard.

    This endpoint pushes a VSM work item's current state to Focalboard,
    creating or updating the corresponding card.

    Args:
        work_item_id: VSM work item ID
        db: Database session

    Returns:
        Sync status
    """
    try:
        # Verify work item exists
        work_item = db.query(WorkItem).filter(WorkItem.id == work_item_id).first()
        if not work_item:
            raise HTTPException(status_code=404, detail=f"Work item {work_item_id} not found")

        # Get current stage
        current_transition = (
            db.query(StageTransition)
            .filter(StageTransition.work_item_id == work_item_id)
            .order_by(StageTransition.timestamp.desc())
            .first()
        )

        stage_name = None
        if current_transition:
            stage = db.query(Stage).filter(Stage.id == current_transition.to_stage_id).first()
            if stage:
                stage_name = stage.name

        # Map stage to Focalboard column
        column_name = FocalboardColumnStageMapping.get_column(stage_name) if stage_name else "Backlog"

        # TODO: Implement actual Focalboard API push using httpx
        # This should:
        # 1. Find or create card in Focalboard for this work item
        # 2. Update card properties (title, status/column, custom fields)
        # 3. Handle API authentication and error cases
        # Example:
        #   async with httpx.AsyncClient() as client:
        #       await client.patch(
        #           f"{FOCALBOARD_API_URL}/cards/{card_id}",
        #           json={"properties": {"status": column_name}},
        #           headers={"Authorization": f"Bearer {api_token}"}
        #       )

        # PLACEHOLDER: Return success without actual API call
        logger.info(f"Would sync work item {work_item_id} to Focalboard column '{column_name}'")

        return {
            "status": "success",
            "work_item_id": work_item_id,
            "focalboard_column": column_name,
            "message": "Sync to Focalboard (placeholder - API integration not fully implemented)",
        }
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to sync work item to Focalboard: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Sync failed: {str(e)}")


@router.get("/stages/mapping")
async def get_stage_column_mapping():
    """
    Get the mapping between VSM stages and Focalboard columns.

    Returns:
        Stage to column mapping
    """
    return {
        "column_to_stage": FocalboardColumnStageMapping.COLUMN_TO_STAGE,
        "description": "Map of Focalboard column names (lowercase) to VSM stage names",
    }
