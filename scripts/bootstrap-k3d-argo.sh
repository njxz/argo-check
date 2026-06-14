#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="${CLUSTER_NAME:-argo-check}"
ARGO_NAMESPACE="${ARGO_NAMESPACE:-argo}"
WORKFLOW_FILE="${WORKFLOW_FILE:-argo/file-check-pipeline.yaml}"

if ! command -v brew >/dev/null 2>&1 && [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

for bin in brew; do
  command -v "$bin" >/dev/null 2>&1 || {
    echo "$bin is required but was not found."
    exit 1
  }
done

for formula in docker colima kubectl k3d argo; do
  if ! brew list --formula "$formula" >/dev/null 2>&1; then
    brew install "$formula"
  fi
done

if ! colima status >/dev/null 2>&1; then
  colima start --cpu 2 --memory 4
fi

if ! docker info >/dev/null 2>&1; then
  echo "Docker runtime is not available. Check 'colima status' and 'docker context ls'."
  exit 1
fi

if ! k3d cluster list "$CLUSTER_NAME" >/dev/null 2>&1; then
  k3d cluster create "$CLUSTER_NAME" --agents 1
fi

kubectl config use-context "k3d-$CLUSTER_NAME"
kubectl create namespace "$ARGO_NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
kubectl apply --server-side -n "$ARGO_NAMESPACE" -f https://github.com/argoproj/argo-workflows/releases/latest/download/install.yaml
kubectl apply -f argo/workflow-rbac.yaml
kubectl wait --for=condition=available deployment --all -n "$ARGO_NAMESPACE" --timeout=180s

argo submit "$WORKFLOW_FILE" -n "$ARGO_NAMESPACE" --watch
