#!/usr/bin/env python3
"""
Index internal documentation into Weaviate vector database.

This script:
1. Scans docs/, platform/, infra/ directories
2. Extracts markdown, YAML, code files
3. Chunks documents (512 tokens max)
4. Generates embeddings via Weaviate's text2vec-transformers
5. Stores in Weaviate with metadata
6. Handles incremental updates

Usage:
    python index-docs.py [--weaviate-url URL] [--dry-run] [--force-reindex]
    
Examples:
    # Index with default settings
    python index-docs.py
    
    # Use custom Weaviate URL
    python index-docs.py --weaviate-url http://weaviate.fawkes.svc:80
    
    # Dry run to see what would be indexed
    python index-docs.py --dry-run
    
    # Force re-indexing of all documents
    python index-docs.py --force-reindex
"""

import sys
import argparse
import hashlib
import time
from pathlib import Path
from typing import List, Dict, Any, Optional, Tuple
from datetime import datetime

try:
    import weaviate
    from weaviate.util import generate_uuid5
except ImportError:
    print("❌ Error: weaviate-client library not installed")
    print("Install with: pip install weaviate-client")
    sys.exit(1)

# Configuration
DEFAULT_WEAVIATE_URL = "http://localhost:8080"
SCHEMA_NAME = "FawkesDocument"
MAX_CHUNK_SIZE = 512  # tokens (approximate by chars/4)
MAX_CHUNK_CHARS = MAX_CHUNK_SIZE * 4  # ~2048 characters

# Directories to scan
SCAN_DIRS = ["docs", "platform", "infra"]

# File extensions to index
FILE_EXTENSIONS = {
    ".md": "markdown",
    ".yaml": "yaml",
    ".yml": "yaml",
    ".py": "python",
    ".sh": "shell",
    ".go": "go",
    ".java": "java",
    ".js": "javascript",
    ".ts": "typescript",
    ".json": "json",
    ".tf": "terraform",
    ".hcl": "hcl",
}

# Excluded patterns
EXCLUDE_PATTERNS = [
    "node_modules",
    ".git",
    "__pycache__",
    ".terraform",
    "vendor",
    "target",
    "build",
    "dist",
    ".venv",
    "venv",
]


def should_exclude(path: Path) -> bool:
    """Check if path should be excluded from indexing."""
    path_str = str(path)
    for pattern in EXCLUDE_PATTERNS:
        if pattern in path_str:
            return True
    return False


def get_file_hash(filepath: Path) -> str:
    """Calculate MD5 hash of file content."""
    hasher = hashlib.md5()
    with open(filepath, "rb") as f:
        hasher.update(f.read())
    return hasher.hexdigest()


def chunk_content(content: str, max_chars: int = MAX_CHUNK_CHARS) -> List[str]:
    """
    Chunk content into smaller pieces.
    
    Tries to split on paragraph boundaries, then sentences, then words.
    """
    # If content is short enough, return as-is
    if len(content) <= max_chars:
        return [content]
    
    chunks = []
    
    # Split on double newlines (paragraphs)
    paragraphs = content.split("\n\n")
    
    current_chunk = ""
    for para in paragraphs:
        # If adding this paragraph would exceed limit
        if len(current_chunk) + len(para) + 2 > max_chars:
            if current_chunk:
                chunks.append(current_chunk.strip())
                current_chunk = ""
            
            # If single paragraph is too long, split it
            if len(para) > max_chars:
                # Split on sentences
                sentences = para.split(". ")
                for sentence in sentences:
                    if len(current_chunk) + len(sentence) + 2 > max_chars:
                        if current_chunk:
                            chunks.append(current_chunk.strip())
                        current_chunk = sentence + ". "
                    else:
                        current_chunk += sentence + ". "
            else:
                current_chunk = para + "\n\n"
        else:
            current_chunk += para + "\n\n"
    
    # Add remaining chunk
    if current_chunk:
        chunks.append(current_chunk.strip())
    
    return chunks


