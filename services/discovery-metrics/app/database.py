"""Database connection and session management."""
import os
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

# Database configuration from environment variables
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://discovery:discovery@localhost:5432/discovery_metrics")

# Create SQLAlchemy engine
engine = create_engine(DATABASE_URL, pool_pre_ping=True, pool_size=5, max_overflow=10)

# Create SessionLocal class
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Create Base class for models
Base = declarative_base()


def get_db():
    """Get database session."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def check_db_connection():
    """Check if database is accessible."""
    try:
        db = SessionLocal()
        db.execute("SELECT 1")
        db.close()
        return True
    except Exception as e:
        print(f"Database connection failed: {e}")
        return False
