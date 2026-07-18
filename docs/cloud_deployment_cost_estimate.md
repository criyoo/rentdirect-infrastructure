# RentDirect Cloud Deployment Cost Estimate

Reviewed on: 2026-05-05

## Scope

This document estimates monthly infrastructure and operational cost for the current RentDirect deployment after reviewing:

- `infra/terraform/envs/dev.tfvars`
- `infra/terraform/envs/prod.tfvars`
- `infra/terraform/main.tf`
- `infra/terraform/modules/networking/*`
- `infra/terraform/modules/databases/*`
- `infra/terraform/modules/storage/*`
- `infra/terraform/modules/ecs_service/*`
- `apps/api/config/settings.py`
- `apps/api/core/views.py`
- `apps/api/core/models.py`
- `apps/web`

The estimate covers:

- the current development environment
- the current production launch baseline
- a moderate production growth scenario on the same architecture
- third-party operational costs visible from the codebase or explicitly requested for planning

These are planning estimates, not invoices.

## Architecture Review Findings

- The frontend is a static Vite build hosted from private S3 behind CloudFront.
- Media uploads are stored in a private S3 bucket and served through a dedicated CloudFront distribution on `media.<domain>`.
- The backend is a single ECS Fargate API service on ARM in `eu-west-1`.
- The API is exposed through a public ALB and is also routed through the main CloudFront distribution for `/api/*`.
- ECS tasks still use public IPv4 addresses because the stack avoids NAT gateways.
- Redis is enabled in both dev and prod on `cache.t4g.micro`.
- Development uses `db.t4g.micro`; production currently uses `db.t4g.small`.
- Both CloudFront distributions use `PriceClass_100`.
- A CloudFront Function rewrites SPA routes for the frontend distribution, so frontend request volume has a small extra runtime cost.
- Application email is configured against GoDaddy SMTP (`smtpout.secureserver.net`) with `info@rentdirect.homes`.
- Payment-related code currently points to OPay configuration and mocked featured-payment checkout flows, not a live Paystack integration.
- NIN is collected and validated in the application, but no external automated NIN verification API integration is present in the reviewed codebase today.
- The frontend links out to Google Maps search URLs and uses Leaflet, but no billed Google Maps API key or paid geocoding SDK was found.

## Architecture Recommendations

### 1. Single S3 bucket for Vite static files and media uploads?

Recommendation: use separate buckets.

Why:

- Static frontend assets and uploaded media have different cache-control needs.
- Frontend deploys often use `aws s3 sync --delete`, which is much safer when isolated from user uploads.
- Bucket lifecycle, versioning, retention, and security policies are usually different for build artifacts versus user content.
- Separate buckets make it easier to keep frontend objects immutable while allowing media overwrite or replacement flows where needed.

When a single bucket is acceptable:

- very early-stage environments
- low operational discipline risk
- strict use of separate prefixes such as `static/` and `media/`
- no `sync --delete` touching the media prefix

For this stack, the current two-bucket setup is the safer default and is the design I would keep.

### 2. Single CloudFront distribution for both `media.<domain>` and `/api/*`?

Recommendation: keep one distribution for the app frontend plus `/api/*`, and keep a separate distribution for `media.<domain>`.

Why the current split is good:

- The frontend and API share the same primary site hostname, so routing `/api/*` through the main distribution is operationally reasonable.
- Media behaves differently from API traffic: it wants long-lived caching, a separate hostname, and fewer accidental cookie/header interactions.
- A dedicated `media.<domain>` distribution keeps cache behavior, response headers, and future signed-URL or hotlink-control changes isolated from the app and API path routing.

When a single distribution for everything can work:

- if media is served from a path like `/media/*` instead of `media.<domain>`
- if you are optimizing for the absolute minimum resource count
- if you are comfortable coupling cache and hostname strategy more tightly

That said, a separate media distribution is usually the cleaner production choice, and the extra CloudFront distribution itself does not create a meaningful fixed monthly charge.

### 3. Why is the CloudFront Function necessary, and can you avoid the cost?

Why it exists:

