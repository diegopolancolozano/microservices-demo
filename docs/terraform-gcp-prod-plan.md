# Terraform + GCP Plan (prod only)

Status: draft
Owner: infraestructura
Date: 2026-04-11

Current implementation note (2026-04-15):
- This file is a target-state plan.
- API Gateway is not currently implemented in the active deployment.
- Pub/Sub Retry + DLQ is currently disabled in `terraform/live/prod/terraform.tfvars`.

## 1) Scope

This plan documents the target implementation for infrastructure pipelines in GCP using Terraform.
Current constraint: there is no GCP access yet, so this is planning-only and tracking-ready.

In scope:
- Single environment: prod
- Design pattern 1: API Gateway
- Design pattern 2: Retry
- Terraform CI/CD pipelines in GitHub Actions

Out of scope (for now):
- Multi-environment setup (dev/staging)
- Full service mesh and circuit breaker

## 2) Architecture decisions

### Decision A: API Gateway pattern

Intent:
- Single public entrypoint
- Route requests to Cloud Run services
- Central auth and rate controls

Expected GCP services:
- API Gateway
- Cloud Run (backend services)
- Secret Manager (secrets)

### Decision B: Retry pattern

Intent:
- Handle transient failures in async flows
- Avoid message loss

Expected GCP services:
- Pub/Sub topics + subscriptions
- Retry policy in subscriptions
- Dead letter topic (DLQ)

Technical rules:
- Max delivery attempts defined explicitly
- Exponential backoff bounds defined explicitly
- Consumers must be idempotent

## 3) Terraform structure proposal

```text
terraform/
  live/
    prod/
      backend.tf
      providers.tf
      main.tf
      variables.tf
      outputs.tf
      terraform.tfvars.example
  modules/
    api_gateway/
      main.tf
      variables.tf
      outputs.tf
    cloud_run_service/
      main.tf
      variables.tf
      outputs.tf
    pubsub_retry/
      main.tf
      variables.tf
      outputs.tf
    iam/
      main.tf
      variables.tf
      outputs.tf
    monitoring/
      main.tf
      variables.tf
      outputs.tf
```

## 4) Pipeline design (GitHub Actions)

### Workflow 1: Terraform CI

Suggested file:
- .github/workflows/infra-terraform-ci.yml

Trigger:
- pull_request to main

Main steps:
1. terraform fmt -check -recursive
2. terraform init (no apply)
3. terraform validate
4. tflint
5. tfsec (or checkov)
6. terraform plan -out tfplan
7. Upload plan artifact

Result:
- Blocks merge when infra quality gates fail

### Workflow 2: Terraform CD (prod)

Suggested file:
- .github/workflows/infra-terraform-prod-apply.yml

Trigger:
- push to main
- protected environment: prod (manual approval required)

Main steps:
1. Download plan artifact (or regenerate with same commit)
2. terraform init
3. terraform apply
4. post-deploy smoke checks

Auth recommendation:
- GitHub OIDC + Workload Identity Federation
- Avoid static service account keys

## 5) Backlog (implementation order)

1. Create Terraform folder skeleton (live/prod + modules)
2. Add remote state backend in GCS (versioning + encryption)
3. Add providers and required versions pinning
4. Implement IAM least-privilege service accounts
5. Implement Cloud Run module and service definitions
6. Implement API Gateway module and OpenAPI integration
7. Implement Pub/Sub Retry + DLQ module
8. Implement monitoring alerts (5xx, DLQ growth, retries)
9. Add Terraform CI workflow
10. Add Terraform CD workflow with manual approval
11. Add smoke checks and operational runbook

## 6) Acceptance criteria

- Terraform validates and plans successfully in CI
- Main branch deploy requires manual approval to prod
- API Gateway routes to target Cloud Run backends
- Retry policy works and failed messages go to DLQ
- Alerting is active for API errors and DLQ growth

## 7) Risks and mitigations

Risk: over-permissioned identities
- Mitigation: explicit IAM roles per module and least privilege review

Risk: infra drift
- Mitigation: plan required before apply, no manual console changes

Risk: retry storms
- Mitigation: bounded retries + dead letter topic + alerting

Risk: cost surprises
- Mitigation: labels/tags + budget alerts

## 8) Pending inputs (blocked until GCP access)

- GCP project id for prod
- Billing account linkage
- Final domain and DNS zone for API Gateway
- Secret inventory and ownership
- Approval owners for prod environment

## 9) Ready-to-start checklist

- [ ] Confirm GCP project id (prod)
- [ ] Confirm GitHub repo environment "prod" approvers
- [ ] Confirm auth mode: OIDC + WIF
- [ ] Create terraform folder skeleton
- [ ] Create CI workflow draft
- [ ] Create CD workflow draft
- [ ] Validate plan in PR
- [ ] Execute first approved apply to prod