def extract_title(content: str, filepath: Path) -> str:
    """Extract title from content or use filename."""
    # Try to find markdown title
    lines = content.split("\n")
    for line in lines[:10]:  # Check first 10 lines
        line = line.strip()
        if line.startswith("# "):
            return line[2:].strip()
    
    # Use filename as fallback
    return filepath.stem.replace("-", " ").replace("_", " ").title()


def categorize_file(filepath: Path) -> str:
    """Categorize file based on path and extension."""
    path_str = str(filepath)
    
    if "docs/adr" in path_str or "ADR" in filepath.stem.upper():
        return "adr"
    elif "docs/" in path_str:
        return "doc"
    elif "README" in filepath.name.upper():
        return "readme"
    elif "platform/" in path_str:
        return "platform"
    elif "infra/" in path_str:
        return "infrastructure"
    elif filepath.suffix in [".py", ".go", ".java", ".js", ".ts"]:
        return "code"
    else:
        return "config"


def scan_files(base_path: Path, scan_dirs: List[str]) -> List[Path]:
    """Scan directories for files to index."""
    files_to_index = []
    
    for scan_dir in scan_dirs:
        dir_path = base_path / scan_dir
        if not dir_path.exists():
            print(f"⚠️  Directory not found: {dir_path}")
            continue
        
        print(f"📁 Scanning: {dir_path}")
        
        for ext in FILE_EXTENSIONS.keys():
            for filepath in dir_path.rglob(f"*{ext}"):
                if not should_exclude(filepath):
                    files_to_index.append(filepath)
    
    return sorted(files_to_index)


def read_file_content(filepath: Path) -> Optional[str]:
    """Read file content, handling encoding errors."""
    try:
        with open(filepath, "r", encoding="utf-8") as f:
            return f.read()
    except UnicodeDecodeError:
        try:
            with open(filepath, "r", encoding="latin-1") as f:
                return f.read()
        except Exception as e:
            print(f"  ❌ Failed to read {filepath}: {e}")
            return None
    except Exception as e:
        print(f"  ❌ Failed to read {filepath}: {e}")
        return None


def create_client(url: str) -> weaviate.Client:
    """Create and return a Weaviate client."""
    print(f"🔗 Connecting to Weaviate at {url}...")
    try:
        client = weaviate.Client(url)
        if client.is_ready():
            print("✅ Connected to Weaviate successfully")
            return client
        else:
            print("❌ Weaviate is not ready")
            sys.exit(1)
    except Exception as e:
        print(f"❌ Failed to connect to Weaviate: {e}")
        sys.exit(1)


def ensure_schema(client: weaviate.Client) -> None:
    """Ensure the document schema exists in Weaviate."""
    print(f"\n📋 Checking schema '{SCHEMA_NAME}'...")
    
    try:
        # Check if schema exists
        schema = client.schema.get()
        class_names = [c["class"] for c in schema.get("classes", [])]
        
        if SCHEMA_NAME in class_names:
            print(f"✅ Schema '{SCHEMA_NAME}' already exists")
            return
        
        # Create schema
        print(f"📝 Creating schema '{SCHEMA_NAME}'...")
        schema_definition = {
            "class": SCHEMA_NAME,
            "description": "Fawkes platform documentation and code files",
            "vectorizer": "text2vec-transformers",
            "properties": [
                {
                    "name": "title",
                    "dataType": ["string"],
                    "description": "Document title or filename",
                    "indexFilterable": True,
                    "indexSearchable": True,
                },
                {
                    "name": "content",
                    "dataType": ["text"],
                    "description": "Document content",
                    "indexFilterable": False,
                    "indexSearchable": True,
                },
                {
                    "name": "filepath",
                    "dataType": ["string"],
                    "description": "File path in repository",
                    "indexFilterable": True,
                    "indexSearchable": True,
                },
                {
                    "name": "category",
                    "dataType": ["string"],
                    "description": "Document category",
                    "indexFilterable": True,
                    "indexSearchable": False,
                },
                {
                    "name": "fileHash",
                    "dataType": ["string"],
                    "description": "MD5 hash of file content for change detection",
                    "indexFilterable": True,
                    "indexSearchable": False,
                },
                {
                    "name": "chunkIndex",
                    "dataType": ["int"],
                    "description": "Chunk index for multi-chunk documents",
                    "indexFilterable": True,
                    "indexSearchable": False,
                },
                {
                    "name": "indexed_at",
                    "dataType": ["date"],
                    "description": "Timestamp when document was indexed",
                    "indexFilterable": True,
                    "indexSearchable": False,
                },
            ],
        }
        
        client.schema.create_class(schema_definition)
        print(f"✅ Schema '{SCHEMA_NAME}' created successfully")
        
    except Exception as e:
        print(f"❌ Failed to ensure schema: {e}")
        sys.exit(1)