- The frontend is a Vite SPA hosted from S3.
- Deep links like `/listings/123` do not exist as physical objects in the bucket.
- The function rewrites those requests to `/index.html` so client-side routing can boot correctly.

Without it:

- direct navigation and refresh on SPA routes would return `403` or `404` from the S3 origin unless another fallback mechanism is configured

Lower-cost alternatives:

- Best AWS-native alternative: use CloudFront custom error responses to map `403/404` from the S3 origin to `/index.html`. That removes the function cost, but it is less precise and can mask genuine missing-asset errors.
- Best long-term alternative: generate a fully static site where each route has a real output file. That eliminates the rewrite need, but only if the app architecture supports it.
- Not recommended here: use S3 website hosting fallback, because this stack intentionally keeps the bucket private behind CloudFront OAC.

Cost perspective:

- CloudFront Functions here are very cheap. The current estimate is `$0.08` in dev, `$0.30` in production launch, and `$1.00` in production growth.
- If you want to eliminate that line item, custom error responses are the most practical substitute.

## Key Assumptions

- Primary cloud: AWS
- Region: `eu-west-1`
- CloudFront certificate region: `us-east-1`
- ECS runtime: AWS Fargate on ARM/Graviton
- The current dev environment is treated as always-on because the Terraform stack does not define scheduled stop/start behavior
- CloudFront uses `PriceClass_100`, so viewer pricing is estimated with the Europe tier as a close planning proxy
- Route 53 uses one public hosted zone for `rentdirect.homes`
- SSM usage stays in the standard tier
- ACM public certificates remain free
- The production baseline uses the current `prod.tfvars` size: 1 API task at `0.5 vCPU / 1 GB`, `db.t4g.small`, and `cache.t4g.micro`
- The growth scenario keeps the current data-tier family and scales the stateless layer first
- The `.homes` domain planning cost uses a recurring placeholder based on GoDaddy list pricing rather than a one-time first-year promotional rate
- The mailbox planning cost uses one paid GoDaddy mailbox and assumes `noreply@rentdirect.homes` can be handled as an alias rather than a second paid seat
- Paystack is budgeted as a planning option because it was explicitly requested, even though the current codebase is wired for OPay/mock flows instead
- NIN verification pricing uses the user-provided rate of `N150` per API call, converted at `N1380 = $1`

## Unit Prices Used

Notes:

- AWS pricing uses the same planning method as the existing PrepVilla estimate so both project documents stay comparable.
- The `db.t4g.small` RDS rate is estimated at approximately double `db.t4g.micro` for planning. Reconfirm in AWS Pricing Calculator before procurement.
- GoDaddy and Paystack prices change by market, promotion, and renewal term. Treat them as current planning references, not locked contract pricing.

| Component | Unit price used | Notes |
| --- | ---: | --- |
| AWS Fargate ARM vCPU | $0.03238 per vCPU-hour | `eu-west-1` |
| AWS Fargate ARM memory | $0.00356 per GB-hour | `eu-west-1` |
| ALB hourly | $0.0252 per hour | `eu-west-1` |
| ALB LCU | $0.008 per LCU-hour | published AWS ELB rate |
| Public IPv4 | $0.005 per IP-hour | all commercial AWS Regions |
| RDS PostgreSQL `db.t4g.micro` Single-AZ | $0.017 per hour | `eu-west-1` |
| RDS PostgreSQL `db.t4g.small` Single-AZ | $0.034 per hour | planning estimate for `eu-west-1` |
| RDS gp3 storage Single-AZ | $0.127 per GB-month | `eu-west-1` |
| ElastiCache Redis `cache.t4g.micro` | $0.0136 per node-hour | `eu-west-1` |
| S3 Standard storage | $0.023 per GB-month | first 50 TB |
| CloudFront data transfer out | $0.085 per GB for first 10 TB | Europe pricing proxy for `PriceClass_100` |
| CloudFront HTTPS requests | $0.012 per 10,000 requests | Europe pricing assumption |
| CloudFront Functions | $0.10 per 1M invocations | frontend distribution |
| Route 53 hosted zone | $0.50 per hosted zone-month | first 25 hosted zones |
| ECR private registry storage | $0.10 per GB-month | small image footprint assumption |
| CloudWatch logs | approx. $0.50 per GB ingested | light retention, no Container Insights |
| GoDaddy `.homes` domain | $21.99 per year | planning placeholder for recurring cost |
| GoDaddy email mailbox | $9.99 per mailbox-month | recurring planning rate |
| Paystack local transaction fee | 1.5% + N100, capped at N2000 | official Nigeria pricing |
| NIN verification | N150 per API call | user-supplied assumption |
| NIN verification USD equivalent | about $0.11 per call | `150 / 1380 = 0.1087` |

