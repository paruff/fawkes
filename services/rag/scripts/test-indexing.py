#!/usr/bin/env python3
"""
Test Weaviate indexing and search functionality.

This script:
1. Connects to Weaviate GraphQL API
2. Creates test schema for documents
3. Indexes sample documents (ADRs, README files)
4. Performs test queries
5. Validates relevance scores >0.7

Usage:
    python test-indexing.py [--weaviate-url URL]

Examples:
    # Use default URL (localhost)
    python test-indexing.py

    # Use custom URL
    python test-indexing.py --weaviate-url http://weaviate.fawkes.svc:80
"""

import sys
import argparse
import time
from pathlib import Path
from typing import List, Dict, Any

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
MIN_RELEVANCE_SCORE = 0.7


def create_client(url: str) -> weaviate.Client:
    """Create and return a Weaviate client."""
    print(f"🔗 Connecting to Weaviate at {url}...")
    try:
        client = weaviate.Client(url)
        # Test connection
        if client.is_ready():
            print("✅ Connected to Weaviate successfully")
            return client
        else:
            print("❌ Weaviate is not ready")
            sys.exit(1)
    except Exception as e:
        print(f"❌ Failed to connect to Weaviate: {e}")
        sys.exit(1)


def create_schema(client: weaviate.Client) -> None:
    """Create the document schema in Weaviate."""
    print(f"\n📋 Creating schema '{SCHEMA_NAME}'...")

    # Delete existing schema if it exists
    try:
        client.schema.delete_class(SCHEMA_NAME)
        print(f"🗑️  Deleted existing schema '{SCHEMA_NAME}'")
    except Exception:
        pass  # Schema doesn't exist, which is fine

    # Define schema
    schema = {
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
                "description": "Document category (adr, readme, doc, code)",
                "indexFilterable": True,
                "indexSearchable": False,
            },
        ],
    }

    try:
        client.schema.create_class(schema)
        print(f"✅ Schema '{SCHEMA_NAME}' created successfully")
    except Exception as e:
        print(f"❌ Failed to create schema: {e}")
        sys.exit(1)


def get_sample_documents() -> List[Dict[str, str]]:
    """Return sample documents for testing."""
    return [
        {
            "title": "ADR-001: Use Kubernetes for Orchestration",
            "content": """
# ADR-001: Use Kubernetes for Orchestration

## Status
Accepted

## Context
We need a container orchestration platform that provides:
- Declarative configuration
- Self-healing capabilities
- Horizontal scaling
- Service discovery
- Load balancing

## Decision
We will use Kubernetes as our container orchestration platform.

## Consequences
- Positive: Industry-standard platform with large ecosystem
- Positive: Strong GitOps support via ArgoCD
- Negative: Complexity and learning curve
- Negative: Resource overhead
""",
            "filepath": "docs/adr/ADR-001-kubernetes-orchestration.md",
            "category": "adr",
        },
        {
            "title": "Fawkes Platform README",
            "content": """
# Fawkes - Internal Product Delivery Platform

Fawkes is an Internal Product Delivery Platform (IDP) that provides
developers with a golden path for building and deploying applications.

## Key Features
- GitOps with ArgoCD
- CI/CD with Jenkins
- Developer Portal with Backstage
- Observability with Prometheus and Grafana
- Security scanning with Trivy and SonarQube

## Quick Start
1. Clone the repository
2. Run `make deploy-local`
3. Access Backstage at http://backstage.local
""",
            "filepath": "README.md",
            "category": "readme",
        },
        {
            "title": "Architecture Documentation",
            "content": """
# Fawkes Architecture

## Overview
Fawkes follows a microservices architecture deployed on Kubernetes.

## Components
- **Backstage**: Developer portal and service catalog
- **ArgoCD**: GitOps continuous delivery
- **Jenkins**: CI/CD pipelines
- **Harbor**: Container registry
- **Prometheus**: Metrics collection
- **Grafana**: Visualization and dashboards

## Design Principles
- GitOps-first: All configuration in Git
- Declarative: Describe desired state, not procedures
- Observable: Every component emits metrics, logs, traces
""",
            "filepath": "docs/architecture.md",
            "category": "doc",
        },
        {
            "title": "Getting Started Guide",
            "content": """
# Getting Started with Fawkes

## Prerequisites
- Kubernetes cluster (local or cloud)
- kubectl CLI
- Helm 3+
- ArgoCD CLI

## Installation Steps
1. Deploy ArgoCD: `kubectl apply -k platform/bootstrap/argocd`
2. Deploy applications: `kubectl apply -f platform/apps/`
3. Access the portal: `kubectl port-forward svc/backstage 7007:7007`

## First Application
Create your first application using the golden path template:
```bash
backstage create app --template java-service
```
""",
            "filepath": "docs/getting-started.md",
            "category": "doc",
        },
        {
            "title": "ADR-020: Vector Database Selection",
            "content": """
# ADR-020: Vector Database Selection

## Status
Accepted

## Context
We need a vector database for RAG (Retrieval Augmented Generation) to:
- Store embeddings of documentation and code
- Enable semantic search
- Support AI-assisted development

## Decision
We will use Weaviate as our vector database.

## Rationale
- Native vector search with HNSW algorithm
- GraphQL API for flexible queries
- Built-in vectorization modules
- Kubernetes-native deployment
- Active community and good documentation

## Consequences
- Positive: Fast semantic search capabilities
- Positive: Flexible schema and data model
- Negative: Additional infrastructure to maintain
""",
            "filepath": "docs/adr/ADR-020-vector-database.md",
            "category": "adr",
        },
    ]


