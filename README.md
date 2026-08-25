# Orders API AWS infrastructure

This repository is a production-shaped Terraform demonstration for Semantic
Terraform Agent (STFA). It models an internet-facing order-processing API on AWS
without running `terraform apply`.

## Architecture

- A dedicated VPC across two Availability Zones.
- Public subnets for an Application Load Balancer and NAT gateway.
- Private subnets for ECS/Fargate tasks and PostgreSQL RDS.
- Security-group isolation between the load balancer, application, and database.
- Separate ECS execution/task IAM roles, scoped database-secret access, and
  CloudWatch application logs.
- Encrypted, private, Multi-AZ PostgreSQL with AWS-managed master credentials.
- Production lifecycle guardrails evaluated during Terraform plan.

```text
Internet
   |
Application Load Balancer (public subnets)
   |
ECS/Fargate orders API (private subnets)
   |
PostgreSQL RDS Multi-AZ (private subnets)
```

## Deliberate STFA scenario

The `test2` branch contains one production safety regression in `variables.tf`:

```hcl
database_deletion_protection = false
```

The RDS resource requires deletion protection in production. Consequently:

1. `terraform fmt` passes.
2. `terraform init` passes.
3. `terraform validate` passes.
4. `terraform plan -refresh=false` fails on `aws_db_instance.orders` with:

```text
Production databases must enable deletion protection.
```

The evidence-backed fix is intentionally small: set the variable default to
`true`. The agent should preserve the RDS guardrail rather than deleting or
weakening it.

## CI behavior

The GitHub workflow performs a refresh-free plan with explicit non-production
placeholder credentials. They cannot access an AWS account and exist only so the
AWS provider can construct an offline plan. The hosted STFA worker independently
uses the repository's verified cross-account role and temporary STS credentials.

No workflow runs `terraform apply`, and this repository should not be applied as-is
without reviewing networking cost, database sizing, DNS/TLS, and the placeholder
application image configuration.

## Dashboard configuration

| Setting | Value |
| --- | --- |
| Terraform directory | `.` |
| Terraform version | `1.15.7` |
| Workflow name | `Terraform CI` |
| Terraform paths | `**/*.tf`, `**/*.tf.json` |
| Failed stage | `plan` |
| Pull request trigger | Enabled |
| AWS region | `ap-south-1` |

## Expected demo flow

1. Open a pull request from `test2` into the repository's baseline branch.
2. Wait for `Terraform CI` to fail at Terraform Plan.
3. Confirm a hosted run is queued automatically in STFA.
4. Review the RDS root cause, constraint evidence, candidate patch, and isolated
   verification attempt.
5. Review the PR comment. Applying or merging remains a human decision.
