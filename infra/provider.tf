terraform {
  required_version = ">= 1.1.7, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.81"
    }
  }
}

provider "azurerm" {
  storage_use_azuread = true
  features {
    key_vault {
      purge_soft_delete_on_destroy = false
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    log_analytics_workspace {
      permanently_delete_on_destroy = true
    }
  }
}

data "azurerm_client_config" "current" {}
