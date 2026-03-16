ARGOCD_PASSWORD=""
if kubectl get secret argocd-initial-admin-secret -n argocd &> /dev/null; then
  ARGOCD_PASSWORD="$(kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath='{.data.password}' | base64 --decode 2>/dev/null)"
  if [ -z "$ARGOCD_PASSWORD" ]; then
    ARGOCD_PASSWORD="$(kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath='{.data.password}' | base64 -d 2>/dev/null)"
  fi
else
  ARGOCD_PASSWORD="(see: kubectl get secret argocd-initial-admin-secret -n argocd)"
fi