## Monthly Estimate By Component

### Shared Fixed Costs

| Shared component | Monthly estimate | Notes |
| --- | ---: | --- |
| GoDaddy domain registration | $1.83 | `rentdirect.homes`, based on a $21.99/year planning placeholder |
| Route 53 hosted zone | $0.50 | one public zone for `rentdirect.homes` |
| GoDaddy email mailbox | $9.99 | one mailbox for `info@rentdirect.homes` |
| ACM public certificates | $0.00 | frontend, media, and ALB certificates |

Shared fixed monthly subtotal: **$12.32**

### Development / Current `dev.tfvars`

Assumptions:

- 1 API task at `0.25 vCPU / 0.5 GB`
- 1 ALB with about `0.5` average LCU
- 3 public IPv4 addresses total: 1 ECS task + 2 ALB nodes
- RDS PostgreSQL `db.t4g.micro` Single-AZ
- 20 GB database storage
- 1 x `cache.t4g.micro`
- small frontend bucket footprint and light media uploads
- about 75 GB combined CloudFront egress across frontend and media
- about 1.5 million total HTTPS CloudFront requests
- about 0.8 million CloudFront Function invocations on the frontend distribution

| Component | Monthly estimate |
| --- | ---: |
| ECS Fargate API | $7.21 |
| Public IPv4 addresses | $10.95 |
| Application Load Balancer | $21.32 |
| RDS PostgreSQL instance | $12.41 |
| RDS storage | $2.54 |
| ElastiCache Redis | $9.93 |
| S3 frontend + media buckets and requests | $0.60 |
| CloudFront CDN | $8.18 |
| CloudFront Functions | $0.08 |
| ECR | $0.10 |
| SSM Parameter Store | $0.00 |
| CloudWatch | $1.50 |

Development runtime subtotal: **$74.81**

Development total including shared fixed costs: **$87.13**

### Production Launch Baseline / Current `prod.tfvars`

Assumptions:

- 1 API task at `0.5 vCPU / 1 GB`
- 1 ALB with about `0.75` average LCU
- 3 public IPv4 addresses total: 1 ECS task + 2 ALB nodes
- RDS PostgreSQL `db.t4g.small` Single-AZ
- 20 GB database storage
- 1 x `cache.t4g.micro`
- 20 GB frontend bucket storage
- 150 GB media bucket storage including listing photos, profile photos, verification documents, and homepage video delivery
- about 450 GB combined CloudFront egress across frontend and media
- about 8 million total HTTPS CloudFront requests
- about 3 million CloudFront Function invocations on the frontend distribution

| Component | Monthly estimate |
| --- | ---: |
| ECS Fargate API | $14.42 |
| Public IPv4 addresses | $10.95 |
| Application Load Balancer | $22.78 |
| RDS PostgreSQL instance | $24.82 |
| RDS storage | $2.54 |
| ElastiCache Redis | $9.93 |
| S3 frontend + media buckets and requests | $3.50 |
| CloudFront CDN | $47.85 |
| CloudFront Functions | $0.30 |
| ECR | $0.20 |
| SSM Parameter Store | $0.00 |
| CloudWatch | $4.00 |

Production launch runtime subtotal: **$141.28**

Production launch total including shared fixed costs: **$153.60**

### Production Growth Baseline

Assumptions:

