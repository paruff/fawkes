#!/usr/bin/env python3
"""
GitHub repository indexer for RAG system.

This indexer:
1. Uses GitHub API to fetch all repositories
2. Extracts README, docs/, *.md files
3. Chunks and embeds content
4. Stores with metadata (repo, file path, last updated)
5. Handles rate limiting
6. Skips binary files

Usage:
    python -m indexers.github --github-token TOKEN [--weaviate-url URL] [--org ORG]
    
Examples:
    # Index all repos in an organization
    python -m indexers.github --github-token ghp_xxx --org paruff
    
    # Index specific repo
    python -m indexers.github --github-token ghp_xxx --repo paruff/fawkes
    
    # Dry run
    python -m indexers.github --github-token ghp_xxx --org paruff --dry-run
"""

import sys
import argparse
import hashlib
import time
from pathlib import Path
from typing import List, Dict, Any, Optional, Tuple
from datetime import datetime
import base64

try:
    import requests
    from requests.adapters import HTTPAdapter
    from urllib3.util.retry import Retry
except ImportError:
    print("❌ Error: requests library not installed")
    print("Install with: pip install requests")
    sys.exit(1)

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
GITHUB_API_BASE = "https://api.github.com"
MAX_CHUNK_SIZE = 512  # tokens (approximate by chars/4)
MAX_CHUNK_CHARS = MAX_CHUNK_SIZE * 4  # ~2048 characters

# File extensions to index
MD_EXTENSIONS = [".md", ".markdown", ".rst", ".txt"]

# Excluded file patterns
EXCLUDE_PATTERNS = [
    "node_modules/",
    ".git/",
    "__pycache__/",
    ".terraform/",
    "vendor/",
    "target/",
    "build/",
    "dist/",
    ".venv/",
    "venv/",
]


class RateLimiter:
    """Simple rate limiter for GitHub API."""
    
    def __init__(self):
        self.remaining = None
        self.reset_time = None
        self.last_check = None
    
    def update(self, headers: Dict[str, str]):
        """Update rate limit info from GitHub API response headers."""
        if "X-RateLimit-Remaining" in headers:
            self.remaining = int(headers["X-RateLimit-Remaining"])
            self.reset_time = int(headers.get("X-RateLimit-Reset", 0))
            self.last_check = time.time()
    
    def should_wait(self) -> Tuple[bool, int]:
        """
        Check if we should wait before making another request.
        
        Returns:
            (should_wait: bool, wait_seconds: int)
        """
        if self.remaining is None:
            return False, 0
        
        # If we're running low on requests, wait
        if self.remaining < 10:
            current_time = time.time()
            if self.reset_time and current_time < self.reset_time:
                wait_time = int(self.reset_time - current_time) + 5
                return True, wait_time
        
        return False, 0
    
    def wait_if_needed(self):
        """Wait if rate limit is approaching."""
        should_wait, wait_time = self.should_wait()
        if should_wait:
            print(f"⏳ Rate limit approaching. Waiting {wait_time} seconds...")
            time.sleep(wait_time)


