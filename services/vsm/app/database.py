"""Database configuration and session management."""
import os
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, Session
from typing import Generator
import logging

logger = logging.getLogger(__name__)

# Database connection configuration from environment
DATABASE_HOST = os.getenv("DATABASE_HOST", "db-vsm-dev-rw.fawkes.svc")
DATABASE_PORT = os.getenv("DATABASE_PORT", "5432")
DATABASE_NAME = os.getenv("DATABASE_NAME", "vsm_db")
DATABASE_USER = os.getenv("DATABASE_USER", "vsm_user")
DATABASE_PASSWORD = os.getenv("DATABASE_PASSWORD", "changeme")

# Construct database URL
DATABASE_URL = f"postgresql://{DATABASE_USER}:{DATABASE_PASSWORD}@{DATABASE_HOST}:{DATABASE_PORT}/{DATABASE_NAME}"

# Create engine
engine = create_engine(
    DATABASE_URL,
    pool_pre_ping=True,  # Enable connection health checks
    pool_size=5,
    max_overflow=10,
    echo=os.getenv("SQL_ECHO", "false").lower() == "true",
)

# Create session factory
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


def get_db() -> Generator[Session, None, None]:
    """
    Get database session.

    Yields:
        Database session
    """
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def init_db():
    """Initialize database with default stages if needed."""
    from app.models import Base, Stage, StageType

    # Create all tables
    Base.metadata.create_all(bind=engine)

    # Create default stages if they don't exist
    db = SessionLocal()
    try:
        existing_stages = db.query(Stage).count()
        if existing_stages == 0:
            logger.info("Initializing default stages")
            default_stages = [
                Stage(name="Backlog", order=1, type=StageType.BACKLOG),
                Stage(name="Analysis", order=2, type=StageType.ANALYSIS),
                Stage(name="Development", order=3, type=StageType.DEVELOPMENT),
                Stage(name="Testing", order=4, type=StageType.TESTING),
                Stage(name="Deployment", order=5, type=StageType.DEPLOYMENT),
                Stage(name="Production", order=6, type=StageType.PRODUCTION),
            ]
            db.add_all(default_stages)
            db.commit()
            logger.info("✅ Default stages created")
    except Exception as e:
        logger.error(f"Failed to initialize database: {e}")
        db.rollback()
    finally:
        db.close()
