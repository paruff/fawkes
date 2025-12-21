#!/usr/bin/env python3
"""
Load stage configurations from YAML file into VSM database.

This script reads the stages.yaml configuration file and loads or updates
the stages in the VSM service database. It can be run during initial setup
or to update stage configurations.

Usage:
    python scripts/load-stages.py [--config config/stages.yaml] [--update]

Options:
    --config PATH    Path to stages configuration YAML file (default: config/stages.yaml)
    --update         Update existing stages instead of skipping them
    --dry-run        Show what would be done without making changes
    --help           Show this help message
"""

import argparse
import logging
import os
import sys
from pathlib import Path
from typing import Dict, List, Optional

import yaml
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

# Add parent directory to path to import app modules
script_dir = Path(__file__).parent
service_dir = script_dir.parent
sys.path.insert(0, str(service_dir))

from app.models import Base, Stage, StageType, StageCategory
from app.database import get_database_url

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


def load_stages_config(config_path: str) -> Dict:
    """Load stages configuration from YAML file."""
    try:
        with open(config_path, 'r') as f:
            config = yaml.safe_load(f)
        logger.info(f"Loaded configuration from {config_path}")
        return config
    except FileNotFoundError:
        logger.error(f"Configuration file not found: {config_path}")
        sys.exit(1)
    except yaml.YAMLError as e:
        logger.error(f"Error parsing YAML file: {e}")
        sys.exit(1)


def map_stage_type(stage_name: str) -> StageType:
    """Map stage name to StageType enum."""
    # Map stage names to their corresponding StageType
    type_mapping = {
        'Backlog': StageType.BACKLOG,
        'Design': StageType.ANALYSIS,  # Map Design to ANALYSIS
        'Development': StageType.DEVELOPMENT,
        'Code Review': StageType.TESTING,  # Map Code Review to TESTING for now
        'Testing': StageType.TESTING,
        'Deployment Approval': StageType.DEPLOYMENT,  # Map to DEPLOYMENT
        'Deploy': StageType.DEPLOYMENT,
        'Production': StageType.PRODUCTION,
    }
    
    return type_mapping.get(stage_name, StageType.DEVELOPMENT)


def map_stage_category(category_str: str) -> StageCategory:
    """Map category string to StageCategory enum."""
    category_mapping = {
        'wait': StageCategory.WAIT,
        'active': StageCategory.ACTIVE,
        'done': StageCategory.DONE,
    }
    
    return category_mapping.get(category_str.lower(), StageCategory.ACTIVE)


def load_stages(
    config: Dict,
    session,
    update: bool = False,
    dry_run: bool = False
) -> Dict[str, int]:
    """
    Load stages from configuration into database.
    
    Args:
        config: Stages configuration dictionary
        session: Database session
        update: Whether to update existing stages
        dry_run: If True, show what would be done without making changes
        
    Returns:
        Dictionary with counts of created, updated, and skipped stages
    """
    results = {
        'created': 0,
        'updated': 0,
        'skipped': 0,
        'errors': 0
    }
    
    stages_config = config.get('stages', [])
    
    if not stages_config:
        logger.warning("No stages found in configuration")
        return results
    
    logger.info(f"Processing {len(stages_config)} stages...")
    
    for stage_data in stages_config:
        name = stage_data.get('name')
        if not name:
            logger.error("Stage missing 'name' field, skipping")
            results['errors'] += 1
            continue
        
        try:
            # Check if stage already exists
            existing_stage = session.query(Stage).filter(Stage.name == name).first()
            
            # Prepare stage data
            stage_type = map_stage_type(name)
            category_str = stage_data.get('type', 'active')
            stage_category = map_stage_category(category_str)
            
            stage_info = {
                'name': name,
                'order': stage_data.get('order', 0),
                'type': stage_type,
                'category': stage_category,
                'wip_limit': stage_data.get('wip_limit'),
                'description': stage_data.get('description', '').strip()
            }
            
            if existing_stage:
                if update:
                    # Update existing stage
                    logger.info(f"{'[DRY RUN] Would update' if dry_run else 'Updating'} stage: {name}")
                    
                    if not dry_run:
                        for key, value in stage_info.items():
                            if key != 'name':  # Don't update the name
                                setattr(existing_stage, key, value)
                    
                    results['updated'] += 1
                else:
                    logger.info(f"Stage already exists (skipping): {name}")
                    results['skipped'] += 1
            else:
                # Create new stage
                logger.info(f"{'[DRY RUN] Would create' if dry_run else 'Creating'} stage: {name}")
                
                if not dry_run:
                    new_stage = Stage(**stage_info)
                    session.add(new_stage)
                
                results['created'] += 1
            
            # Log stage details
            logger.debug(f"  Order: {stage_info['order']}")
            logger.debug(f"  Type: {stage_info['type'].value}")
            logger.debug(f"  Category: {stage_info['category'].value}")
            logger.debug(f"  WIP Limit: {stage_info['wip_limit']}")
            
        except Exception as e:
            logger.error(f"Error processing stage '{name}': {e}")
            results['errors'] += 1
            continue
    
    if not dry_run:
        try:
            session.commit()
            logger.info("Changes committed to database")
        except Exception as e:
            logger.error(f"Error committing changes: {e}")
            session.rollback()
            raise
    
    return results


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description='Load stage configurations into VSM database',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__
    )
    parser.add_argument(
        '--config',
        default='config/stages.yaml',
        help='Path to stages configuration YAML file'
    )
    parser.add_argument(
        '--update',
        action='store_true',
        help='Update existing stages instead of skipping them'
    )
    parser.add_argument(
        '--dry-run',
        action='store_true',
        help='Show what would be done without making changes'
    )
    parser.add_argument(
        '--verbose',
        action='store_true',
        help='Enable verbose logging'
    )
    
    args = parser.parse_args()
    
    # Set logging level
    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)
    
    # Resolve config path
    config_path = Path(args.config)
    if not config_path.is_absolute():
        config_path = service_dir / config_path
    
    logger.info("=" * 60)
    logger.info("VSM Stage Loader")
    logger.info("=" * 60)
    
    if args.dry_run:
        logger.info("DRY RUN MODE - No changes will be made")
    
    # Load configuration
    config = load_stages_config(str(config_path))
    
    # Get database connection
    database_url = get_database_url()
    logger.info(f"Connecting to database...")
    
    try:
        engine = create_engine(database_url)
        SessionLocal = sessionmaker(bind=engine)
        session = SessionLocal()
        
        # Test connection
        session.execute("SELECT 1")
        logger.info("✅ Database connection successful")
        
        # Load stages
        results = load_stages(config, session, update=args.update, dry_run=args.dry_run)
        
        # Print summary
        logger.info("=" * 60)
        logger.info("Summary:")
        logger.info(f"  Created: {results['created']}")
        logger.info(f"  Updated: {results['updated']}")
        logger.info(f"  Skipped: {results['skipped']}")
        logger.info(f"  Errors:  {results['errors']}")
        logger.info("=" * 60)
        
        if results['errors'] > 0:
            logger.warning("Some stages had errors during processing")
            sys.exit(1)
        
        if args.dry_run:
            logger.info("DRY RUN completed - No changes were made")
        else:
            logger.info("✅ Stage loading completed successfully")
        
        session.close()
        
    except Exception as e:
        logger.error(f"❌ Failed to load stages: {e}")
        sys.exit(1)


if __name__ == '__main__':
    main()
