#!/usr/bin/env bash
set -euo pipefail

# Automated setup script for the platform-task infrastructure.
# Bootstraps the remote state backend and deploys team environments via Terragrunt.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Checking prerequisites..."
command -v tofu >/dev/null 2>&1 || { echo "ERROR: opentofu not found"; exit 1; }
command -v terragrunt >/dev/null 2>&1 || { echo "ERROR: terragrunt not found"; exit 1; }
command -v aws >/dev/null 2>&1 || { echo "ERROR: aws cli not found"; exit 1; }
aws sts get-caller-identity >/dev/null 2>&1 || { echo "ERROR: AWS credentials not configured"; exit 1; }
echo "    All prerequisites met."

echo ""
echo "==> Step 1: Bootstrapping remote state backend..."
cd "$SCRIPT_DIR/bootstrap"
tofu init -input=false
tofu apply -auto-approve

echo ""
echo "==> Step 2: Deploying team environments..."
cd "$SCRIPT_DIR/environments"

echo ""
echo "    Detected team environments:"
for dir in team-*/; do
  echo "      - ${dir%/}"
done

echo ""
echo "    Running terragrunt init for all teams..."
terragrunt run --all init --non-interactive -- -upgrade

echo ""
echo "==> Setup complete!"
echo "    Next steps:"
echo "    1. Edit each team's terragrunt.hcl to set allowed_ip"
echo "    2. cd environments && terragrunt run --all plan"
echo "    3. cd environments && terragrunt run --all apply"
echo ""
echo "    To deploy a single team:"
echo "    cd environments/team-alpha && terragrunt apply"
echo ""
echo "    To onboard a new team:"
echo "    cp -r environments/team-alpha environments/team-newname"
echo "    Edit environments/team-newname/terragrunt.hcl"
