#!/usr/bin/env python3
"""
Backstage TechDocs indexer for RAG system.

This indexer:
1. Fetches all TechDocs from Backstage API
2. Parses markdown content
3. Extracts sections and headings
4. Chunks and embeds content
5. Links back to Backstage URLs

Usage:
    python -m indexers.techdocs --backstage-url URL [--weaviate-url URL]
    
Examples:
    # Index TechDocs from Backstage
    python -m indexers.techdocs --backstage-url http://backstage.example.com
    
    # With authentication token
    python -m indexers.techdocs --backstage-url http://backstage.example.com --token TOKEN
    
    # Dry run
    python -m indexers.techdocs --backstage-url http://backstage.example.com --dry-run
"""

import sys
import argparse
import hashlib
import time
from typing import List, Dict, Any, Optional, Tuple
from datetime import datetime
import re

try:
    import requests
    from requests.adapters import HTTPAdapter
    from urllib3.util.retry import Retry
except ImportError:
    print("❌ Error: requests library not installed")
    print("Install with: pip install requests")
    sys.exit(1)

try:
    from bs4 import BeautifulSoup
except ImportError:
    print("❌ Error: beautifulsoup4 library not installed")
    print("Install with: pip install beautifulsoup4 lxml")
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
MAX_CHUNK_SIZE = 512  # tokens (approximate by chars/4)
MAX_CHUNK_CHARS = MAX_CHUNK_SIZE * 4  # ~2048 characters


