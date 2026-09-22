# Terraform AWS Lab

A portfolio-scale AWS infrastructure lab demonstrating reusable Terraform modules, environment boundaries, secure defaults, cost-free tests, and CI validation.

## Architecture

```text
Internet → API Gateway HTTP API → Lambda → DynamoDB
                                      └→ CloudWatch Logs

Dedicated VPC → public subnet + two private subnets
```

The serverless API and networking module are intentionally separate: they demonstrate two common infrastructure concerns without coupling Lambda to a VPC it does not need.

## Repository layout

- `modules/networking` — dedicated VPC and stably keyed subnets
- `modules/serverless-api` — HTTP API, Lambda, DynamoDB, IAM, and logging
- `environments/dev` — runnable development composition
- `environments/prod` — documented production boundary, intentionally not deployable by default
- `tests` — Terraform native tests using a mocked AWS provider

## Requirements and assumptions

| Component | Version / choice |
| --- | --- |
| Terraform | 1.7.3 (`~> 1.7`) |
| AWS provider | `~> 5.0` |
| State | Local only for this non-production lab; use encrypted remote state with locking for team or production use |
| Execution | Local validation and GitHub Actions; no automated apply |
| Criticality | Portfolio demonstration, not production |

## Validate without deploying

```bash
terraform fmt -check -recursive
terraform -chdir=environments/dev init -backend=false
terraform -chdir=environments/dev validate
terraform -chdir=modules/networking init -backend=false
terraform -chdir=modules/networking test
trivy config .
```

## Safe deployment workflow

No infrastructure is deployed automatically. If adapting the lab, authenticate through a short-lived AWS identity, configure reviewed remote state, then create a saved plan:

```bash
terraform -chdir=environments/dev plan -out=tfplan
terraform -chdir=environments/dev show tfplan
```

Apply only the reviewed `tfplan` artifact with explicit approval. Never commit state, plan files, credentials, account identifiers, or production variable files.

## Security choices

- Dedicated VPC rather than the default VPC
- No automatic public IP assignment; individual workloads must opt in explicitly
- Stable `for_each` subnet identities to reduce replacement churn
- DynamoDB encryption and point-in-time recovery
- Least-privilege Lambda access scoped to one table
- CloudWatch retention, X-Ray tracing, API throttling, and no plaintext secrets
- Read-only CI permissions and no cloud credentials or apply stage

## Cost note

Formatting, validation, mocked tests, and security scans are cost-free. An actual apply can create billable AWS resources. Review the plan and AWS pricing before deployment.

## Rollback

This repository does not mutate state or deploy resources. For an adapted deployment, retain the reviewed plan and state version. Before removing anything, run `terraform plan -destroy`, review every explicit and implicit deletion, and obtain approval before applying the destroy plan.

## License

MIT