- 4 API tasks at `0.5 vCPU / 1 GB` to match the current autoscaling ceiling
- 1 ALB with about `1.5` average LCUs
- 6 public IPv4 addresses total: 4 ECS tasks + 2 ALB nodes
- RDS PostgreSQL `db.t4g.small` Single-AZ
- 100 GB database storage
- 2 x `cache.t4g.micro` for primary + replica
- 40 GB frontend bucket storage
- 500 GB media bucket storage
- about 2 TB combined CloudFront egress across frontend and media
- about 28 million total HTTPS CloudFront requests
- about 10 million CloudFront Function invocations on the frontend distribution

| Component | Monthly estimate |
| --- | ---: |
| ECS Fargate API | $57.67 |
| Public IPv4 addresses | $21.90 |
| Application Load Balancer | $27.16 |
| RDS PostgreSQL instance | $24.82 |
| RDS storage | $12.70 |
| ElastiCache Redis | $19.86 |
| S3 frontend + media buckets and requests | $12.00 |
| CloudFront CDN | $203.60 |
| CloudFront Functions | $1.00 |
| ECR | $0.30 |
| SSM Parameter Store | $0.00 |
| CloudWatch | $9.00 |

Production growth runtime subtotal: **$390.00**

Production growth total including shared fixed costs: **$402.32**

## Third-Party Service Budget

### Notes Before Budgeting

- The current codebase is not using a live Paystack integration today. Payment models default to `provider="opay"` and featured checkout is currently mocked in `apps/api/core/views.py`.
- The Paystack row below is therefore a planning budget line, not a confirmed present-day runtime charge.
- NIN verification is also budgeted as a planning line because the current code validates NIN format locally but does not yet call an external verification provider.
- No paid maps API, SMS provider, video SDK, or external chat service was found in the reviewed codebase, so no separate line item is included for those.

### Monthly Variable-Service Assumptions

| Service | Development | Production (Current) | Production (Growth) | Notes |
| --- | ---: | ---: | ---: | --- |
| GoDaddy domain registration | $1.83 | $1.83 | $1.83 | shared fixed cost |
| GoDaddy email mailbox | $9.99 | $9.99 | $9.99 | one paid mailbox |
| Paystack gateway fees | $0.00 | $115.94 | $507.25 | assumes dev uses sandbox only; production assumes large-ticket local transactions where the N2000 cap applies |
| NIN verification API | $5.43 | $32.61 | $163.04 | assumes 50 / 300 / 1,500 verification calls per month |

### Paystack Scenario Behind The Estimate

Because RentDirect booking payments are likely high-value rent transactions, the practical Paystack charge will often hit the local transaction cap of `N2000` per successful payment. This estimate therefore uses a capped-fee planning model:

- development: `0` live transactions, because sandbox or mocked flows should be used
- production current: `80` successful local transactions per month
- production growth: `350` successful local transactions per month

At the provided FX rate, the capped fee is about **$1.45 per successful transaction**.

### NIN Verification Scenario Behind The Estimate

The NIN planning estimate uses:

- development: `50` verification calls per month
- production current: `300` verification calls per month
- production growth: `1,500` verification calls per month

At `N150` per call and `N1380 = $1`, each call is about **$0.11**.

## Cross-Environment Summary Table

| Service | Dev | Prod (Startup) | Prod (Growth) |
| --- | ---: | ---: | ---: |
| ECS Fargate API | $7.21 | $14.42 | $57.67 |
| Public IPv4 addresses | $10.95 | $10.95 | $21.90 |
| Application Load Balancer | $21.32 | $22.78 | $27.16 |
| RDS PostgreSQL instance | $12.41 | $24.82 | $24.82 |
| RDS storage | $2.54 | $2.54 | $12.70 |
| ElastiCache Redis | $9.93 | $9.93 | $19.86 |
| S3 frontend + media buckets and requests | $0.60 | $3.50 | $12.00 |
| CloudFront CDN | $8.18 | $47.85 | $203.60 |
| CloudFront Functions | $0.08 | $0.30 | $1.00 |
| ECR | $0.10 | $0.20 | $0.30 |
| SSM Parameter Store | $0.00 | $0.00 | $0.00 |
| CloudWatch | $1.50 | $4.00 | $9.00 |
| AWS runtime subtotal | **$74.81** | **$141.28** | **$390.00** |
| GoDaddy domain registration | $1.83 | $1.83 | $1.83 |
| Route 53 hosted zone | $0.50 | $0.50 | $0.50 |
| GoDaddy email mailbox | $9.99 | $9.99 | $9.99 |
| Paystack gateway fees | $0.00 | $115.94 | $507.25 |
| NIN verification API | $5.43 | $32.61 | $163.04 |
| Total per month | **$92.56** | **$302.15** | **$1,072.61** |

