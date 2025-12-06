#!/usr/bin/env python3
"""
SCORE to Kubernetes Manifest Generator for Fawkes

This script translates score.yaml workload specifications into Kubernetes manifests.
It serves as a reference implementation and bridge to the official score-k8s tool.

Usage:
    python generator.py --score score.yaml --environment dev --output manifests/

Author: Fawkes Platform Team
License: MIT
"""

import argparse
import os
import sys
import yaml
from pathlib import Path
from typing import Dict, Any, List
from jinja2 import Environment, FileSystemLoader, select_autoescape


class ScoreGenerator:
    """
    Generates Kubernetes manifests from SCORE workload specifications.
    """
    
    def __init__(self, score_file: str, environment: str, output_dir: str):
        self.score_file = Path(score_file)
        self.environment = environment
        self.output_dir = Path(output_dir)
        self.score_data = {}
        self.templates_dir = Path(__file__).parent / "templates"
        
        # Setup Jinja2 environment
        self.jinja_env = Environment(
            loader=FileSystemLoader(str(self.templates_dir)),
            autoescape=select_autoescape(['yaml']),
            trim_blocks=True,
            lstrip_blocks=True
        )
    
    def load_score(self):
        """Load and validate score.yaml file."""
        if not self.score_file.exists():
            raise FileNotFoundError(f"SCORE file not found: {self.score_file}")
        
        with open(self.score_file, 'r') as f:
            self.score_data = yaml.safe_load(f)
        
        # Basic validation
        if 'apiVersion' not in self.score_data:
            raise ValueError("score.yaml must have 'apiVersion' field")
        
        if not self.score_data.get('apiVersion', '').startswith('score.dev/'):
            raise ValueError("Invalid SCORE apiVersion")
        
        print(f"✓ Loaded SCORE file: {self.score_file}")
        print(f"  Workload: {self.score_data.get('metadata', {}).get('name', 'unknown')}")
        print(f"  Environment: {self.environment}")
    
    def generate_all(self):
        """Generate all Kubernetes manifests."""
        self.output_dir.mkdir(parents=True, exist_ok=True)
        
        manifests = []
        
        # Generate Deployment
        if 'containers' in self.score_data:
            deployment = self.generate_deployment()
            manifests.append(('deployment.yaml', deployment))
        
        # Generate Service
        if 'service' in self.score_data and 'ports' in self.score_data['service']:
            service = self.generate_service()
            manifests.append(('service.yaml', service))
        
        # Generate Ingress
        if 'route' in self.score_data:
            ingress = self.generate_ingress()
            manifests.append(('ingress.yaml', ingress))
        
        # Generate resource manifests (PVC, ExternalSecrets)
        if 'resources' in self.score_data:
            resource_manifests = self.generate_resources()
            manifests.extend(resource_manifests)
        
        # Write all manifests
        for filename, content in manifests:
            output_file = self.output_dir / filename
            with open(output_file, 'w') as f:
                f.write(content)
            print(f"✓ Generated: {output_file}")
        
        print(f"\n✓ Successfully generated {len(manifests)} manifests")
    
    def generate_deployment(self) -> str:
        """Generate Kubernetes Deployment manifest."""
        template = self.jinja_env.get_template('deployment.yaml.j2')
        
        context = {
            'name': self.score_data['metadata']['name'],
            'namespace': self.get_namespace(),
            'environment': self.environment,
            'containers': self.score_data['containers'],
            'extensions': self.score_data.get('extensions', {}),
            'team': self.get_team(),
        }
        
        return template.render(**context)
    
    def generate_service(self) -> str:
        """Generate Kubernetes Service manifest."""
        template = self.jinja_env.get_template('service.yaml.j2')
        
        context = {
            'name': self.score_data['metadata']['name'],
            'namespace': self.get_namespace(),
            'ports': self.score_data['service']['ports'],
            'team': self.get_team(),
        }
        
        return template.render(**context)
    
    def generate_ingress(self) -> str:
        """Generate Kubernetes Ingress manifest."""
        template = self.jinja_env.get_template('ingress.yaml.j2')
        
        route = self.score_data['route']
        host = route['host'].replace('${ENVIRONMENT}', self.environment)
        
        context = {
            'name': self.score_data['metadata']['name'],
            'namespace': self.get_namespace(),
            'host': host,
            'path': route.get('path', '/'),
            'tls_enabled': route.get('tls', {}).get('enabled', True),
            'team': self.get_team(),
        }
        
        return template.render(**context)
    
    def generate_resources(self) -> List[tuple]:
        """Generate manifests for SCORE resources (DB, cache, secrets, volumes)."""
        manifests = []
        resources = self.score_data.get('resources', {})
        
        for resource_name, resource_def in resources.items():
            resource_type = resource_def.get('type')
            
            if resource_type == 'volume':
                manifest = self.generate_pvc(resource_name, resource_def)
                manifests.append((f'pvc-{resource_name}.yaml', manifest))
            
            elif resource_type in ['postgres', 'redis', 'secret']:
                manifest = self.generate_external_secret(resource_name, resource_def)
                manifests.append((f'externalsecret-{resource_name}.yaml', manifest))
        
        return manifests
    
    def generate_pvc(self, name: str, resource_def: Dict) -> str:
        """Generate PersistentVolumeClaim for volume resources."""
        template = self.jinja_env.get_template('pvc.yaml.j2')
        
        size = resource_def.get('properties', {}).get('size', '1Gi')
        storage_class = resource_def.get('metadata', {}).get('annotations', {}).get('fawkes.dev/storage-class', 'standard')
        access_mode = resource_def.get('metadata', {}).get('annotations', {}).get('fawkes.dev/access-mode', 'ReadWriteOnce')
        
        context = {
            'name': f"{self.score_data['metadata']['name']}-{name}",
            'namespace': self.get_namespace(),
            'size': size,
            'storage_class': storage_class,
            'access_mode': access_mode,
            'team': self.get_team(),
        }
        
        return template.render(**context)
    
    def generate_external_secret(self, name: str, resource_def: Dict) -> str:
        """Generate ExternalSecret for databases, caches, and secrets."""
        # This is a placeholder - actual implementation would integrate with
        # External Secrets Operator and Vault
        return f"""# ExternalSecret for {name} ({resource_def.get('type')})
# TODO: Implement External Secrets Operator integration
# This would create a Secret with connection credentials from Vault
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: {self.score_data['metadata']['name']}-{name}
  namespace: {self.get_namespace()}
spec:
  # Implementation depends on Vault structure
  secretStoreRef:
    name: vault-backend
    kind: SecretStore
  target:
    name: {self.score_data['metadata']['name']}-{name}-credentials
"""
    
    def get_namespace(self) -> str:
        """Determine namespace from team and environment."""
        team = self.get_team()
        return f"{team}-{self.environment}" if team else self.environment
    
    def get_team(self) -> str:
        """Get team name from SCORE extensions."""
        return self.score_data.get('extensions', {}).get('fawkes', {}).get('team', 'default')


def main():
    parser = argparse.ArgumentParser(
        description='Generate Kubernetes manifests from SCORE workload specification'
    )
    parser.add_argument(
        '--score',
        required=True,
        help='Path to score.yaml file'
    )
    parser.add_argument(
        '--environment',
        required=True,
        choices=['dev', 'staging', 'prod'],
        help='Target environment'
    )
    parser.add_argument(
        '--output',
        required=True,
        help='Output directory for generated manifests'
    )
    
    args = parser.parse_args()
    
    try:
        generator = ScoreGenerator(
            score_file=args.score,
            environment=args.environment,
            output_dir=args.output
        )
        
        generator.load_score()
        generator.generate_all()
        
        return 0
    
    except Exception as e:
        print(f"✗ Error: {e}", file=sys.stderr)
        return 1


if __name__ == '__main__':
    sys.exit(main())
