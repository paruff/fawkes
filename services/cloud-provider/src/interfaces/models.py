"""Common data models for cloud resources."""

from dataclasses import dataclass
from datetime import datetime
from typing import Any, Dict, Optional


@dataclass
class Cluster:
    """Represents a Kubernetes cluster."""

    id: str
    name: str
    status: str
    version: str
    endpoint: str | None = None
    region: str = ""
    node_count: int = 0
    created_at: datetime | None = None
    metadata: dict[str, Any] = None

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
    endpoint: str | None = None
    port: int | None = None
    region: str = ""
    allocated_storage: int = 0
    instance_class: str = ""
    created_at: datetime | None = None
    metadata: dict[str, Any] = None

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
    created_at: datetime | None = None
    versioning_enabled: bool = False
    encryption_enabled: bool = False
    metadata: dict[str, Any] = None

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
    breakdown: dict[str, float] = None
    metadata: dict[str, Any] = None

    def __post_init__(self):
        if self.breakdown is None:
            self.breakdown = {}
        if self.metadata is None:
            self.metadata = {}
