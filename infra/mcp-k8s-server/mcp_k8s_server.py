"""Read-only Kubernetes inspector service for MCP-style access.

Exposes simple HTTP endpoints to list Argo CD Applications and Kubernetes
workloads. Designed to run in-cluster with a least-privilege ServiceAccount.

Endpoints:
- GET /health
- GET /applications?namespace=fawkes
- GET /pods?namespace=fawkes

This code uses in-cluster config; if not available, it falls back to
local kubeconfig (useful for local testing).
"""
from __future__ import annotations

import os
from typing import Dict, Any, List

from fastapi import FastAPI, HTTPException
from kubernetes import client, config


def _load_kubeconfig() -> None:
    try:
        config.load_incluster_config()
    except Exception:
        # Fall back to default kubeconfig for local testing
        config.load_kube_config()


app = FastAPI(title="MCP K8s Inspector", version="0.1.0")


@app.on_event("startup")
def _startup() -> None:
    _load_kubeconfig()


@app.get("/health")
def health() -> Dict[str, str]:
    return {"status": "ok"}


@app.get("/applications")
def list_applications(namespace: str = "fawkes") -> List[Dict[str, Any]]:
    try:
        co = client.CustomObjectsApi()
        data = co.list_namespaced_custom_object(
            group="argoproj.io",
            version="v1alpha1",
            namespace=namespace,
            plural="applications",
        )
    except Exception as e:  # pragma: no cover
        raise HTTPException(status_code=500, detail=str(e))
    items = []
    for item in data.get("items", []):
        meta = item.get("metadata", {})
        status = item.get("status", {})
        items.append(
            {
                "name": meta.get("name"),
                "namespace": meta.get("namespace"),
                "sync": status.get("sync", {}).get("status"),
                "health": status.get("health", {}).get("status"),
                "revision": status.get("sync", {}).get("revision"),
            }
        )
    return items


@app.get("/pods")
def list_pods(namespace: str | None = None) -> List[Dict[str, Any]]:
    try:
        v1 = client.CoreV1Api()
        if namespace:
            resp = v1.list_namespaced_pod(namespace=namespace)
        else:
            resp = v1.list_pod_for_all_namespaces()
    except Exception as e:  # pragma: no cover
        raise HTTPException(status_code=500, detail=str(e))
    return [
        {
            "namespace": p.metadata.namespace,
            "name": p.metadata.name,
            "phase": p.status.phase,
            "node": (p.spec.node_name or ""),
        }
        for p in resp.items
    ]
