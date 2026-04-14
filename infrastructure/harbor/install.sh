#!/usr/bin/env bash
# Install Harbor into the `harbor` namespace on the current kube context.
# Invoked by `make harbor-install`.
set -euo pipefail

HARBOR_NAMESPACE="${HARBOR_NAMESPACE:-harbor}"
HARBOR_RELEASE="${HARBOR_RELEASE:-harbor}"
HARBOR_CHART_VERSION="${HARBOR_CHART_VERSION:-1.17.1}"
VALUES_FILE="${VALUES_FILE:-infrastructure/harbor/values.yaml}"

echo ">>> Ensuring harbor Helm repo is registered"
helm repo add harbor https://helm.goharbor.io 2>/dev/null || true
helm repo update harbor

echo ">>> Creating namespace ${HARBOR_NAMESPACE} (idempotent)"
kubectl create namespace "${HARBOR_NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -

echo ">>> helm upgrade --install ${HARBOR_RELEASE} harbor/harbor (chart ${HARBOR_CHART_VERSION})"
helm upgrade --install "${HARBOR_RELEASE}" harbor/harbor \
  --version "${HARBOR_CHART_VERSION}" \
  --namespace "${HARBOR_NAMESPACE}" \
  --values "${VALUES_FILE}" \
  --wait --timeout 10m

echo ""
echo "Harbor installed. Next steps:"
echo "  make harbor-ui              # open Harbor UI via minikube tunnel"
echo "  make harbor-admin-password  # print the admin password"
echo "  make harbor-login           # docker login against the registry"
