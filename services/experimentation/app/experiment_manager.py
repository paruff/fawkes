"""Experiment management logic"""
import hashlib
import uuid
from datetime import datetime
from typing import Optional, List, Dict, Any
from sqlalchemy.orm import Session
from sqlalchemy import func

from .schema import Experiment, Assignment, Event
from .models import (
    ExperimentCreate,
    ExperimentUpdate,
    ExperimentResponse,
    VariantAssignment,
    ExperimentList,
    VariantConfig
)
from .statistical_analysis import StatisticalAnalyzer
from .metrics import MetricsCollector


class ExperimentManager:
    """Manages experiment lifecycle and variant assignment"""

    def __init__(self, db: Session, metrics_collector: MetricsCollector):
        self.db = db
        self.metrics_collector = metrics_collector
        self.analyzer = StatisticalAnalyzer()

    def create_experiment(self, experiment: ExperimentCreate) -> ExperimentResponse:
        """Create a new experiment"""
        # Validate variant allocations sum to 1.0
        total_allocation = sum(v.allocation for v in experiment.variants)
        if abs(total_allocation - 1.0) > 0.001:
            raise ValueError(f"Variant allocations must sum to 1.0 (got {total_allocation})")

        # Create experiment record
        experiment_id = str(uuid.uuid4())
        db_experiment = Experiment(
            id=experiment_id,
            name=experiment.name,
            description=experiment.description,
            hypothesis=experiment.hypothesis,
            status="draft",
            variants=[v.model_dump() for v in experiment.variants],
            metrics=experiment.metrics,
            target_sample_size=experiment.target_sample_size,
            significance_level=experiment.significance_level,
            traffic_allocation=experiment.traffic_allocation,
            created_at=datetime.utcnow()
        )

        self.db.add(db_experiment)
        self.db.commit()
        self.db.refresh(db_experiment)

        # Update metrics
        self.metrics_collector.increment_experiments_total(status="draft")

        return self._to_response(db_experiment)

    def list_experiments(self, skip: int = 0, limit: int = 100, status: str = None) -> ExperimentList:
        """List all experiments with optional filtering"""
        query = self.db.query(Experiment)

        if status:
            query = query.filter(Experiment.status == status)

        total = query.count()
        experiments = query.offset(skip).limit(limit).all()

        return ExperimentList(
            experiments=[self._to_response(exp) for exp in experiments],
            total=total,
            skip=skip,
            limit=limit
        )

    def get_experiment(self, experiment_id: str) -> Optional[ExperimentResponse]:
        """Get experiment by ID"""
        experiment = self.db.query(Experiment).filter(Experiment.id == experiment_id).first()
        if not experiment:
            return None
        return self._to_response(experiment)

    def update_experiment(self, experiment_id: str, update: ExperimentUpdate) -> Optional[ExperimentResponse]:
        """Update experiment configuration"""
        experiment = self.db.query(Experiment).filter(Experiment.id == experiment_id).first()
        if not experiment:
            return None

        if experiment.status == "running":
            # Limited updates allowed for running experiments
            if update.traffic_allocation is not None:
                experiment.traffic_allocation = update.traffic_allocation
        else:
            # Full updates for non-running experiments
            if update.description is not None:
                experiment.description = update.description
            if update.traffic_allocation is not None:
                experiment.traffic_allocation = update.traffic_allocation
            if update.target_sample_size is not None:
                experiment.target_sample_size = update.target_sample_size

        self.db.commit()
        self.db.refresh(experiment)

        return self._to_response(experiment)

    def delete_experiment(self, experiment_id: str) -> bool:
        """Delete an experiment"""
        experiment = self.db.query(Experiment).filter(Experiment.id == experiment_id).first()
        if not experiment:
            return False

        self.db.delete(experiment)
        self.db.commit()

        return True

    def start_experiment(self, experiment_id: str) -> Optional[ExperimentResponse]:
        """Start an experiment"""
        experiment = self.db.query(Experiment).filter(Experiment.id == experiment_id).first()
        if not experiment:
            return None

        if experiment.status == "draft":
            experiment.status = "running"
            experiment.started_at = datetime.utcnow()
            self.db.commit()
            self.db.refresh(experiment)

            self.metrics_collector.increment_experiments_total(status="running")

        return self._to_response(experiment)

    def stop_experiment(self, experiment_id: str) -> Optional[ExperimentResponse]:
        """Stop an experiment"""
        experiment = self.db.query(Experiment).filter(Experiment.id == experiment_id).first()
        if not experiment:
            return None

        if experiment.status == "running":
            experiment.status = "stopped"
            experiment.stopped_at = datetime.utcnow()
            self.db.commit()
            self.db.refresh(experiment)

            self.metrics_collector.increment_experiments_total(status="stopped")

        return self._to_response(experiment)

    def assign_variant(self, experiment_id: str, user_id: str, context: Dict[str, Any]) -> Optional[VariantAssignment]:
        """Assign a variant to a user using consistent hashing"""
        experiment = self.db.query(Experiment).filter(Experiment.id == experiment_id).first()
        if not experiment or experiment.status != "running":
            return None

        # Check if user already has an assignment
        existing = self.db.query(Assignment).filter(
            Assignment.experiment_id == experiment_id,
            Assignment.user_id == user_id
        ).first()

        if existing:
            return VariantAssignment(
                experiment_id=experiment_id,
                user_id=user_id,
                variant=existing.variant,
                assigned_at=existing.assigned_at
            )

        # Apply traffic allocation
        traffic_hash = self._hash_user(f"{experiment_id}:traffic:{user_id}")
        if traffic_hash > experiment.traffic_allocation:
            # User not in experiment traffic
            return None

        # Assign variant using consistent hashing
        variant = self._select_variant(experiment_id, user_id, experiment.variants)

        # Create assignment record
        assignment = Assignment(
            experiment_id=experiment_id,
            user_id=user_id,
            variant=variant,
            context=context,
            assigned_at=datetime.utcnow()
        )

        self.db.add(assignment)
        self.db.commit()
        self.db.refresh(assignment)

        # Update metrics
        self.metrics_collector.increment_variant_assignments(experiment_id, variant)

        return VariantAssignment(
            experiment_id=experiment_id,
            user_id=user_id,
            variant=variant,
            assigned_at=assignment.assigned_at
        )

    def track_event(self, experiment_id: str, user_id: str, event_name: str, value: float = 1.0) -> bool:
        """Track an event for experiment analytics"""
        # Get assignment
        assignment = self.db.query(Assignment).filter(
            Assignment.experiment_id == experiment_id,
            Assignment.user_id == user_id
        ).first()

        if not assignment:
            return False

        # Create event record
        event = Event(
            experiment_id=experiment_id,
            assignment_id=assignment.id,
            user_id=user_id,
            variant=assignment.variant,
            event_name=event_name,
            value=value,
            timestamp=datetime.utcnow()
        )

        self.db.add(event)
        self.db.commit()

        # Update metrics
        self.metrics_collector.increment_event_total(experiment_id, assignment.variant, event_name)
        self.metrics_collector.observe_event_value(experiment_id, assignment.variant, event_name, value)

        return True

    def get_experiment_stats(self, experiment_id: str):
        """Get statistical analysis for an experiment"""
        experiment = self.db.query(Experiment).filter(Experiment.id == experiment_id).first()
        if not experiment:
            return None

        # Collect data for each variant
        variant_data = {}
        for variant_config in experiment.variants:
            variant_name = variant_config['name']

            # Get assignments and events for this variant
            assignments = self.db.query(Assignment).filter(
                Assignment.experiment_id == experiment_id,
                Assignment.variant == variant_name
            ).all()

            events = self.db.query(Event).filter(
                Event.experiment_id == experiment_id,
                Event.variant == variant_name
            ).all()

            # Calculate basic stats
            sample_size = len(assignments)
            conversions = len(set(e.user_id for e in events if e.event_name in experiment.metrics))
            values = [e.value for e in events if e.event_name in experiment.metrics]

            variant_data[variant_name] = {
                'sample_size': sample_size,
                'conversions': conversions,
                'values': values
            }

        # Perform statistical analysis
        stats = self.analyzer.analyze_experiment(
            experiment_id=experiment_id,
            experiment_name=experiment.name,
            status=experiment.status,
            variants=experiment.variants,
            variant_data=variant_data,
            significance_level=experiment.significance_level
        )

        return stats

    def _hash_user(self, key: str) -> float:
        """Generate consistent hash for user (0.0 to 1.0)"""
        # Use SHA-256 for secure hashing (not MD5)
        hash_value = int(hashlib.sha256(key.encode()).hexdigest(), 16)
        return (hash_value % 10000) / 10000.0

    def _select_variant(self, experiment_id: str, user_id: str, variants: List[Dict]) -> str:
        """Select variant using consistent hashing with allocation weights"""
        user_hash = self._hash_user(f"{experiment_id}:{user_id}")

        cumulative = 0.0
        for variant in variants:
            cumulative += variant['allocation']
            if user_hash <= cumulative:
                return variant['name']

        # Fallback to last variant if rounding issues
        return variants[-1]['name']

    def _to_response(self, experiment: Experiment) -> ExperimentResponse:
        """Convert database model to response model"""
        return ExperimentResponse(
            id=experiment.id,
            name=experiment.name,
            description=experiment.description,
            hypothesis=experiment.hypothesis,
            status=experiment.status,
            variants=[VariantConfig(**v) for v in experiment.variants],
            metrics=experiment.metrics,
            target_sample_size=experiment.target_sample_size,
            significance_level=experiment.significance_level,
            traffic_allocation=experiment.traffic_allocation,
            created_at=experiment.created_at,
            started_at=experiment.started_at,
            stopped_at=experiment.stopped_at
        )