class BackstageIndexer:
    """Backstage TechDocs indexer."""
    
    def __init__(
        self,
        backstage_url: str,
        weaviate_url: str = DEFAULT_WEAVIATE_URL,
        auth_token: Optional[str] = None,
        dry_run: bool = False
    ):
        """
        Initialize Backstage indexer.
        
        Args:
            backstage_url: Backstage instance URL
            weaviate_url: Weaviate instance URL
            auth_token: Optional authentication token
            dry_run: If True, only show what would be indexed
        """
        self.backstage_url = backstage_url.rstrip("/")
        self.weaviate_url = weaviate_url
        self.auth_token = auth_token
        self.dry_run = dry_run
        
        # Setup requests session with retry
        self.session = requests.Session()
        retry = Retry(
            total=3,
            backoff_factor=1,
            status_forcelist=[429, 500, 502, 503, 504]
        )
        adapter = HTTPAdapter(max_retries=retry)
        self.session.mount("http://", adapter)
        self.session.mount("https://", adapter)
        
        # Add auth header if token provided
        if auth_token:
            self.session.headers.update({
                "Authorization": f"Bearer {auth_token}"
            })
        
        # Weaviate client
        self.weaviate_client = None
        if not dry_run:
            self._connect_weaviate()
    
    def _connect_weaviate(self):
        """Connect to Weaviate. Exits on failure since this is a CLI script."""
        print(f"🔗 Connecting to Weaviate at {self.weaviate_url}...")
        try:
            self.weaviate_client = weaviate.Client(self.weaviate_url)
            if self.weaviate_client.is_ready():
                print("✅ Connected to Weaviate successfully")
            else:
                print("❌ Weaviate is not ready")
                sys.exit(1)  # Fatal error for CLI script
        except Exception as e:
            print(f"❌ Failed to connect to Weaviate: {e}")
            sys.exit(1)  # Fatal error for CLI script
    
    def _backstage_request(self, path: str, params: Optional[Dict] = None) -> Optional[Any]:
        """
        Make a Backstage API request.
        
        Args:
            path: API endpoint path
            params: Optional query parameters
            
        Returns:
            Response JSON or None on error
        """
        url = f"{self.backstage_url}{path}"
        
        try:
            response = self.session.get(url, params=params, timeout=30)
            
            if response.status_code == 200:
                return response.json()
            elif response.status_code == 404:
                print(f"  ⚠️  Not found: {path}")
                return None
            else:
                print(f"  ❌ API request failed: {response.status_code} - {path}")
                return None
        except Exception as e:
            print(f"  ❌ Request error: {e}")
            return None
    
    def fetch_catalog_entities(self) -> List[Dict[str, Any]]:
        """
        Fetch all catalog entities from Backstage.
        
        Returns:
            List of catalog entities
        """
        print("📚 Fetching catalog entities from Backstage...")
        
        # Try to fetch entities from catalog API
        # Backstage catalog API typically at /api/catalog/entities
        entities = self._backstage_request("/api/catalog/entities")
        
        if entities and isinstance(entities, dict):
            items = entities.get("items", [])
            print(f"✅ Found {len(items)} catalog entities")
            return items
        elif isinstance(entities, list):
            print(f"✅ Found {len(entities)} catalog entities")
            return entities
        else:
            print("⚠️  No entities found or unexpected response format")
            return []
    
    def fetch_techdocs_metadata(self, entity: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """
        Fetch TechDocs metadata for an entity.
        
        Args:
            entity: Catalog entity
            
        Returns:
            TechDocs metadata or None
        """
        # Extract entity reference
        metadata = entity.get("metadata", {})
        kind = entity.get("kind", "").lower()
        namespace = metadata.get("namespace", "default")
        name = metadata.get("name", "")
        
        if not name:
            return None
        
        # TechDocs API path
        # Format: /api/techdocs/static/docs/{namespace}/{kind}/{name}
        path = f"/api/techdocs/static/docs/{namespace}/{kind}/{name}"
        
        # Fetch index.html or techdocs_metadata.json
        metadata_path = f"{path}/techdocs_metadata.json"
        techdocs_metadata = self._backstage_request(metadata_path)
        
        if techdocs_metadata:
            return {
                "entity_ref": f"{kind}:{namespace}/{name}",
                "metadata": techdocs_metadata,
                "docs_path": path
            }
        
        return None
    
    def fetch_techdocs_content(self, docs_path: str) -> Optional[str]:
        """
        Fetch TechDocs content (HTML or markdown).
        
        Args:
            docs_path: Path to TechDocs
            
        Returns:
            Content as string or None
        """
        # Try to fetch index.html
        index_path = f"{docs_path}/index.html"
        
        try:
            url = f"{self.backstage_url}{index_path}"
            response = self.session.get(url, timeout=30)
            
            if response.status_code == 200:
                # Extract text from HTML
                content = self._extract_text_from_html(response.text)
                return content
        except Exception as e:
            print(f"  ⚠️  Failed to fetch content: {e}")
        
        return None
    
    def _extract_text_from_html(self, html: str) -> str:
        """
        Extract readable text from HTML using BeautifulSoup.
        
        This provides secure HTML parsing and proper text extraction.
        """
        try:
            # Parse HTML with BeautifulSoup
            soup = BeautifulSoup(html, 'lxml')
            
            # Remove script and style elements
            for element in soup(['script', 'style', 'meta', 'link', 'noscript']):
                element.decompose()
            
            # Get text content
            text = soup.get_text(separator=' ', strip=True)
            
            # Clean up whitespace
            text = re.sub(r'\s+', ' ', text)
            text = text.strip()
            
            return text
        except Exception as e:
            print(f"  ⚠️  Failed to parse HTML with BeautifulSoup: {e}")
            # Fallback to simple text extraction if parsing fails
            text = re.sub(r'<[^>]+>', ' ', html)
            text = re.sub(r'\s+', ' ', text)
            return text.strip()
    
    def extract_sections(self, content: str) -> List[Dict[str, str]]:
        """
        Extract sections from content based on headings.
        
        Args:
            content: Document content
            
        Returns:
            List of sections with heading and content
        """
        # Find markdown-style headings
        sections = []
        current_section = {"heading": "Introduction", "content": ""}
        
        lines = content.split("\n")
        for line in lines:
            # Check for heading (# or ##)
            heading_match = re.match(r'^(#{1,6})\s+(.+)$', line.strip())
            if heading_match:
                # Save previous section if it has content
                if current_section["content"].strip():
                    sections.append(current_section)
                
                # Start new section
                heading_text = heading_match.group(2)
                current_section = {
                    "heading": heading_text,
                    "content": ""
                }
            else:
                # Add to current section
                current_section["content"] += line + "\n"
        
        # Add last section
        if current_section["content"].strip():
            sections.append(current_section)
        
        # If no sections found, return entire content as one section
        if not sections:
            sections.append({"heading": "Content", "content": content})
        
        return sections
    
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
    
    def get_content_hash(self, content: str) -> str:
        """Calculate MD5 hash of content."""
        return hashlib.md5(content.encode("utf-8")).hexdigest()
    
    def index_techdocs(
        self,
        entity_ref: str,
        content: str,
        backstage_url: str,
        force: bool = False
    ) -> Tuple[bool, int]:
        """
        Index TechDocs content.
        
        Args:
            entity_ref: Entity reference (e.g., "component:default/my-service")
            content: Document content
            backstage_url: URL to Backstage docs
            force: Force re-indexing even if unchanged
            
        Returns:
            (success: bool, chunks_indexed: int)
        """
        if not content or not content.strip():
            return True, 0
        
        # Calculate hash
        content_hash = self.get_content_hash(content)
        
        # Check if needs reindex
        full_path = f"backstage:{entity_ref}"
        if not self.dry_run and not force:
            if not self._needs_reindex(full_path, content_hash):
                return True, 0  # Skip, no changes
        
        # Extract title from entity ref
        title = entity_ref.split("/")[-1].replace("-", " ").title()
        
        # Extract sections
        sections = self.extract_sections(content)
        
        if self.dry_run:
            print(f"  📄 Would index: {entity_ref}")
            print(f"     Title: {title}")
            print(f"     Sections: {len(sections)}")
            total_chunks = sum(len(self.chunk_content(s["content"])) for s in sections)
            print(f"     Total chunks: {total_chunks}")
            return True, total_chunks
        
        # Delete existing chunks
        deleted = self._delete_existing_chunks(full_path)
        if deleted > 0:
            print(f"  🗑️  Deleted {deleted} existing chunks")
        
        # Index sections
        indexed_count = 0
        timestamp = datetime.utcnow().isoformat() + "Z"
        
        try:
            with self.weaviate_client.batch as batch:
                batch.batch_size = 10
                
                chunk_idx = 0
                for section in sections:
                    section_heading = section["heading"]
                    section_content = section["content"]
                    
                    # Chunk section content
                    chunks = self.chunk_content(section_content)
                    
                    for chunk in chunks:
                        chunk_id = generate_uuid5(f"{full_path}:chunk:{chunk_idx}")
                        
                        # Include heading in content for context
                        chunk_with_heading = f"# {section_heading}\n\n{chunk}"
                        
                        data_object = {
                            "title": f"{title} - {section_heading}",
                            "content": chunk_with_heading,
                            "filepath": full_path,
                            "category": "techdocs",
                            "fileHash": content_hash,
                            "chunkIndex": chunk_idx,
                            "indexed_at": timestamp,
                        }
                        
                        batch.add_data_object(
                            data_object=data_object,
                            class_name=SCHEMA_NAME,
                            uuid=chunk_id,
                        )
                        indexed_count += 1
                        chunk_idx += 1
            
            return True, indexed_count
        except Exception as e:
            print(f"  ❌ Failed to index {entity_ref}: {e}")
            return False, 0
    
    def _needs_reindex(self, filepath: str, content_hash: str) -> bool:
        """Check if content needs re-indexing."""
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
            return existing_hash != content_hash
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
                .with_limit(200)  # TechDocs can have many chunks
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
    
    def index_all_techdocs(self, force: bool = False):
        """
        Index all TechDocs from Backstage.
        
        Args:
            force: Force re-indexing even if unchanged
        """
        print(f"\n{'='*70}")
        print("Indexing Backstage TechDocs")
        print(f"{'='*70}\n")
        
        # Fetch catalog entities
        entities = self.fetch_catalog_entities()
        
        if not entities:
            print("⚠️  No entities found in catalog")
            return
        
        # Index entities with TechDocs
        success_count = 0
        error_count = 0
        total_chunks = 0
        skipped_count = 0
        techdocs_count = 0
        
        for i, entity in enumerate(entities, 1):
            metadata = entity.get("metadata", {})
            kind = entity.get("kind", "")
            name = metadata.get("name", "")
            
            # Skip if no name
            if not name:
                continue
            
            # Check if entity has TechDocs annotation
            annotations = metadata.get("annotations", {})
            has_techdocs = (
                "backstage.io/techdocs-ref" in annotations or
                "backstage.io/managed-by-location" in annotations
            )
            
            if not has_techdocs:
                continue
            
            techdocs_count += 1
            print(f"[{techdocs_count}] Processing: {kind}/{name}")
            
            # Fetch TechDocs metadata
            techdocs_info = self.fetch_techdocs_metadata(entity)
            
            if not techdocs_info:
                print(f"  ⚠️  No TechDocs found")
                skipped_count += 1
                continue
            
            entity_ref = techdocs_info["entity_ref"]
            docs_path = techdocs_info["docs_path"]
            
            # Fetch content
            content = self.fetch_techdocs_content(docs_path)
            
            if not content:
                print(f"  ⚠️  No content found")
                skipped_count += 1
                continue
            
            # Build Backstage URL
            backstage_url = f"{self.backstage_url}/docs/{entity_ref.replace(':', '/')}"
            
            # Index
            success, chunks = self.index_techdocs(
                entity_ref, content, backstage_url, force
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
        
        # Summary
        print(f"\n{'='*70}")
        print("TechDocs Indexing Summary")
        print(f"{'='*70}")
        print(f"Total entities: {len(entities)}")
        print(f"Entities with TechDocs: {techdocs_count}")
        print(f"Successfully indexed: {success_count}")
        print(f"Skipped (unchanged/no content): {skipped_count}")
        print(f"Errors: {error_count}")
        print(f"Total chunks indexed: {total_chunks}")
        print(f"{'='*70}\n")


def main():
    """Main execution function."""
    parser = argparse.ArgumentParser(
        description="Index Backstage TechDocs into Weaviate RAG system"
    )
    parser.add_argument(
        "--backstage-url",
        required=True,
        help="Backstage instance URL",
    )
    parser.add_argument(
        "--weaviate-url",
        default=DEFAULT_WEAVIATE_URL,
        help=f"Weaviate URL (default: {DEFAULT_WEAVIATE_URL})",
    )
    parser.add_argument(
        "--token",
        help="Optional Backstage authentication token",
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
    
    print("=" * 70)
    print("Backstage TechDocs Indexer for RAG System")
    print("=" * 70)
    
    if args.dry_run:
        print("🔍 DRY RUN MODE - No changes will be made\n")
    
    # Create indexer
    indexer = BackstageIndexer(
        backstage_url=args.backstage_url,
        weaviate_url=args.weaviate_url,
        auth_token=args.token,
        dry_run=args.dry_run
    )
    
    start_time = time.time()
    
    try:
        indexer.index_all_techdocs(args.force_reindex)
    except KeyboardInterrupt:
        print("\n\n⚠️  Indexing interrupted by user")
        sys.exit(1)
    except Exception as e:
        print(f"\n\n❌ Fatal error: {e}")
        import traceback
        traceback.print_exc()
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