def check_if_needs_reindex(
    client: weaviate.Client, filepath: str, file_hash: str, force: bool = False
) -> bool:
    """Check if file needs re-indexing based on hash."""
    if force:
        return True
    
    try:
        # Query for existing document with same filepath
        result = (
            client.query
            .get(SCHEMA_NAME, ["fileHash", "filepath"])
            .with_where({
                "path": ["filepath"],
                "operator": "Equal",
                "valueString": filepath,
            })
            .with_limit(1)
            .do()
        )
        
        documents = result.get("data", {}).get("Get", {}).get(SCHEMA_NAME, [])
        
        if not documents:
            return True  # New document
        
        # Check if hash changed
        existing_hash = documents[0].get("fileHash", "")
        return existing_hash != file_hash
        
    except Exception:
        # On error, assume needs reindex
        return True


def delete_existing_chunks(client: weaviate.Client, filepath: str) -> int:
    """Delete existing chunks for a filepath."""
    try:
        # Get all UUIDs for this filepath
        result = (
            client.query
            .get(SCHEMA_NAME, ["filepath"])
            .with_where({
                "path": ["filepath"],
                "operator": "Equal",
                "valueString": filepath,
            })
            .with_additional(["id"])
            .with_limit(100)  # Assume max 100 chunks per file
            .do()
        )
        
        documents = result.get("data", {}).get("Get", {}).get(SCHEMA_NAME, [])
        
        deleted_count = 0
        for doc in documents:
            doc_id = doc.get("_additional", {}).get("id")
            if doc_id:
                client.data_object.delete(doc_id, class_name=SCHEMA_NAME)
                deleted_count += 1
        
        return deleted_count
        
    except Exception as e:
        print(f"  ⚠️  Failed to delete existing chunks: {e}")
        return 0


def index_file(
    client: weaviate.Client,
    filepath: Path,
    base_path: Path,
    dry_run: bool = False,
    force: bool = False,
) -> Tuple[bool, int]:
    """
    Index a single file into Weaviate.
    
    Returns:
        (success: bool, chunks_indexed: int)
    """
    # Read content
    content = read_file_content(filepath)
    if not content:
        return False, 0
    
    # Skip empty files
    if not content.strip():
        return True, 0
    
    # Calculate relative path
    try:
        rel_path = str(filepath.relative_to(base_path))
    except ValueError:
        rel_path = str(filepath)
    
    # Calculate file hash
    file_hash = get_file_hash(filepath)
    
    # Check if needs reindex
    if not dry_run and not check_if_needs_reindex(client, rel_path, file_hash, force):
        return True, 0  # Skip, no changes
    
    # Extract metadata
    title = extract_title(content, filepath)
    category = categorize_file(filepath)
    
    # Chunk content
    chunks = chunk_content(content)
    
    if dry_run:
        print(f"  📄 Would index: {rel_path}")
        print(f"     Title: {title}")
        print(f"     Category: {category}")
        print(f"     Chunks: {len(chunks)}")
        return True, len(chunks)
    
    # Delete existing chunks
    deleted_count = delete_existing_chunks(client, rel_path)
    if deleted_count > 0:
        print(f"  🗑️  Deleted {deleted_count} existing chunks")
    
    # Index chunks
    indexed_count = 0
    timestamp = datetime.utcnow().isoformat() + "Z"
    
    try:
        with client.batch as batch:
            batch.batch_size = 10
            
            for chunk_idx, chunk in enumerate(chunks):
                # Generate deterministic UUID
                chunk_id = generate_uuid5(f"{rel_path}:chunk:{chunk_idx}")
                
                data_object = {
                    "title": title,
                    "content": chunk,
                    "filepath": rel_path,
                    "category": category,
                    "fileHash": file_hash,
                    "chunkIndex": chunk_idx,
                    "indexed_at": timestamp,
                }
                
                batch.add_data_object(
                    data_object=data_object,
                    class_name=SCHEMA_NAME,
                    uuid=chunk_id,
                )
                indexed_count += 1
        
        return True, indexed_count
        
    except Exception as e:
        print(f"  ❌ Failed to index {rel_path}: {e}")
        return False, 0


