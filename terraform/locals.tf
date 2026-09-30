locals {
  name_prefix        = "${var.project_name}-${var.environment}"
  project_name       = "rentdirect"
  applied_prod       = local.is_prod ? "true" : "false"
  is_prod            = var.environment == "prod"
  waf_enabled        = local.is_prod && var.enable_waf
  migrate_on_startup = local.applied_prod
  seed_demo_accounts = local.applied_prod


  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  })

  availability_zones = slice(data.aws_availability_zones.available.names, 0, 2)
  route53_zone_id    = data.aws_route53_zone.main.zone_id # aws_route53_zone.main.zone_id # data.aws_route53_zone.main.zone_id

  frontend_origin  = "https://${var.domain_name}"
  api_origin       = trimspace(var.api_domain_name) != "" ? "https://${var.api_domain_name}" : local.frontend_origin
  websocket_origin = trimspace(var.api_domain_name) != "" ? "wss://${var.api_domain_name}" : "wss://${var.domain_name}"

  api_allowed_hosts = join(
    ",",
    distinct(compact(concat(var.django_allowed_hosts, [var.domain_name, trimspace(var.api_domain_name) != "" ? var.api_domain_name : ""])))
  )

  api_image_uri = "${module.storage.api_repository_url}:${var.environment}"

  api_string_environment = {
    # Flutterwaves
    FLUTTERWAVE_API_VERSION                           = var.flutterwave.api_version
    FLUTTERWAVE_API_BASE_URL                          = var.flutterwave.api_version == "3" ? var.flutterwave.api_url_v3 : var.flutterwave.api_url_v3
    FLUTTERWAVE_TOKEN_URL                             = "https://idp.flutterwave.com/realms/flutterwave/protocol/openid-connect/token"
    FLUTTERWAVE_WEBHOOK_URL                           = "${local.api_origin}/api/v1/payments/webhook/flutterwave"
    FLUTTERWAVE_PAYOUT_BALANCE_DELAY_MINUTES          = 1440 # Minutes
    FLUTTERWAVE_PAYOUT_RELEASE_WATCH_INTERVAL_SECONDS = "300"

    # AI Chat Assistant 'Sally' configurations
    AI_CHAT_BASE_URL        = "https://openrouter.ai/api/v1"
    AI_CHAT_MODEL           = "nvidia/nemotron-3.5-lightning:free"
    AI_CHAT_FALLBACK_MODELS = "nvidia/nemotron-3-ultra-550b-a55b:free,thinkingmachines/inkling:free,thinkingmachines/inkling-small:free,stealth/space-bunny-alpha"
    AI_CHAT_TIMEOUT_SECONDS = 45
    AI_CHAT_MAX_TOOL_ROUNDS = 4
    AI_CHAT_SEARCH_LIMIT    = 12

    DJANGO_SETTINGS_MODULE                    = local.is_prod ? "config.settings.production" : "config.settings.development"
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
    ENFORCE_PRODUCTION_HARDENING              = local.applied_prod
    ENFORCE_FLUTTERWAVE_WEBHOOK_SIGNATURE     = local.applied_prod
    AWS_STORAGE_BUCKET_NAME                   = module.storage.media_bucket_name
    AWS_S3_REGION_NAME                        = var.region
    AWS_S3_CUSTOM_DOMAIN                      = module.networking.media_domain_name
    STATIC_ROOT                               = "/app/staticfiles"
    MEDIA_ROOT                                = "/app/uploads"
    SECURE_SSL_REDIRECT                       = "true"
    SESSION_COOKIE_SECURE                     = "true"
    CSRF_COOKIE_SECURE                        = "true"
    SECURE_HSTS_SECONDS                       = local.is_prod ? "31536000" : "3600"
    SECURE_HSTS_INCLUDE_SUBDOMAINS            = local.applied_prod
    SECURE_HSTS_PRELOAD                       = local.applied_prod
    COOKIE_DOMAIN                             = ".${var.domain_name}"
    SEED_DEMO_ACCOUNTS_WATCH                  = var.environment == "dev" ? "1" : "0"
    SEED_DEMO_ACCOUNTS_WATCH_INTERVAL_SECONDS = "2"

    # Email settings
    DEFAULT_FROM_EMAIL                        = "noreply@rentdirect.homes"
    EMAIL_BACKEND                             = "django.core.mail.backends.smtp.EmailBackend"
    EMAIL_HOST                                = "smtpout.secureserver.net"
    EMAIL_PORT                                = "587"
    EMAIL_HOST_USER                           = "info@rentdirect.homes"
    EMAIL_USE_TLS                             = "true"
    EMAIL_USE_SSL                             = "false"
    EMAIL_TIMEOUT                             = "60"
    SERVER_EMAIL                              = "info@rentdirect.homes"

    # Verification
    VERIFICATION_SERVICE = "prembly" # or "dikript"

    # Dikript
    DIKRIPT_API_BASE_URL    = "https://api.dikript.com"
    DIKRIPT_NIN_API_URL     = "/dikript/verification/api/v1/getnin"
    DIKRIPT_BVN_API_URL     = "/dikript/verification/api/v1/getbvn"
    DIKRIPT_CAC_API_URL     = "/dikript/verification/api/v1/getcacbasic"
    DIKRIPT_TIMEOUT_SECONDS = "10"

    # Prembly
    PREMBLY_API_BASE_URL                 = "https://api.prembly.com"
    PREMBLY_NIN_API_URL                  = "/verification/vnin"
    PREMBLY_BVN_API_URL                  = "/verification/bvn"
    PREMBLY_CAC_API_URL                  = "/verification/cac"
    PREMBLY_TIMEOUT_SECONDS              = "10"
    PREMBLY_LOOKUP_CACHE_TIMEOUT_SECONDS = "86400"
    PREMBLY_WEBHOOK_TOKEN_CACHE_SECONDS  = "604800"
    PREMBLY_CAC_COMPANY_TYPE             = "RC"

    SUBSCRIPTION_RENEWAL_WATCH_INTERVAL_SECONDS = "3600"

    # VAT on paid tenant and landlord subscriptions and administration fees
    SUBSCRIPTION_VAT_RATE_PERCENT = "7.5"
  }

  api_secure_parameter_arns = {
    for key, arn in module.storage.app_secure_parameter_arns :
    key => arn
    if !contains(keys(local.api_string_environment), key)
  }

  api_secrets = merge(
    local.api_secure_parameter_arns,
    module.databases.valkey_auth_parameter_arn != null ? {
      VALKEY_AUTH_TOKEN = module.databases.valkey_auth_parameter_arn
    } : {}
  )

  secure_parameter_arns = values(local.api_secrets)
}
