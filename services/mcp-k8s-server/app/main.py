from fastapi import FastAPI
from kubernetes import client, config

app = FastAPI(title="MCP K8s Inspector", version="0.1.0")


@app.on_event("startup")
def init_k8s():
    try:
        config.load_incluster_config()
    except Exception:
        config.load_kube_config()


@app.get("/healthz")
def healthz():
    return {"status": "ok"}


@app.get("/pods")
def list_pods(namespace: str = "fawkes"):
    v1 = client.CoreV1Api()
    pods = v1.list_namespaced_pod(namespace).items
    return [{
        "name": p.metadata.name,
        "namespace": p.metadata.namespace,
        "phase": p.status.phase,
    } for p in pods]
