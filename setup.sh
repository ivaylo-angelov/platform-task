#!/usr/bin/env bash
set -euo pipefail

# Automated setup script for the platform-task infrastructure.
# Bootstraps the remote state backend and generates backend.hcl.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Step 1: Bootstrapping remote state backend..."
cd "$SCRIPT_DIR/bootstrap"
terraform init -input=false
terraform apply -auto-approve

BUCKET=$(terraform output -raw state_bucket_name)
LOCK_TABLE=$(terraform output -raw lock_table_name)
REGION=$(terraform output -raw region)

echo ""
echo "==> Step 2: Generating backend.hcl..."
cd "$SCRIPT_DIR"
cat > backend.hcl <<EOF
bucket         = "${BUCKET}"
key            = "infra/terraform.tfstate"
region         = "${REGION}"
dynamodb_table = "${LOCK_TABLE}"
encrypt        = true
EOF

echo "    Written: backend.hcl"

echo ""
echo "==> Step 3: Initializing main configuration..."
terraform init -input=false -backend-config=backend.hcl

echo ""
echo "==> Setup complete!"
echo "    Next steps:"
echo "    1. cp terraform.tfvars.example terraform.tfvars"
echo "    2. Edit terraform.tfvars and set your allowed_ip"
echo "    3. terraform plan"
echo "    4. terraform apply"