## Costs Excluded Or Treated Separately

- Taxes, VAT, and card chargeback costs
- Registrar add-ons such as premium DNS or domain protection
- Additional mailboxes beyond the single mailbox assumption
- Reserved capacity, Savings Plans, or enterprise discounts
- WAF, because no WAF resources are provisioned in the current Terraform
- Terraform backend S3 and DynamoDB lock-table costs, because they are shared platform prerequisites rather than application runtime resources
- Any future paid identity, anti-fraud, or KYC providers beyond the explicit NIN assumption used here

## Best Cost Optimizations Without Hurting Performance

### 1. Schedule Development Off-Hours

The dev stack is always-on today. ECS, ALB, Redis, RDS, and public IPv4 time dominate the dev bill. Turning dev off outside working hours would materially reduce monthly spend.

### 2. Keep Media Behind CloudFront

RentDirect serves listing photos, profile images, documents, and a homepage video. Keeping media behind CloudFront should reduce direct S3 egress and make delivery more predictable.

### 3. Revisit Public IPv4 Versus NAT Only If The Service Count Grows

The stack currently avoids NAT gateways, which is usually cheaper at small scale even with public IPv4 charges. Revisit the networking tradeoff only if task count or security requirements change materially.

### 4. Confirm Whether GoDaddy Mailbox Seats Can Be Minimized

If `noreply@rentdirect.homes` can remain an alias on the `info@rentdirect.homes` mailbox, you avoid paying for an extra seat.

### 5. Keep Paystack As A Formula, Not A Fixed Budget

For RentDirect, payment fees will scale with successful transaction count. Operationally, it is better to model Paystack as:

`successful live transactions x min(1.5% + N100, N2000)`

That keeps the finance model honest as booking volume changes.

### 6. Implement Real NIN Verification Only When The Funnel Justifies It

The current application validates NIN format locally. Delaying paid external verification until onboarding volume is real can keep early-stage spend down.

## Pricing Sources

- AWS Fargate pricing: <https://aws.amazon.com/fargate/pricing/>
- Elastic Load Balancing pricing: <https://aws.amazon.com/elasticloadbalancing/pricing/>
- Amazon VPC public IPv4 pricing: <https://aws.amazon.com/vpc/pricing/>
- Amazon RDS for PostgreSQL pricing: <https://aws.amazon.com/rds/postgresql/pricing/>
- Amazon ElastiCache pricing: <https://aws.amazon.com/elasticache/pricing/>
- Amazon CloudFront pricing: <https://aws.amazon.com/cloudfront/pricing/>
- Amazon S3 pricing: <https://aws.amazon.com/s3/pricing/>
- Amazon Route 53 pricing: <https://aws.amazon.com/route53/pricing/>
- Amazon ECR pricing: <https://aws.amazon.com/ecr/pricing/>
- Amazon CloudWatch pricing: <https://aws.amazon.com/cloudwatch/pricing/>
- AWS Systems Manager pricing: <https://aws.amazon.com/systems-manager/pricing/>
- AWS Certificate Manager pricing: <https://aws.amazon.com/certificate-manager/pricing/>
- GoDaddy `.homes` domain page: <https://www.godaddy.com/en/tlds/homes-domain>
- GoDaddy email pricing: <https://www.godaddy.com/email>
- Paystack pricing: <https://paystack.com/pricing>
