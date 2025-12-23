"""Main FastAPI application for Insights service."""
import os
from typing import List, Optional
from fastapi import FastAPI, Depends, HTTPException, Query, status
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from sqlalchemy import or_, func
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST
from fastapi.responses import Response
import logging

from app import __version__
from app.database import get_db, check_db_connection
from app.models import Insight, Tag, Category, insight_tags
from app.schemas import (
    InsightCreate, InsightUpdate, InsightResponse, InsightListResponse, InsightSearchRequest,
    TagCreate, TagUpdate, TagResponse,
    CategoryCreate, CategoryUpdate, CategoryResponse,
    InsightStatistics, HealthResponse
)

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Prometheus metrics
insights_created = Counter('insights_created_total', 'Total number of insights created')
insights_updated = Counter('insights_updated_total', 'Total number of insights updated')
insights_deleted = Counter('insights_deleted_total', 'Total number of insights deleted')
api_requests = Counter('api_requests_total', 'Total API requests', ['method', 'endpoint'])
request_duration = Histogram('request_duration_seconds', 'Request duration', ['method', 'endpoint'])

# Create FastAPI app
app = FastAPI(
    title="Fawkes Insights Service",
    description="Database and tracking system for capturing, organizing, and tracking insights",
    version=__version__,
    docs_url="/docs",
    redoc_url="/redoc",
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure appropriately for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Health check endpoint
@app.get("/health", response_model=HealthResponse, tags=["Health"])
async def health_check(db: Session = Depends(get_db)):
    """Health check endpoint."""
    return HealthResponse(
        status="healthy",
        service="insights",
        version=__version__,
        database_connected=check_db_connection()
    )


# Metrics endpoint
@app.get("/metrics", tags=["Metrics"])
async def metrics():
    """Prometheus metrics endpoint."""
    return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)


# Tag endpoints
@app.post("/tags", response_model=TagResponse, status_code=status.HTTP_201_CREATED, tags=["Tags"])
async def create_tag(tag_data: TagCreate, db: Session = Depends(get_db)):
    """Create a new tag."""
    # Check if tag already exists
    existing_tag = db.query(Tag).filter(
        or_(Tag.name == tag_data.name, Tag.slug == tag_data.slug)
    ).first()
    if existing_tag:
        raise HTTPException(status_code=400, detail="Tag with this name or slug already exists")
    
    tag = Tag(**tag_data.model_dump())
    db.add(tag)
    db.commit()
    db.refresh(tag)
    return tag


@app.get("/tags", response_model=List[TagResponse], tags=["Tags"])
async def list_tags(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=1000),
    db: Session = Depends(get_db)
):
    """List all tags."""
    tags = db.query(Tag).order_by(Tag.name).offset(skip).limit(limit).all()
    return tags


@app.get("/tags/{tag_id}", response_model=TagResponse, tags=["Tags"])
async def get_tag(tag_id: int, db: Session = Depends(get_db)):
    """Get a specific tag by ID."""
    tag = db.query(Tag).filter(Tag.id == tag_id).first()
    if not tag:
        raise HTTPException(status_code=404, detail="Tag not found")
    return tag


@app.put("/tags/{tag_id}", response_model=TagResponse, tags=["Tags"])
async def update_tag(tag_id: int, tag_data: TagUpdate, db: Session = Depends(get_db)):
    """Update a tag."""
    tag = db.query(Tag).filter(Tag.id == tag_id).first()
    if not tag:
        raise HTTPException(status_code=404, detail="Tag not found")
    
    update_data = tag_data.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(tag, field, value)
    
    db.commit()
    db.refresh(tag)
    return tag


@app.delete("/tags/{tag_id}", status_code=status.HTTP_204_NO_CONTENT, tags=["Tags"])
async def delete_tag(tag_id: int, db: Session = Depends(get_db)):
    """Delete a tag."""
    tag = db.query(Tag).filter(Tag.id == tag_id).first()
    if not tag:
        raise HTTPException(status_code=404, detail="Tag not found")
    
    db.delete(tag)
    db.commit()


# Category endpoints
@app.post("/categories", response_model=CategoryResponse, status_code=status.HTTP_201_CREATED, tags=["Categories"])
async def create_category(category_data: CategoryCreate, db: Session = Depends(get_db)):
    """Create a new category."""
    # Check if category already exists
    existing_category = db.query(Category).filter(
        or_(Category.name == category_data.name, Category.slug == category_data.slug)
    ).first()
    if existing_category:
        raise HTTPException(status_code=400, detail="Category with this name or slug already exists")
    
    category = Category(**category_data.model_dump())
    db.add(category)
    db.commit()
    db.refresh(category)
    return category