def index_documents(client: weaviate.Client, documents: List[Dict[str, str]]) -> None:
    """Index documents into Weaviate."""
    print(f"\n📝 Indexing {len(documents)} sample documents...")

    with client.batch as batch:
        batch.batch_size = 10

        for i, doc in enumerate(documents, 1):
            # Generate deterministic UUID based on filepath
            doc_id = generate_uuid5(doc["filepath"])

            try:
                batch.add_data_object(
                    data_object={
                        "title": doc["title"],
                        "content": doc["content"],
                        "filepath": doc["filepath"],
                        "category": doc["category"],
                    },
                    class_name=SCHEMA_NAME,
                    uuid=doc_id,
                )
                print(f"  ✅ Indexed: {doc['title']}")
            except Exception as e:
                print(f"  ❌ Failed to index {doc['title']}: {e}")

    # Wait for indexing to complete
    print("⏳ Waiting for indexing to complete...")
    time.sleep(2)
    print("✅ Indexing complete")


def test_queries(client: weaviate.Client) -> bool:
    """Test search queries and validate relevance scores."""
    print("\n🔍 Running test queries...")

    test_cases = [
        {
            "query": "How do I deploy applications?",
            "expected_terms": ["ArgoCD", "GitOps", "deploy", "application"],
        },
        {
            "query": "What is the architecture of the platform?",
            "expected_terms": ["architecture", "microservices", "Kubernetes"],
        },
        {
            "query": "Why was Weaviate chosen for vector search?",
            "expected_terms": ["Weaviate", "vector", "database", "RAG"],
        },
    ]

    all_passed = True

    for i, test_case in enumerate(test_cases, 1):
        query = test_case["query"]
        print(f"\n📊 Test Query {i}: '{query}'")

        try:
            result = (
                client.query
                .get(SCHEMA_NAME, ["title", "filepath", "category"])
                .with_near_text({"concepts": [query]})
                .with_limit(3)
                .with_additional(["certainty", "distance"])
                .do()
            )

            if "data" not in result or "Get" not in result["data"]:
                print("  ❌ No results returned")
                all_passed = False
                continue

            documents = result["data"]["Get"][SCHEMA_NAME]

            if not documents:
                print("  ❌ Empty result set")
                all_passed = False
                continue

            print(f"  📄 Found {len(documents)} results:")

            for j, doc in enumerate(documents, 1):
                certainty = doc.get("_additional", {}).get("certainty", 0)
                distance = doc.get("_additional", {}).get("distance", 1.0)

                # Weaviate uses certainty (0-1, higher is better)
                relevance_ok = certainty >= MIN_RELEVANCE_SCORE
                status = "✅" if relevance_ok else "⚠️"

                print(f"    {status} Result {j}:")
                print(f"       Title: {doc['title']}")
                print(f"       File: {doc['filepath']}")
                print(f"       Certainty: {certainty:.3f}")
                print(f"       Distance: {distance:.3f}")

                if not relevance_ok:
                    print(f"       ⚠️  Certainty {certainty:.3f} < {MIN_RELEVANCE_SCORE}")
                    all_passed = False

            # Check if top result has good relevance
            top_certainty = documents[0].get("_additional", {}).get("certainty", 0)
            if top_certainty >= MIN_RELEVANCE_SCORE:
                print(f"  ✅ Top result certainty {top_certainty:.3f} >= {MIN_RELEVANCE_SCORE}")
            else:
                print(f"  ❌ Top result certainty {top_certainty:.3f} < {MIN_RELEVANCE_SCORE}")
                all_passed = False

        except Exception as e:
            print(f"  ❌ Query failed: {e}")
            all_passed = False

    return all_passed


def main():
    """Main execution function."""
    parser = argparse.ArgumentParser(
        description="Test Weaviate indexing and search functionality"
    )
    parser.add_argument(
        "--weaviate-url",
        default=DEFAULT_WEAVIATE_URL,
        help=f"Weaviate URL (default: {DEFAULT_WEAVIATE_URL})",
    )
    args = parser.parse_args()

    print("=" * 70)
    print("Weaviate Test Indexing Script")
    print("=" * 70)

    # Create client
    client = create_client(args.weaviate_url)

    # Create schema
    create_schema(client)

    # Get sample documents
    documents = get_sample_documents()

    # Index documents
    index_documents(client, documents)

    # Test queries
    success = test_queries(client)

    # Summary
    print("\n" + "=" * 70)
    if success:
        print("✅ All tests passed! Weaviate is working correctly.")
        print("=" * 70)
        return 0
    else:
        print("⚠️  Some tests failed. Check the output above for details.")
        print("=" * 70)
        return 1


if __name__ == "__main__":
    sys.exit(main())
