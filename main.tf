# Configure providers
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.22.0"
    }

    azapi = {
      source  = "Azure/azapi"
      version = "~> 0.5.0"
    }
  }
}

#terraform {
#  backend "azurerm"{
#      resource_group_name  = "walure-group"
#      storage_account_name = "walureerp"
#      container_name       = "walureerp"
#  }
#}

provider "azurerm" {
  features {}
}

# Define resource group
resource "azurerm_resource_group" "rg" {
  name     = "erpcontainer"
  location = "northeurope"
}

# Create Log Analytics workspace
resource "azurerm_log_analytics_workspace" "law" {
  name                = "law-aca-terraform"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "PerGB2018"
  retention_in_days   = 90
}

# Create ACA environment
resource "azapi_resource" "aca_env" {
  type      = "Microsoft.App/managedEnvironments@2022-03-01"
  parent_id = azurerm_resource_group.rg.id
  location  = azurerm_resource_group.rg.location
  name      = "aca-env-terraform"

  body = jsonencode({
    properties = {
      appLogsConfiguration = {
        destination = "log-analytics"
        logAnalyticsConfiguration = {
          customerId = azurerm_log_analytics_workspace.law.workspace_id
          sharedKey  = azurerm_log_analytics_workspace.law.primary_shared_key
        }
      }
    }
  })
}

# Create the ACA with embedded secrets
resource "azapi_resource" "aca" {
  type      = "Microsoft.App/containerApps@2022-03-01"
  parent_id = azurerm_resource_group.rg.id
  location  = azurerm_resource_group.rg.location
  name      = "erpapp-account"

  body = jsonencode({
    properties: {
      managedEnvironmentId = azapi_resource.aca_env.id
      configuration = {
        ingress = {
          external   = true
          targetPort = 80
        }
        registries = [{
          server   = "erpapp.azurecr.io"
          username = "erpapp"
          passwordSecretRef = "acr-password"
        }]
        secrets = [
          {
            name  = "acr-password"
            value = "paste password here"
          }
        ]
      }
      template = {
        containers = [
          {
            name  = "web"
            image = "erpapp.azurecr.io/erpaccount:latest"
            resources = {
              cpu    = 0.5
              memory = "1.0Gi"
            }
          }
        ]
        scale = {
          minReplicas = 2
          maxReplicas = 20
        }
      }
    }
  })
}

resource "azapi_resource" "aca2" {
  type      = "Microsoft.App/containerApps@2022-03-01"
  parent_id = azurerm_resource_group.rg.id
  location  = azurerm_resource_group.rg.location
  name      = "erpapp-auth"

  body = jsonencode({
    properties: {
      managedEnvironmentId = azapi_resource.aca_env.id
      configuration = {
        ingress = {
          external   = true
          targetPort = 80
        }
        registries = [{
          server   = "erpapp.azurecr.io"
          username = "erpapp"
          passwordSecretRef = "acr-password"
        }]
        secrets = [
          {
            name  = "acr-password"
            value = "paste password"
          }
        ]
      }
      template = {
        containers = [
          {
            name  = "web"
            image = "erpapp.azurecr.io/erpauth:latest"
            resources = {
              cpu    = 0.5
              memory = "1.0Gi"
            }
          }
        ]
        scale = {
          minReplicas = 2
          maxReplicas = 20
        }
      }
    }
  })
}

resource "azapi_resource" "aca3" {
  type      = "Microsoft.App/containerApps@2022-03-01"
  parent_id = azurerm_resource_group.rg.id
  location  = azurerm_resource_group.rg.location
  name      = "erpapp-hr"

  body = jsonencode({
    properties: {
      managedEnvironmentId = azapi_resource.aca_env.id
      configuration = {
        ingress = {
          external   = true
          targetPort = 80
        }
        registries = [{
          server   = "erpapp.azurecr.io"
          username = "erpapp"
          passwordSecretRef = "acr-password"
        }]
        secrets = [
          {
            name  = "acr-password"
            value = "paste password"
          }
        ]
      }
      template = {
        containers = [
          {
            name  = "web"
            image = "erpapp.azurecr.io/erphr:latest"
            resources = {
              cpu    = 0.5
              memory = "1.0Gi"
            }
          }
        ]
        scale = {
          minReplicas = 2
          maxReplicas = 20
        }
      }
    }
  })
}
