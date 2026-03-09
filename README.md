# Platform Task - AWS Infrastructure

Terraform project that provisions a secure AWS VPC environment with public and private EC2 instances, accessible via AWS Systems Manager (SSM) Session Manager — no SSH keys required.

## Architecture

![Architecture Diagram](generated-diagrams/architecture.png)

### What Gets Created

| Resource | Details |
|----------|---------|
| **VPC** | `10.0.0.0/16` with DNS support enabled |
| **Public Subnets** | One per AZ (e.g. `10.0.0.0/24`, `10.0.1.0/24`, `10.0.2.0/24`) |
| **Private Subnets** | One per AZ (e.g. `10.0.10.0/24`, `10.0.11.0/24`, `10.0.12.0/24`) |
| **Internet Gateway** | Attached to VPC for public subnet internet access |
| **NAT Gateway** | Single NAT GW in first public subnet — gives private subnets outbound internet |
| **Public EC2** | `t4g.micro` (Graviton/ARM64), Amazon Linux 2023, in first public subnet |
| **Private EC2** | `t4g.micro` (Graviton/ARM64), Amazon Linux 2023, in first private subnet |
| **IAM Role** | SSM-enabled instance profile attached to both instances |
| **Security Groups** | Public: HTTPS (443) + SSH (22) from a single IP. Private: all traffic from public SG only |
| **VPC Flow Logs** | CloudWatch Logs destination, 30-day retention, 60s aggregation |

### Design Decisions