@app.get("/categories", response_model=List[CategoryResponse], tags=["Categories"])
async def list_categories(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=1000),
    db: Session = Depends(get_db)
):
    """List all categories."""
    categories = db.query(Category).order_by(Category.name).offset(skip).limit(limit).all()
    
    # Add insight count to each category
    result = []
    for category in categories:
        category_dict = CategoryResponse.model_validate(category).model_dump()
        insight_count = db.query(Insight).filter(Insight.category_id == category.id).count()
        category_dict['insight_count'] = insight_count
        result.append(CategoryResponse(**category_dict))
    
    return result


@app.get("/categories/{category_id}", response_model=CategoryResponse, tags=["Categories"])
async def get_category(category_id: int, db: Session = Depends(get_db)):
    """Get a specific category by ID."""
    category = db.query(Category).filter(Category.id == category_id).first()
    if not category:
        raise HTTPException(status_code=404, detail="Category not found")
    
    category_dict = CategoryResponse.model_validate(category).model_dump()
    insight_count = db.query(Insight).filter(Insight.category_id == category.id).count()
    category_dict['insight_count'] = insight_count
    return CategoryResponse(**category_dict)


@app.put("/categories/{category_id}", response_model=CategoryResponse, tags=["Categories"])
async def update_category(category_id: int, category_data: CategoryUpdate, db: Session = Depends(get_db)):
    """Update a category."""
    category = db.query(Category).filter(Category.id == category_id).first()
    if not category:
        raise HTTPException(status_code=404, detail="Category not found")
    
    update_data = category_data.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(category, field, value)
    
    db.commit()
    db.refresh(category)
    return category


@app.delete("/categories/{category_id}", status_code=status.HTTP_204_NO_CONTENT, tags=["Categories"])
async def delete_category(category_id: int, db: Session = Depends(get_db)):
    """Delete a category."""
    category = db.query(Category).filter(Category.id == category_id).first()
    if not category:
        raise HTTPException(status_code=404, detail="Category not found")
    
    # Check if category has insights
    insight_count = db.query(Insight).filter(Insight.category_id == category.id).count()
    if insight_count > 0:
        raise HTTPException(
            status_code=400,
            detail=f"Cannot delete category with {insight_count} insights. Remove insights first."
        )
    
    db.delete(category)
    db.commit()


# Insight endpoints
@app.post("/insights", response_model=InsightResponse, status_code=status.HTTP_201_CREATED, tags=["Insights"])
async def create_insight(insight_data: InsightCreate, db: Session = Depends(get_db)):
    """Create a new insight."""
    # Extract tag IDs
    tag_ids = insight_data.tag_ids if hasattr(insight_data, 'tag_ids') else []
    insight_dict = insight_data.model_dump(exclude={'tag_ids'})
    
    # Create insight
    insight = Insight(**insight_dict)
    
    # Add tags
    if tag_ids:
        tags = db.query(Tag).filter(Tag.id.in_(tag_ids)).all()
        insight.tags = tags
        
        # Update tag usage counts
        for tag in tags:
            tag.usage_count += 1
    
    db.add(insight)
    db.commit()
    db.refresh(insight)
    
    insights_created.inc()
    return insight


@app.get("/insights", response_model=InsightListResponse, tags=["Insights"])
async def list_insights(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    status: Optional[str] = None,
    priority: Optional[str] = None,
    category_id: Optional[int] = None,
    author: Optional[str] = None,
    db: Session = Depends(get_db)
):
    """List insights with pagination and filters."""
    query = db.query(Insight)
    
    # Apply filters
    if status:
        query = query.filter(Insight.status == status)
    if priority:
        query = query.filter(Insight.priority == priority)
    if category_id:
        query = query.filter(Insight.category_id == category_id)
    if author:
        query = query.filter(Insight.author.ilike(f"%{author}%"))
    
    # Get total count
    total = query.count()
    
    # Apply pagination
    offset = (page - 1) * page_size
    insights = query.order_by(Insight.created_at.desc()).offset(offset).limit(page_size).all()
    
    return InsightListResponse(
        total=total,
        page=page,
        page_size=page_size,
        insights=insights
    )


