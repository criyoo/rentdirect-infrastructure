locals {
  name_prefix        = "${var.project_name}-${var.environment}"
  project_name       = "rentdirect"
  is_prod            = var.environment == "prod"
  migrate_on_startup = local.is_prod ? "false" : "true"
  seed_demo_accounts = local.is_prod ? "false" : "true"

  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  })

  availability_zones = slice(data.aws_availability_zones.available.names, 0, 2)
  route53_zone_id    = data.aws_route53_zone.main.zone_id # aws_route53_zone.main.zone_id # data.aws_route53_zone.main.zone_id

  frontend_origin      = "https://${var.domain_name}"
  api_origin           = trimspace(var.api_domain_name) != "" ? "https://${var.api_domain_name}" : local.frontend_origin
  websocket_origin     = trimspace(var.api_domain_name) != "" ? "wss://${var.api_domain_name}" : "wss://${var.domain_name}"
  verification_service = var.environment == "dev" ? "prembly" : "prembly" #"dikript"

  api_allowed_hosts = join(
    ",",
    distinct(compact(concat(var.django_allowed_hosts, [var.domain_name, trimspace(var.api_domain_name) != "" ? var.api_domain_name : ""])))
  )

  flutterwave_api_base_url = var.environment == "dev" ? "https://f4bexperience.flutterwave.com" : "https://f4bexperience.flutterwave.com"
  # v3 sandbox & Live = https://api.flutterwave.com/v3
  # v4 sandbox = https://developersandbox-api.flutterwave.com
  # v4 Live = https://f4bexperience.flutterwave.com

  api_image_uri = "${module.storage.api_repository_url}:${var.environment}"

  api_string_environment = {
    DJANGO_SETTINGS_MODULE                    = "config.settings"
    DJANGO_ENV                                = local.is_prod ? "production" : "development"
    DJANGO_DEBUG                              = "false"
    DJANGO_ALLOWED_HOSTS                      = local.api_allowed_hosts
    FRONTEND_URL                              = local.frontend_origin
    API_PUBLIC_URL                            = local.api_origin
    WEB_PUBLIC_URL                            = local.frontend_origin
    CORS_ALLOWED_ORIGINS                      = local.frontend_origin
    CSRF_TRUSTED_ORIGINS                      = join(",", distinct([local.frontend_origin, local.api_origin]))
    POSTGRES_HOST                             = module.databases.database_endpoint
    POSTGRES_DB                               = var.database.name
    POSTGRES_USER                             = var.database.username
    POSTGRES_PORT                             = "5432"
    DATABASE_SSL_REQUIRE                      = "true"
    MIGRATE_ON_STARTUP                        = "0"
    SEED_DEMO_ACCOUNTS                        = local.seed_demo_accounts
    SEED_DEMO_ACCOUNTS_ON_STARTUP             = "0"
    VALKEY_URL                                = module.databases.valkey_url
    ENFORCE_PRODUCTION_HARDENING              = local.is_prod ? "true" : "false"
    ENFORCE_FLUTTERWAVE_WEBHOOK_SIGNATURE     = local.is_prod ? "true" : "false"
    AWS_STORAGE_BUCKET_NAME                   = module.storage.media_bucket_name
    AWS_S3_REGION_NAME                        = var.region
    AWS_S3_CUSTOM_DOMAIN                      = module.networking.media_domain_name
    STATIC_ROOT                               = "/app/staticfiles"
    MEDIA_ROOT                                = "/app/uploads"
    SECURE_SSL_REDIRECT                       = "true"
    SESSION_COOKIE_SECURE                     = "true"
    CSRF_COOKIE_SECURE                        = "true"
    SECURE_HSTS_SECONDS                       = local.is_prod ? "31536000" : "3600"
    SECURE_HSTS_INCLUDE_SUBDOMAINS            = local.is_prod ? "true" : "false"
    SECURE_HSTS_PRELOAD                       = local.is_prod ? "true" : "false"
    COOKIE_DOMAIN                             = ".${var.domain_name}"
    SEED_DEMO_ACCOUNTS_WATCH                  = var.environment == "dev" ? "1" : "0"
    SEED_DEMO_ACCOUNTS_WATCH_INTERVAL_SECONDS = "2"
    DEFAULT_FROM_EMAIL                        = "noreply@rentdirect.homes"
    EMAIL_BACKEND                             = "django.core.mail.backends.smtp.EmailBackend"
    EMAIL_HOST                                = "smtpout.secureserver.net"
    EMAIL_PORT                                = "587"
    EMAIL_HOST_USER                           = "info@rentdirect.homes"
    EMAIL_USE_TLS                             = "true"
    EMAIL_USE_SSL                             = "false"
    EMAIL_TIMEOUT                             = "60"
    SERVER_EMAIL                              = "info@rentdirect.homes"
    # Flutterwaves
    FLUTTERWAVE_PAYOUT_RELEASE_WATCH_INTERVAL_SECONDS = "900"
    FLUTTERWAVE_API_VERSION                           = "4"
    FLUTTERWAVE_API_BASE_URL                          = local.flutterwave_api_base_url
    FLUTTERWAVE_TOKEN_URL                             = "https://idp.flutterwave.com/realms/flutterwave/protocol/openid-connect/token"
    FLUTTERWAVE_WEBHOOK_URL                           = "${local.api_origin}/api/v1/payments/webhook/flutterwave"
    # Verification
    VERIFICATION_SERVICE = local.verification_service
    # Dikript
    DIKRIPT_API_BASE_URL    = "https://api.dikript.com"
    DIKRIPT_NIN_API_URL     = "/dikript/verification/api/v1/getnin"
    DIKRIPT_BVN_API_URL     = "/dikript/verification/api/v1/getbvn"
    DIKRIPT_CAC_API_URL     = "/dikript/verification/api/v1/getcacbasic"
    DIKRIPT_TIMEOUT_SECONDS = "10",
    # Prembly
    PREMBLY_API_BASE_URL                 = "https://api.prembly.com"
    PREMBLY_NIN_API_URL                  = "/verification/vnin"
    PREMBLY_BVN_API_URL                  = "/verification/bvn"
    PREMBLY_CAC_API_URL                  = "/verification/cac"
    PREMBLY_TIMEOUT_SECONDS              = "10"
    PREMBLY_LOOKUP_CACHE_TIMEOUT_SECONDS = "86400"
    PREMBLY_CAC_COMPANY_TYPE             = "RC"
    # Rentdirect
    RENTDIRECT_SUBSCRIPTION_SUBACCOUNT_ID           = "",
    RENTDIRECT_SUBSCRIPTION_BUSINESS_EMAIL          = "noreply@rentdirect.homes",
    RENTDIRECT_SUBSCRIPTION_BUSINESS_MOBILE         = "08099446062",
    RENTDIRECT_SUBSCRIPTION_SUBACCOUNT_COUNTRY      = "NG",
    RENTDIRECT_SUBSCRIPTION_SUBACCOUNT_SPLIT_TYPE   = "flat",
    RENTDIRECT_SUBSCRIPTION_SUBACCOUNT_SPLIT_VALUE  = "0",
    RENTDIRECT_SUBSCRIPTION_TRANSACTION_CHARGE_TYPE = "flat",
    RENTDIRECT_SUBSCRIPTION_TRANSACTION_CHARGE      = "0",
  }

  api_secrets = merge(
    module.storage.app_secure_parameter_arns,
    module.databases.valkey_auth_parameter_arn != null ? {
      VALKEY_AUTH_TOKEN = module.databases.valkey_auth_parameter_arn
    } : {}
  )

  secure_parameter_arns = values(local.api_secrets)
}
