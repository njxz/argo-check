#!/usr/bin/env bash
set -euo pipefail

if [ -z "${TERRAFORM_BIN:-}" ] && [ -x ".tools/terraform/terraform" ]; then
  TERRAFORM_BIN=".tools/terraform/terraform"
fi

TERRAFORM_BIN="${TERRAFORM_BIN:-terraform}"

"$TERRAFORM_BIN" fmt -check -recursive infra/terraform

for dir in infra/terraform/envs/*; do
  [ -d "$dir" ] || continue
  "$TERRAFORM_BIN" -chdir="$dir" init -backend=false
  "$TERRAFORM_BIN" -chdir="$dir" validate
done

if command -v kubeconform >/dev/null 2>&1; then
  find k8s atlantis argo -name '*.yaml' -print0 | xargs -0 kubeconform -summary -ignore-missing-schemas
else
  echo "kubeconform not installed; skipping Kubernetes schema validation."
fi
