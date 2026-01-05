"""Common data models for cloud resources."""
from dataclasses import dataclass
from datetime import datetime
from typing import Optional, Dict, Any


@dataclass
class Cluster:
    """Represents a Kubernetes cluster."""

    id: str
    name: str
    status: str
    version: str
    endpoint: Optional[str] = None
    region: str = ""
    node_count: int = 0
    created_at: Optional[datetime] = None
    metadata: Dict[str, Any] = None

    def __post_init__(self):
        if self.metadata is None:
            self.metadata = {}


@dataclass
class Database:
    """Represents a database instance."""

    id: str
    name: str
    engine: str
    engine_version: str
    status: str
    endpoint: Optional[str] = None
    port: Optional[int] = None
    region: str = ""
    allocated_storage: int = 0
    instance_class: str = ""
    created_at: Optional[datetime] = None
    metadata: Dict[str, Any] = None

    def __post_init__(self):
        if self.metadata is None:
            self.metadata = {}


@dataclass
class Storage:
    """Represents a storage bucket."""

    id: str
    name: str
    region: str
    size_bytes: int = 0
    object_count: int = 0
    created_at: Optional[datetime] = None
    versioning_enabled: bool = False
    encryption_enabled: bool = False
    metadata: Dict[str, Any] = None

    def __post_init__(self):
        if self.metadata is None:
            self.metadata = {}


@dataclass
class CostData:
    """Represents cost data for a time period."""

    start_date: datetime
    end_date: datetime
    total_cost: float
    currency: str = "USD"
    breakdown: Dict[str, float] = None
    metadata: Dict[str, Any] = None

    def __post_init__(self):
        if self.breakdown is None:
            self.breakdown = {}
        if self.metadata is None:
            self.metadata = {}