def main():
    """Main execution function."""
    parser = argparse.ArgumentParser(
        description="Index Fawkes internal documentation into Weaviate"
    )
    parser.add_argument(
        "--weaviate-url",
        default=DEFAULT_WEAVIATE_URL,
        help=f"Weaviate URL (default: {DEFAULT_WEAVIATE_URL})",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show what would be indexed without actually indexing",
    )
    parser.add_argument(
        "--force-reindex",
        action="store_true",
        help="Force re-indexing of all documents even if unchanged",
    )
    parser.add_argument(
        "--base-path",
        type=Path,
        default=Path.cwd(),
        help="Base path of repository (default: current directory)",
    )
    args = parser.parse_args()
    
    print("=" * 70)
    print("Fawkes Documentation Indexing Script")
    print("=" * 70)
    
    if args.dry_run:
        print("🔍 DRY RUN MODE - No changes will be made")
        print()
    
    # Connect to Weaviate (skip in dry-run)
    if not args.dry_run:
        client = create_client(args.weaviate_url)
        ensure_schema(client)
    else:
        client = None
    
    # Scan for files
    print(f"\n📂 Base path: {args.base_path}")
    files_to_index = scan_files(args.base_path, SCAN_DIRS)
    print(f"\n📊 Found {len(files_to_index)} files to process")
    
    # Index files
    print("\n📝 Indexing files...")
    print()
    
    success_count = 0
    error_count = 0
    total_chunks = 0
    skipped_count = 0
    start_time = time.time()
    
    for i, filepath in enumerate(files_to_index, 1):
        print(f"[{i}/{len(files_to_index)}] Processing: {filepath.name}")
        
        success, chunks = index_file(
            client, filepath, args.base_path, args.dry_run, args.force_reindex
        )
        
        if success:
            if chunks > 0:
                success_count += 1
                total_chunks += chunks
                print(f"  ✅ Indexed {chunks} chunk(s)")
            else:
                skipped_count += 1
                print(f"  ⏭️  Skipped (no changes)")
        else:
            error_count += 1
    
    elapsed_time = time.time() - start_time
    
    # Summary
    print("\n" + "=" * 70)
    print("📊 Indexing Summary")
    print("=" * 70)
    print(f"Total files processed: {len(files_to_index)}")
    print(f"Successfully indexed: {success_count}")
    print(f"Skipped (unchanged): {skipped_count}")
    print(f"Errors: {error_count}")
    print(f"Total chunks indexed: {total_chunks}")
    print(f"Time elapsed: {elapsed_time:.2f} seconds")
    
    if args.dry_run:
        print("\n🔍 This was a dry run. Run without --dry-run to actually index.")
    else:
        print("\n✅ Indexing complete!")
    
    print("=" * 70)
    
    return 0 if error_count == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
