# NOTE: The second `=` in the string is intentional, and it means
# use exact version to avoid upgrade mistakenly.
provider "azurerm" {
  version         = "=1.44.0"
  subscription_id = var.subscription_id
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

#resource "azurerm_app_service_custom_hostname_binding" "backendbinding" {
#  hostname            = "linkedin-demo-backend.dev.msdevopsdude.com"
#  app_service_name    = azurerm_app_service.backend.name
#  resource_group_name = azurerm_resource_group.target.name

#  depends_on = [
#     null_resource.appservicemanagedcert
#  ]
#}