class GitHubIndexer:
    """GitHub repository indexer."""
    
    def __init__(
        self,
        github_token: str,
        weaviate_url: str = DEFAULT_WEAVIATE_URL,
        dry_run: bool = False
    ):
        """
        Initialize GitHub indexer.
        
        Args:
            github_token: GitHub personal access token
            weaviate_url: Weaviate instance URL
            dry_run: If True, only show what would be indexed
        """
        self.github_token = github_token
        self.weaviate_url = weaviate_url
        self.dry_run = dry_run
        self.rate_limiter = RateLimiter()
        
        # Setup requests session with retry
        self.session = requests.Session()
        retry = Retry(
            total=3,
            backoff_factor=1,
            status_forcelist=[429, 500, 502, 503, 504]
        )
        adapter = HTTPAdapter(max_retries=retry)
        self.session.mount("https://", adapter)
        self.session.headers.update({
            "Authorization": f"token {github_token}",
            "Accept": "application/vnd.github.v3+json"
        })
        
        # Weaviate client
        self.weaviate_client = None
        if not dry_run:
            self._connect_weaviate()
    
    def _connect_weaviate(self):
        """Connect to Weaviate."""
        print(f"🔗 Connecting to Weaviate at {self.weaviate_url}...")
        try:
            self.weaviate_client = weaviate.Client(self.weaviate_url)
            if self.weaviate_client.is_ready():
                print("✅ Connected to Weaviate successfully")
            else:
                print("❌ Weaviate is not ready")
                sys.exit(1)
        except Exception as e:
            print(f"❌ Failed to connect to Weaviate: {e}")
            sys.exit(1)
    
    def _github_request(self, url: str, params: Optional[Dict] = None) -> Optional[Any]:
        """
        Make a GitHub API request with rate limiting.
        
        Args:
            url: API endpoint URL
            params: Optional query parameters
            
        Returns:
            Response JSON or None on error
        """
        # Check rate limit before request
        self.rate_limiter.wait_if_needed()
        
        try:
            response = self.session.get(url, params=params, timeout=30)
            
            # Update rate limit info
            self.rate_limiter.update(response.headers)
            
            if response.status_code == 200:
                return response.json()
            elif response.status_code == 404:
                print(f"  ⚠️  Not found: {url}")
                return None
            elif response.status_code == 403:
                print(f"  ❌ Forbidden (rate limit?): {url}")
                # Wait and retry once
                self.rate_limiter.wait_if_needed()
                return None
            else:
                print(f"  ❌ API request failed: {response.status_code} - {url}")
                return None
        except Exception as e:
            print(f"  ❌ Request error: {e}")
            return None
    
    def fetch_org_repos(self, org: str) -> List[Dict[str, Any]]:
        """
        Fetch all repositories for an organization.
        
        Args:
            org: Organization name
            
        Returns:
            List of repository data dictionaries
        """
        print(f"📦 Fetching repositories for organization: {org}")
        repos = []
        page = 1
        
        while True:
            url = f"{GITHUB_API_BASE}/orgs/{org}/repos"
            params = {"page": page, "per_page": 100, "type": "all"}
            
            data = self._github_request(url, params)
            if not data:
                break
            
            if isinstance(data, list):
                repos.extend(data)
                print(f"  Found {len(data)} repos on page {page}")
                
                if len(data) < 100:
                    break
                page += 1
            else:
                break
        
        print(f"✅ Found {len(repos)} total repositories")
        return repos
    
    def fetch_repo(self, repo_full_name: str) -> Optional[Dict[str, Any]]:
        """
        Fetch a specific repository.
        
        Args:
            repo_full_name: Repository in format "owner/repo"
            
        Returns:
            Repository data or None
        """
        print(f"📦 Fetching repository: {repo_full_name}")
        url = f"{GITHUB_API_BASE}/repos/{repo_full_name}"
        return self._github_request(url)
    
    def fetch_repo_contents(
        self,
        repo_full_name: str,
        path: str = ""
    ) -> List[Dict[str, Any]]:
        """
        Fetch contents of a repository path.
        
        Args:
            repo_full_name: Repository in format "owner/repo"
            path: Path within repository
            
        Returns:
            List of file/directory metadata
        """
        url = f"{GITHUB_API_BASE}/repos/{repo_full_name}/contents/{path}"
        data = self._github_request(url)
        
        if isinstance(data, list):
            return data
        elif isinstance(data, dict):
            return [data]
        else:
            return []
    
    def fetch_file_content(self, file_info: Dict[str, Any]) -> Optional[str]:
        """
        Fetch content of a file from GitHub.
        
        Args:
            file_info: File metadata from GitHub API
            
        Returns:
            File content as string or None
        """
        # Skip if not a file
        if file_info.get("type") != "file":
            return None
        
        # Skip if too large (>1MB)
        size = file_info.get("size", 0)
        if size > 1024 * 1024:
            print(f"  ⚠️  Skipping large file: {file_info.get('path')} ({size} bytes)")
            return None
        
        try:
            # Get file content (base64 encoded)
            content_b64 = file_info.get("content")
            if content_b64:
                content = base64.b64decode(content_b64).decode("utf-8")
                return content
            else:
                # Fetch via download_url
                download_url = file_info.get("download_url")
                if download_url:
                    response = self.session.get(download_url, timeout=30)
                    if response.status_code == 200:
                        return response.text
        except Exception as e:
            print(f"  ⚠️  Failed to decode file content: {e}")
        
        return None
    
    def scan_repo_for_docs(
        self,
        repo_full_name: str,
        paths: List[str] = None
    ) -> List[Dict[str, Any]]:
        """
        Scan repository for documentation files.
        
        Args:
            repo_full_name: Repository in format "owner/repo"
            paths: Specific paths to scan (default: ["", "docs", "documentation"])
            
        Returns:
            List of file metadata to index
        """
        if paths is None:
            paths = ["", "docs", "documentation"]
        
        files_to_index = []
        
        for path in paths:
            self._scan_path_recursive(repo_full_name, path, files_to_index)
        
        return files_to_index
    
    def _scan_path_recursive(
        self,
        repo_full_name: str,
        path: str,
        files_to_index: List[Dict[str, Any]],
        depth: int = 0,
        max_depth: int = 5
    ):
        """Recursively scan a path for documentation files."""
        if depth > max_depth:
            return
        
        # Skip excluded patterns
        for pattern in EXCLUDE_PATTERNS:
            if pattern in path:
                return
        
        contents = self.fetch_repo_contents(repo_full_name, path)
        
        for item in contents:
            item_path = item.get("path", "")
            item_type = item.get("type", "")
            
            # Skip excluded patterns
            if any(pattern in item_path for pattern in EXCLUDE_PATTERNS):
                continue
            
            if item_type == "file":
                # Check if it's a documentation file
                name = item.get("name", "")
                if any(name.lower().endswith(ext) for ext in MD_EXTENSIONS):
                    files_to_index.append(item)
            elif item_type == "dir":
                # Recursively scan directories
                self._scan_path_recursive(
                    repo_full_name, item_path, files_to_index, depth + 1, max_depth
                )
    
    def chunk_content(self, content: str) -> List[str]:
        """Chunk content into smaller pieces."""
        if len(content) <= MAX_CHUNK_CHARS:
            return [content]
        
        chunks = []
        paragraphs = content.split("\n\n")
        current_chunk = ""
        
        for para in paragraphs:
            if len(current_chunk) + len(para) + 2 > MAX_CHUNK_CHARS:
                if current_chunk:
                    chunks.append(current_chunk.strip())
                    current_chunk = ""
                
                if len(para) > MAX_CHUNK_CHARS:
                    sentences = para.split(". ")
                    for sentence in sentences:
                        if len(current_chunk) + len(sentence) + 2 > MAX_CHUNK_CHARS:
                            if current_chunk:
                                chunks.append(current_chunk.strip())
                            current_chunk = sentence + ". "
                        else:
                            current_chunk += sentence + ". "
                else:
                    current_chunk = para + "\n\n"
            else:
                current_chunk += para + "\n\n"
        
        if current_chunk:
            chunks.append(current_chunk.strip())
        
        return chunks
    
    def get_file_hash(self, content: str) -> str:
        """Calculate MD5 hash of content."""
        return hashlib.md5(content.encode("utf-8")).hexdigest()
    
    def index_file(
        self,
        repo_full_name: str,
        file_info: Dict[str, Any],
        force: bool = False
    ) -> Tuple[bool, int]:
        """
        Index a single file from GitHub.
        
        Args:
            repo_full_name: Repository in format "owner/repo"
            file_info: File metadata from GitHub API
            force: Force re-indexing even if unchanged
            
        Returns:
            (success: bool, chunks_indexed: int)
        """
        filepath = file_info.get("path", "")
        filename = file_info.get("name", "")
        
        # Fetch content
        content = self.fetch_file_content(file_info)
        if not content or not content.strip():
            return True, 0
        
        # Calculate hash
        file_hash = self.get_file_hash(content)
        
        # Check if needs reindex
        full_path = f"github:{repo_full_name}:{filepath}"
        if not self.dry_run and not force:
            if not self._needs_reindex(full_path, file_hash):
                return True, 0  # Skip, no changes
        
        # Extract title from first heading or use filename
        title = filename
        lines = content.split("\n")
        for line in lines[:20]:
            line = line.strip()
            if line.startswith("# "):
                title = line[2:].strip()
                break
        
        # Chunk content
        chunks = self.chunk_content(content)
        
        if self.dry_run:
            print(f"  📄 Would index: {filepath}")
            print(f"     Title: {title}")
            print(f"     Chunks: {len(chunks)}")
            return True, len(chunks)
        
        # Delete existing chunks
        deleted = self._delete_existing_chunks(full_path)
        if deleted > 0:
            print(f"  🗑️  Deleted {deleted} existing chunks")
        
        # Index chunks
        indexed_count = 0
        timestamp = datetime.utcnow().isoformat() + "Z"
        last_updated = file_info.get("sha", "")  # Use commit SHA as version
        
        try:
            with self.weaviate_client.batch as batch:
                batch.batch_size = 10
                
                for chunk_idx, chunk in enumerate(chunks):
                    chunk_id = generate_uuid5(f"{full_path}:chunk:{chunk_idx}")
                    
                    data_object = {
                        "title": title,
                        "content": chunk,
                        "filepath": full_path,
                        "category": "github",
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
            print(f"  ❌ Failed to index {filepath}: {e}")
            return False, 0
    
    def _needs_reindex(self, filepath: str, file_hash: str) -> bool:
        """Check if file needs re-indexing."""
        try:
            result = (
                self.weaviate_client.query
                .get(SCHEMA_NAME, ["fileHash"])
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
                return True
            
            existing_hash = documents[0].get("fileHash", "")
            return existing_hash != file_hash
        except Exception:
            return True
    
    def _delete_existing_chunks(self, filepath: str) -> int:
        """Delete existing chunks for a filepath."""
        try:
            result = (
                self.weaviate_client.query
                .get(SCHEMA_NAME, ["filepath"])
                .with_where({
                    "path": ["filepath"],
                    "operator": "Equal",
                    "valueString": filepath,
                })
                .with_additional(["id"])
                .with_limit(100)
                .do()
            )
            
            documents = result.get("data", {}).get("Get", {}).get(SCHEMA_NAME, [])
            
            deleted_count = 0
            for doc in documents:
                doc_id = doc.get("_additional", {}).get("id")
                if doc_id:
                    self.weaviate_client.data_object.delete(doc_id, class_name=SCHEMA_NAME)
                    deleted_count += 1
            
            return deleted_count
        except Exception as e:
            print(f"  ⚠️  Failed to delete existing chunks: {e}")
            return 0
    
    def index_repository(self, repo_full_name: str, force: bool = False):
        """
        Index all documentation from a repository.
        
        Args:
            repo_full_name: Repository in format "owner/repo"
            force: Force re-indexing even if unchanged
        """
        print(f"\n{'='*70}")
        print(f"Indexing Repository: {repo_full_name}")
        print(f"{'='*70}\n")
        
        # Scan for documentation files
        files = self.scan_repo_for_docs(repo_full_name)
        print(f"📊 Found {len(files)} documentation files\n")
        
        if not files:
            print("⚠️  No documentation files found")
            return
        
        # Index each file
        success_count = 0
        error_count = 0
        total_chunks = 0
        skipped_count = 0
        
        for i, file_info in enumerate(files, 1):
            filepath = file_info.get("path", "")
            print(f"[{i}/{len(files)}] Processing: {filepath}")
            
            success, chunks = self.index_file(repo_full_name, file_info, force)
            
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
        
        # Summary
        print(f"\n{'='*70}")
        print(f"Repository Summary: {repo_full_name}")
        print(f"{'='*70}")
        print(f"Files processed: {len(files)}")
        print(f"Successfully indexed: {success_count}")
        print(f"Skipped (unchanged): {skipped_count}")
        print(f"Errors: {error_count}")
        print(f"Total chunks: {total_chunks}")
        print(f"{'='*70}\n")


def main():
    """Main execution function."""
    parser = argparse.ArgumentParser(
        description="Index GitHub repositories into Weaviate RAG system"
    )
    parser.add_argument(
        "--github-token",
        required=True,
        help="GitHub personal access token",
    )
    parser.add_argument(
        "--weaviate-url",
        default=DEFAULT_WEAVIATE_URL,
        help=f"Weaviate URL (default: {DEFAULT_WEAVIATE_URL})",
    )
    parser.add_argument(
        "--org",
        help="GitHub organization to index all repositories from",
    )
    parser.add_argument(
        "--repo",
        help="Specific repository to index (format: owner/repo)",
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
    args = parser.parse_args()
    
    if not args.org and not args.repo:
        print("❌ Error: Must specify either --org or --repo")
        sys.exit(1)
    
    print("=" * 70)
    print("GitHub Repository Indexer for RAG System")
    print("=" * 70)
    
    if args.dry_run:
        print("🔍 DRY RUN MODE - No changes will be made\n")
    
    # Create indexer
    indexer = GitHubIndexer(
        github_token=args.github_token,
        weaviate_url=args.weaviate_url,
        dry_run=args.dry_run
    )
    
    start_time = time.time()
    
    try:
        if args.org:
            # Index all repos in organization
            repos = indexer.fetch_org_repos(args.org)
            
            for repo in repos:
                repo_full_name = repo.get("full_name")
                if repo_full_name:
                    try:
                        indexer.index_repository(repo_full_name, args.force_reindex)
                    except Exception as e:
                        print(f"❌ Failed to index {repo_full_name}: {e}\n")
        
        elif args.repo:
            # Index specific repository
            indexer.index_repository(args.repo, args.force_reindex)
    
    except KeyboardInterrupt:
        print("\n\n⚠️  Indexing interrupted by user")
        sys.exit(1)
    except Exception as e:
        print(f"\n\n❌ Fatal error: {e}")
        sys.exit(1)
    
    elapsed_time = time.time() - start_time
    
    print(f"\n{'='*70}")
    print(f"⏱️  Total time elapsed: {elapsed_time:.2f} seconds")
    
    if args.dry_run:
        print("🔍 This was a dry run. Run without --dry-run to actually index.")
    else:
        print("✅ Indexing complete!")
    
    print(f"{'='*70}\n")


if __name__ == "__main__":
    main()
