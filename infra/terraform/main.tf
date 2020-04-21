# NOTE: The second `=` in the string is intentional, and it means
# use exact version to avoid upgrade mistakenly.
provider "azurerm" {
  version         = "=1.44.0"
  subscription_id = var.subscription_id
  #client_id       = var.client_id
  #client_secret   = var.client_secret
  #tenant_id       = var.tenant_id
}

terraform {
  required_version = "= 0.12.23"

  backend "azurerm" {
    resource_group_name  = "azure-spa-tf-state-we-rg"
    storage_account_name = "azurespatfstatewestor"
    container_name       = "terraform"
    key                  = "azurespa.demo.tfstate"
  }
}

resource "azurerm_resource_group" "target" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

### STORAGE for SPA ###
resource "azurerm_storage_account" "frontend" {
  name                     = substr("spademofewestor", 0, 24)
  resource_group_name      = azurerm_resource_group.target.name
  location                 = azurerm_resource_group.target.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  tags                     = var.tags
}

resource "azurerm_storage_container" "blobcontainer" {
  name                  = "spa"
  storage_account_name  = azurerm_storage_account.frontend.name
  container_access_type = "blob"
}

### CDN ###
resource "azurerm_cdn_profile" "cdn" {
  name                = "spa-demo-fe-we-cdn"
  location            = azurerm_resource_group.target.location
  resource_group_name = azurerm_resource_group.target.name
  sku                 = "Standard_Microsoft"
  tags                = var.tags
}

resource "azurerm_cdn_endpoint" "spa" {
  name                = "spa-demo-fe-we-cdn-ep"
  profile_name        = azurerm_cdn_profile.cdn.name
  location            = azurerm_cdn_profile.cdn.location
  resource_group_name = azurerm_cdn_profile.cdn.resource_group_name
  tags                = var.tags
  origin_host_header  = azurerm_storage_account.frontend.primary_blob_host
  origin_path         = "/spa"

  origin {
    name       = "FrontendCdnOrigin"
    host_name  = azurerm_storage_account.frontend.primary_blob_host
    http_port  = 80
    https_port = 443
  }
}

### CDN CUSTOM DOMAIN ###

resource "azurerm_dns_cname_record" "target" {
  name                = "playground"
  zone_name           = var.dns_zone_name
  resource_group_name = var.common_resource_group_name
  ttl                 = 300
  tags                = var.tags
  record              = "${azurerm_cdn_endpoint.spa.name}.azureedge.net"
}

resource "null_resource" "cdndomain" {
  triggers = {
    version = "0.0.1"
  }

  provisioner "local-exec" {
    command     = "./bin/domain.sh ${azurerm_cdn_endpoint.spa.name} ${azurerm_cdn_profile.cdn.name} ${azurerm_resource_group.target.name} ${azurerm_dns_cname_record.target.name} ${azurerm_dns_cname_record.target.name}.${var.dns_zone_name}"
    interpreter = ["/bin/bash", "-c"]
  }

  depends_on = [
    azurerm_cdn_endpoint.spa,
    azurerm_dns_cname_record.target
  ]
}

### BACKEND APP ###

resource "azurerm_app_service_plan" "appserviceplan" {
  name                = "spa-demo-be-we-asp"
  location            = azurerm_resource_group.target.location
  resource_group_name = azurerm_resource_group.target.name
  tags                = var.tags
  kind                = "Linux"
  reserved            = "true" # Mandatory for Linux plans

  sku {
    tier = "Basic"
    size = "B1"
  }
}

resource "azurerm_app_service" "backend" {
  name                = "spa-demo-be-we-app"
  location            = azurerm_resource_group.target.location
  resource_group_name = azurerm_resource_group.target.name
  tags                = var.tags
  app_service_plan_id = azurerm_app_service_plan.appserviceplan.id
  https_only          = true

  identity {
    type = "SystemAssigned"
  }

  # Configure Docker Image to load on start
  site_config {
    linux_fx_version = "DOCKER|masahigo/spa-demo-backend:latest"
    always_on        = true
    cors {
      allowed_origins = ["https://${azurerm_dns_cname_record.target.name}.${var.dns_zone_name}"]
    }
  }

  # https://github.com/microsoft/cobalt/issues/170
  app_settings = {
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = false # Do not attach Storage by default
    WEBSITES_PORT                       = 9000
    LINKEDIN_REDIRECT_URI               = "https://${azurerm_dns_cname_record.target.name}.${var.dns_zone_name}"
    LINKEDIN_CLIENT_ID                  = "771fivvrhz594x"
    LINKEDIN_CLIENT_SECRET              = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault.secrets.vault_uri}secrets/${azurerm_key_vault_secret.linkedinsecret.name}/${azurerm_key_vault_secret.linkedinsecret.version})"
  }
}

resource "azurerm_dns_cname_record" "backendcname" {
  name                = "linkedin-demo-backend"
  zone_name           = var.dns_zone_name
  resource_group_name = var.common_resource_group_name
  ttl                 = 300
  tags                = var.tags
  record              = "${azurerm_app_service.backend.name}.azurewebsites.net"
}

# App Service Managed Certs not yet supported in tf - https://github.com/terraform-providers/terraform-provider-azurerm/issues/4824
resource "null_resource" "appservicemanagedcert" {
  triggers = {
    version = "0.0.1"
  }

  provisioner "local-exec" {
    command     = "./bin/managedcert.sh ${azurerm_resource_group.target.name} ${azurerm_app_service.backend.name} ${azurerm_dns_cname_record.backendcname.name}.${var.dns_zone_name}"
    interpreter = ["/bin/bash", "-c"]
  }

  depends_on = [
    azurerm_app_service.backend,
    azurerm_dns_cname_record.backendcname
  ]
}

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "secrets" {
  name                        = "spa-demo-we-kv"
  location                    = azurerm_resource_group.target.location
  resource_group_name         = azurerm_resource_group.target.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"

  #  Cannot utilize kv network restrictions when using references - https://docs.microsoft.com/fi-fi/azure/app-service/app-service-key-vault-references#granting-your-app-access-to-key-vault
  #network_acls {
  #  default_action = "Deny"
  #  bypass         = "AzureServices"
  #}

  tags = var.tags
}

resource "azurerm_key_vault_access_policy" "ci" {
  key_vault_id = azurerm_key_vault.secrets.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions = [
    "get",
    "set",
    "delete",
  ]
}

resource "azurerm_key_vault_access_policy" "appservicemsi" {
  key_vault_id = azurerm_key_vault.secrets.id
  tenant_id    = azurerm_app_service.backend.identity.0.tenant_id
  object_id    = azurerm_app_service.backend.identity.0.principal_id

  secret_permissions = [
    "get",
  ]
}

resource "azurerm_key_vault_secret" "linkedinsecret" {
  name         = "linkedin-client-secret"
  value        = var.linkedin_client_secret
  key_vault_id = azurerm_key_vault.secrets.id
  tags         = var.tags

  depends_on = [azurerm_key_vault_access_policy.ci]
}