@app.post("/insights/search", response_model=InsightListResponse, tags=["Insights"])
async def search_insights(search_request: InsightSearchRequest, db: Session = Depends(get_db)):
    """Search insights with advanced filters."""
    query = db.query(Insight)
    
    # Text search
    if search_request.query:
        search_term = f"%{search_request.query}%"
        query = query.filter(
            or_(
                Insight.title.ilike(search_term),
                Insight.description.ilike(search_term),
                Insight.content.ilike(search_term)
            )
        )
    
    # Apply filters
    if search_request.category_id:
        query = query.filter(Insight.category_id == search_request.category_id)
    if search_request.priority:
        query = query.filter(Insight.priority == search_request.priority)
    if search_request.status:
        query = query.filter(Insight.status == search_request.status)
    if search_request.author:
        query = query.filter(Insight.author.ilike(f"%{search_request.author}%"))
    
    # Filter by tags (AND logic - insight must have all specified tags)
    if search_request.tag_ids:
        for tag_id in search_request.tag_ids:
            query = query.filter(Insight.tags.any(Tag.id == tag_id))
    
    # Get total count
    total = query.count()
    
    # Apply pagination
    offset = (search_request.page - 1) * search_request.page_size
    insights = query.order_by(Insight.created_at.desc()).offset(offset).limit(search_request.page_size).all()
    
    return InsightListResponse(
        total=total,
        page=search_request.page,
        page_size=search_request.page_size,
        insights=insights
    )


@app.get("/insights/{insight_id}", response_model=InsightResponse, tags=["Insights"])
async def get_insight(insight_id: int, db: Session = Depends(get_db)):
    """Get a specific insight by ID."""
    insight = db.query(Insight).filter(Insight.id == insight_id).first()
    if not insight:
        raise HTTPException(status_code=404, detail="Insight not found")
    return insight


@app.put("/insights/{insight_id}", response_model=InsightResponse, tags=["Insights"])
async def update_insight(insight_id: int, insight_data: InsightUpdate, db: Session = Depends(get_db)):
    """Update an insight."""
    insight = db.query(Insight).filter(Insight.id == insight_id).first()
    if not insight:
        raise HTTPException(status_code=404, detail="Insight not found")
    
    # Handle tag updates
    update_data = insight_data.model_dump(exclude_unset=True, exclude={'tag_ids'})
    
    if hasattr(insight_data, 'tag_ids') and insight_data.tag_ids is not None:
        # Update tag usage counts
        old_tags = set(tag.id for tag in insight.tags)
        new_tags = set(insight_data.tag_ids)
        
        # Decrease count for removed tags
        for tag_id in old_tags - new_tags:
            tag = db.query(Tag).filter(Tag.id == tag_id).first()
            if tag and tag.usage_count > 0:
                tag.usage_count -= 1
        
        # Increase count for added tags
        for tag_id in new_tags - old_tags:
            tag = db.query(Tag).filter(Tag.id == tag_id).first()
            if tag:
                tag.usage_count += 1
        
        # Update tags
        tags = db.query(Tag).filter(Tag.id.in_(insight_data.tag_ids)).all()
        insight.tags = tags
    
    # Update other fields
    for field, value in update_data.items():
        setattr(insight, field, value)
    
    db.commit()
    db.refresh(insight)
    
    insights_updated.inc()
    return insight


@app.delete("/insights/{insight_id}", status_code=status.HTTP_204_NO_CONTENT, tags=["Insights"])
async def delete_insight(insight_id: int, db: Session = Depends(get_db)):
    """Delete an insight."""
    insight = db.query(Insight).filter(Insight.id == insight_id).first()
    if not insight:
        raise HTTPException(status_code=404, detail="Insight not found")
    
    # Update tag usage counts
    for tag in insight.tags:
        if tag.usage_count > 0:
            tag.usage_count -= 1
    
    db.delete(insight)
    db.commit()
    
    insights_deleted.inc()


# Statistics endpoint
@app.get("/statistics", response_model=InsightStatistics, tags=["Statistics"])
async def get_statistics(db: Session = Depends(get_db)):
    """Get insights statistics and aggregations."""
    # Total insights
    total_insights = db.query(Insight).count()
    
    # Insights by status
    status_counts = db.query(
        Insight.status, func.count(Insight.id)
    ).group_by(Insight.status).all()
    insights_by_status = {status: count for status, count in status_counts}
    
    # Insights by priority
    priority_counts = db.query(
        Insight.priority, func.count(Insight.id)
    ).group_by(Insight.priority).all()
    insights_by_priority = {priority: count for priority, count in priority_counts}
    
    # Insights by category
    category_counts = db.query(
        Category.name, func.count(Insight.id)
    ).join(Insight, Category.id == Insight.category_id, isouter=True
    ).group_by(Category.name).all()
    insights_by_category = {name if name else "Uncategorized": count for name, count in category_counts}
    
    # Total tags and categories
    total_tags = db.query(Tag).count()
    total_categories = db.query(Category).count()
    
    # Recent insights
    recent_insights = db.query(Insight).order_by(Insight.created_at.desc()).limit(5).all()
    
    return InsightStatistics(
        total_insights=total_insights,
        insights_by_status=insights_by_status,
        insights_by_priority=insights_by_priority,
        insights_by_category=insights_by_category,
        total_tags=total_tags,
        total_categories=total_categories,
        recent_insights=recent_insights
    )


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
