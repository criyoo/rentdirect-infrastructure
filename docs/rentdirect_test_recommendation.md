# RentDirect Infrastructure Test Recommendation

**Date:** 2026-06-21
**Project:** RentDirect Rental Marketplace
**Scope:** Terraform, AWS, container deployment, infrastructure security, resilience, and infrastructure observability tests.

---

## Table of Contents

1. [Terraform and AWS Testing](#1-terraform-and-aws-testing)
2. [Container and Deployment Testing](#2-container-and-deployment-testing)
3. [Infrastructure Security Testing](#3-infrastructure-security-testing)
4. [Resilience and Chaos Testing](#4-resilience-and-chaos-testing)
5. [Infrastructure Performance Testing](#5-infrastructure-performance-testing)
6. [Infrastructure Monitoring and Observability](#6-infrastructure-monitoring-and-observability)
7. [Infrastructure Test Roadmap](#7-infrastructure-test-roadmap)
8. [Recommended Infrastructure Test Tools](#8-recommended-infrastructure-test-tools)

---

## 1. Terraform and AWS Testing

### 1.1 Terraform Formatting and Validation

**Purpose:** Catch syntax, provider, module, and variable issues before deployment.

**Recommended checks:**

```bash
terraform fmt -check -recursive
terraform init -backend=false
terraform validate
```

**Coverage:**

- Root Terraform configuration
- Environment variable files in `infra/terraform/envs`
- ECS service module
- Networking, database, storage, IAM, secrets, and DNS modules

### 1.2 Terraform Plan Testing

**Purpose:** Review infrastructure changes before they are applied.

**Recommended checks:**

```bash
terraform plan -var-file=envs/dev.tfvars
terraform plan -var-file=envs/prod.tfvars
```

**Required review areas:**

- No unexpected resource deletion
- ECS task definitions contain the intended API and payout worker commands
- Secrets are referenced from AWS Secrets Manager or SSM, not committed as plain text
- Dev and production use the correct domains, URLs, and bank/payment configuration sources
- Production changes do not inherit local-only settings

### 1.3 Policy Validation

**Purpose:** Enforce infrastructure rules before deployment.

**Tools:** OPA/Conftest, Checkov, TFLint

**Recommended policies:**

- S3 buckets block public write access
- Security groups do not expose database ports publicly
- ECS services use least-privilege IAM roles
- Secrets are not passed as non-secret environment variables
- Production resources require encryption and deletion protection where appropriate

### 1.4 Environment Drift Testing

**Purpose:** Detect differences between expected Terraform state and actual cloud resources.

**Recommended checks:**

```bash
terraform plan -refresh-only -var-file=envs/dev.tfvars
terraform plan -refresh-only -var-file=envs/prod.tfvars
```

**Coverage:**

- ECS task definitions and services
- Load balancers and target groups
- DNS records and certificates
- RDS configuration
- S3 bucket policies
- Secrets and environment variable references

---

## 2. Container and Deployment Testing

### 2.1 Docker Image Build Testing

**Purpose:** Verify API images can be built for the target runtime.

**Recommended checks:**

```bash
docker build --target production -t rentdirect-api:test apps/api
docker build --target development -t rentdirect-api:dev apps/api
```

**Coverage:**

- Production image starts with Gunicorn
- Development image starts with Django runserver
- Entrypoint permissions are valid
- Required OS packages and Python dependencies are installed

### 2.2 Container Security Scanning

**Purpose:** Detect vulnerable packages and unsafe image configuration.

**Tools:** Trivy, Grype, Docker Scout

**Recommended checks:**

```bash
trivy image rentdirect-api:test
grype rentdirect-api:test
```

**Coverage:**

- Base image vulnerabilities
- OS package vulnerabilities
- Python dependency vulnerabilities inside the image
- Non-root production user configuration

### 2.3 ECS Task Definition Testing

**Purpose:** Verify API, migration, and payout worker containers are configured correctly.

**Recommended checks:**

- API task exposes container port `8000`
- Payout worker task runs `python manage.py watch_ready_payouts`
- Migration task runs `python manage.py migrate`
- API and payout worker share the required runtime environment and secrets
- CloudWatch log groups and stream prefixes are configured
- Health checks match the real application readiness endpoint

### 2.4 Deployment Smoke Tests

**Purpose:** Confirm the deployed infrastructure serves the application correctly.

**Recommended checks after deployment:**

- Load balancer target group is healthy
- API readiness endpoint responds through the public API domain
- Web domain serves the expected frontend build
- ECS service desired count equals running count
- Payout worker service is running and logging
- Migration task completed successfully

---

## 3. Infrastructure Security Testing

### 3.1 IaC Security Scanning

**Purpose:** Catch insecure infrastructure before it reaches AWS.

**Tools:** Checkov, tfsec, Terrascan

**Recommended checks:**

```bash
checkov -d infra/terraform
tfsec infra/terraform
terrascan scan -t aws -i terraform -d infra/terraform
```

**Coverage:**

- IAM permissions
- Security group ingress and egress
- RDS encryption and public access
- S3 public access and encryption
- ALB listener and TLS configuration
- CloudWatch log retention

### 3.2 Secret Scanning

**Purpose:** Prevent credentials from entering the repository or image layers.

**Tools:** Gitleaks, TruffleHog, GitHub secret scanning

**Recommended checks:**

```bash
gitleaks detect --source .
trufflehog filesystem .
```

**Coverage:**

- Terraform variable files
- Local `.env` files
- Docker Compose files
- CI/CD configuration
- Container build context

### 3.3 AWS Permission Testing

**Purpose:** Validate least-privilege behavior.

**Recommended checks:**

- ECS task role can access only required secrets
- ECS execution role can pull images and write logs
- Application task cannot modify infrastructure resources
- S3 permissions are limited to required buckets and actions
- Production secrets cannot be read by development-only roles

### 3.4 Network Security Testing

**Purpose:** Verify only intended network paths are open.

**Recommended checks:**

- Database is reachable from ECS only
- Private subnets do not expose internal services publicly
- ALB exposes only expected HTTP/HTTPS listeners
- Security groups do not allow unrestricted admin/database access
- Egress rules are documented and limited where practical

---

## 4. Resilience and Chaos Testing

### 4.1 Service Failure Testing

**Purpose:** Validate recovery when cloud services or tasks fail.

**Recommended scenarios:**

- Stop one API ECS task and verify service replacement
- Stop the payout worker task and verify it restarts
- Simulate failed migration task and verify deployment behavior
- Restart RDS during a staging maintenance window and verify application recovery

### 4.2 Network Chaos Testing

**Purpose:** Understand behavior under degraded network conditions.

**Recommended scenarios:**

- Temporarily block outbound access to external payment providers in staging
- Simulate slow database responses
- Simulate intermittent DNS resolution failures
- Verify retries and timeouts do not exhaust ECS resources

### 4.3 Load and Chaos Combination

**Purpose:** Verify infrastructure remains stable during stress and partial failure.

**Recommended scenarios:**

- Run application load tests while recycling ECS tasks
- Run webhook retry traffic while payout worker is restarting
- Monitor ALB 5xx errors, ECS CPU/memory, and database connections

---

## 5. Infrastructure Performance Testing

### 5.1 Capacity Testing

**Purpose:** Validate that provisioned infrastructure can support expected traffic.

**Recommended checks:**

- ECS CPU and memory usage under representative application load
- ALB request count, target response time, and 5xx rates
- RDS CPU, memory, storage, and connection count
- NAT gateway or outbound traffic behavior where applicable

### 5.2 Scaling Tests

**Purpose:** Verify autoscaling or manual scaling behavior.

**Recommended checks:**

- API service scales to the configured desired count
- New ECS tasks pass health checks before receiving traffic
- Scale-in does not terminate all healthy tasks
- Payout worker service remains singleton if required by payout processing assumptions

### 5.3 Database Infrastructure Tests

**Purpose:** Validate database infrastructure configuration.

**Recommended checks:**

- Automated backups are enabled
- Restore process is tested in a non-production environment
- Storage autoscaling or alerting is configured
- Production deletion protection is enabled where required

---

## 6. Infrastructure Monitoring and Observability

### 6.1 CloudWatch Log Testing

**Purpose:** Verify deployed services emit logs to the expected destinations.

**Recommended checks:**

- API logs reach the API CloudWatch log group
- Payout worker logs reach the expected log group and stream prefix
- Migration task logs are retained long enough for deployment debugging
- Log retention is configured by environment

### 6.2 Metric and Alarm Testing

**Purpose:** Ensure infrastructure failures trigger visibility.

**Recommended alarms:**

- ALB 5xx rate
- ECS service running task count below desired count
- ECS CPU/memory high usage
- RDS CPU, storage, and connection exhaustion
- Target group unhealthy host count
- Payout worker task stopped unexpectedly

### 6.3 Deployment Observability Testing

**Purpose:** Make deployments auditable and debuggable.

**Recommended checks:**

- Deployment scripts report image tag, environment, and task definition revision
- ECS service events are reviewed after deployment
- Failed deployments preserve enough logs to diagnose root cause
- Rollback path is documented and tested in development

---

## 7. Infrastructure Test Roadmap

### Phase 1: Immediate

- Keep a single canonical local Docker Compose file at the repository root
- Add Terraform `fmt`, `validate`, and plan checks for development
- Add Docker image build checks
- Add ECS deployment smoke checks

### Phase 2: Pre-Launch

- Add Checkov/tfsec scanning to CI
- Add Trivy or Grype image scans
- Add secret scanning
- Add refresh-only drift checks for development
- Test payout worker ECS service recovery

### Phase 3: Production Readiness

- Add production Terraform plan review gates
- Add CloudWatch alarms for ECS, ALB, RDS, and payout worker health
- Test RDS backup restore
- Run staging resilience tests before production launch
- Document rollback and incident response steps

---

## 8. Recommended Infrastructure Test Tools

| Category | Tool |
| --- | --- |
| Terraform formatting/validation | `terraform fmt`, `terraform validate` |
| Terraform linting | TFLint |
| IaC security | Checkov, tfsec, Terrascan |
| Policy testing | OPA, Conftest |
| Secret scanning | Gitleaks, TruffleHog |
| Image scanning | Trivy, Grype, Docker Scout |
| AWS deployment checks | AWS CLI, ECS service events, CloudWatch |
| Drift detection | `terraform plan -refresh-only` |
| Resilience testing | AWS Fault Injection Service, controlled ECS/RDS failure tests |