- **SSM as primary access** — No key management, fully auditable sessions via CloudTrail. SSH (port 22) is open to the allowed IP as a fallback but SSM is the intended access method
- **Graviton (ARM64)** — Better price/performance ratio vs x86 instances
- **IMDSv2 enforced** — Instance metadata service hardened against SSRF attacks
- **Encrypted EBS volumes** — Root volumes use gp3 with encryption enabled
- **S3 + DynamoDB backend** — Remote state with locking prevents concurrent modifications
- **Multi-AZ VPC** — Subnets span all available AZs in the region (dynamically computed via `cidrsubnet`)
- **VPC Flow Logs** — Network traffic logged to CloudWatch for observability and security auditing
- **Community Terraform modules** — Uses battle-tested [terraform-aws-modules](https://github.com/terraform-aws-modules) for VPC, security groups, and EC2

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.5 (or [OpenTofu](https://opentofu.org/docs/intro/install/))
- [AWS CLI v2](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) configured with credentials
- [Session Manager Plugin](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html) for AWS CLI

Verify your setup:

```bash
terraform --version              # >= 1.5
aws sts get-caller-identity      # should return your account
session-manager-plugin           # should print version info
```

## Quick Start

### Automated Setup

A setup script handles bootstrapping, backend configuration, and initialization in one step:

```bash
./setup.sh
```

Then configure your variables and deploy:

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars — set allowed_ip to your public IP:
#   curl -s https://checkip.amazonaws.com

terraform fmt -check
terraform validate
terraform plan
terraform apply
```

### Manual Setup (Step-by-Step)

<details>
<summary>Click to expand manual steps</summary>

#### Step 1: Bootstrap the Remote State Backend

This creates the S3 bucket and DynamoDB table used for Terraform state storage and locking.

```bash
cd bootstrap
terraform init
terraform apply
```

Note the outputs — you'll need the bucket name in the next step:

```bash
terraform output
# state_bucket_name = "platform-task-tfstate-123456789012"
# lock_table_name   = "platform-task-tflock"
# region            = "eu-west-1"
```

#### Step 2: Configure the Backend

```bash
cd ..
cp backend.hcl.example backend.hcl
```

Edit `backend.hcl` and replace `ACCOUNT_ID` with your AWS account ID (from the bootstrap output):

```hcl
bucket         = "platform-task-tfstate-123456789012"
key            = "infra/terraform.tfstate"
region         = "eu-west-1"
dynamodb_table = "platform-task-tflock"
encrypt        = true
```

#### Step 3: Configure Variables

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` and set your public IP. To find it:

```bash
curl -s https://checkip.amazonaws.com
```

Then update `terraform.tfvars`:

```hcl
allowed_ip = "203.0.113.1/32"   # Replace with your IP
```

#### Step 4: Deploy the Infrastructure

```bash
terraform init -backend-config=backend.hcl
terraform fmt -check
terraform validate
terraform plan
terraform apply
```

</details>

### Step 5: Connect to the Instances

After deployment, Terraform outputs ready-to-use SSM connection commands:

```bash
# Copy the command directly from Terraform output
$(terraform output -raw ssm_connect_public)

# Or for the private instance
$(terraform output -raw ssm_connect_private)
```

### Step 6: Verify Internet Connectivity

Once connected via SSM, run from inside the instance:

```bash
curl -s https://checkip.amazonaws.com
```

- The **public instance** returns its own public IP
- The **private instance** returns the NAT Gateway's Elastic IP

## Tear Down

Destroy in reverse order:

```bash
# 1. Destroy the main infrastructure
terraform destroy

# 2. Destroy the bootstrap resources (optional)
cd bootstrap
terraform destroy
```

> **Note:** The S3 bucket has `prevent_destroy = true` as a safety measure. To fully remove it, edit `bootstrap/main.tf` to remove the lifecycle rule, empty the bucket (`aws s3 rm s3://BUCKET_NAME --recursive`), then run `terraform destroy` again.

## Project Structure

```
.
├── bootstrap/                  # Remote state backend (S3 + DynamoDB)
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── versions.tf
├── setup.sh                    # Automated bootstrap + backend config + init
├── main.tf                     # Locals, data sources (AZs, AMI)
├── vpc.tf                      # VPC, subnets, NAT GW, flow logs
├── security.tf                 # Public and private security groups
├── iam.tf                      # SSM role and instance profile
├── compute.tf                  # EC2 instances (Graviton, Amazon Linux 2023)
├── variables.tf                # Input variables with defaults and validation
├── outputs.tf                  # Useful outputs (instance IDs, SSM commands)
├── versions.tf                 # Provider and Terraform version constraints
├── backend.tf                  # S3 backend configuration (partial)
├── backend.hcl.example         # Backend config template
├── terraform.tfvars.example    # Variables template
├── generated-diagrams/         # Architecture diagram
└── README.md
```

## Cost Estimate

Approximate monthly costs for `eu-west-1` (USD):

| Resource | Cost |
|----------|------|
| NAT Gateway | ~$32 + $0.048/GB data processed |
| EC2 `t4g.micro` x2 | ~$15 (or free-tier eligible) |
| EBS gp3 volumes x2 | ~$2 |
| VPC Flow Logs (CloudWatch) | ~$0.50/GB ingested |
| S3 state bucket | < $0.01 |
| DynamoDB lock table | < $0.01 |
| **Total** | **~$50/month** (mostly NAT Gateway) |

> **Tip:** Remember to run `terraform destroy` when you're done to avoid ongoing charges.

## Production Considerations

This project is scoped for a technical assessment. In a production environment, you would additionally consider:

- **SSM VPC Endpoints** — Add interface endpoints for `ssm`, `ssmmessages`, and `ec2messages` so SSM traffic stays on the AWS backbone instead of routing through the NAT Gateway / public internet
- **NAT Gateway per AZ** — The current setup uses a single NAT GW for cost efficiency; production workloads should use one per AZ for high availability (`single_nat_gateway = false`, `one_nat_gateway_per_az = true`)
- **Auto Scaling** — Replace standalone instances with Auto Scaling Groups for self-healing
- **Monitoring & Alerting** — CloudWatch alarms on instance health, NAT GW bandwidth, and Flow Log anomalies

## Community Modules Used

| Module | Version | Purpose |
|--------|---------|---------|
| [terraform-aws-modules/vpc/aws](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws) | ~> 5.21 | VPC, subnets, IGW, NAT GW, route tables, flow logs |
| [terraform-aws-modules/security-group/aws](https://registry.terraform.io/modules/terraform-aws-modules/security-group/aws) | ~> 5.3 | Public and private security groups |
| [terraform-aws-modules/ec2-instance/aws](https://registry.terraform.io/modules/terraform-aws-modules/ec2-instance/aws) | ~> 5.8 | EC2 instances with best-practice defaults |
