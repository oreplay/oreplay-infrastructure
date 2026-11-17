# The storage account holding the Terraform states and the exported Activity Log. Applied by hand
# only, because every other stack depends on it.
## az login --tenant 3326c0e7-e6aa-4e04-bbdf-0b325951674c
# terraform plan -out main.tfplan
# terraform apply main.tfplan

data "azurerm_client_config" "current" {}

locals {
    location = "spaincentral"
    # Storage account names are global; the subscription id keeps this one unique.
    storage_account_name = "oreplaytfstate${substr(data.azurerm_client_config.current.subscription_id, 0, 8)}"
}

resource "azurerm_resource_group" "tfstate" {
    name     = "oreplay-tfstate"
    location = local.location

    lifecycle {
        prevent_destroy = true
    }
}

# Guards against deleting the group from the portal or CLI, which prevent_destroy cannot see.
resource "azurerm_management_lock" "tfstate" {
    name       = "do-not-delete-terraform-state"
    scope      = azurerm_resource_group.tfstate.id
    lock_level = "CanNotDelete"
    notes      = "Holds the Terraform state of every oreplay stack."
}

resource "azurerm_storage_account" "tfstate" {
    name                     = local.storage_account_name
    resource_group_name      = azurerm_resource_group.tfstate.name
    location                 = azurerm_resource_group.tfstate.location
    account_kind             = "StorageV2"
    account_tier             = "Standard"
    account_replication_type = "LRS"

    https_traffic_only_enabled      = true
    min_tls_version                 = "TLS1_2"
    allow_nested_items_to_be_public = false
    shared_access_key_enabled       = false
    default_to_oauth_authentication = true
    local_user_enabled              = false

    blob_properties {
        versioning_enabled = true

        delete_retention_policy {
            days = 30
        }

        container_delete_retention_policy {
            days = 30
        }
    }

    lifecycle {
        prevent_destroy = true
    }
}

resource "azurerm_storage_container" "tfstate" {
    name                  = "tfstate"
    storage_account_id    = azurerm_storage_account.tfstate.id
    container_access_type = "private"
}

# Role assignments on the subscription do not reach blob data, so even an Owner needs this one.
resource "azurerm_role_assignment" "tfstate_admin" {
    scope                = azurerm_storage_container.tfstate.id
    role_definition_name = "Storage Blob Data Contributor"
    principal_id         = data.azurerm_client_config.current.object_id
}

# Azure keeps the Activity Log for 90 days only; this copy lets us still answer who changed what
# after that. Azure Monitor writes it to the insights-activity-logs container itself.
resource "azurerm_monitor_diagnostic_setting" "activity_log" {
    name               = "activity-log-to-storage"
    target_resource_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
    storage_account_id = azurerm_storage_account.tfstate.id

    enabled_log {
        category = "Administrative"
    }

    enabled_log {
        category = "Security"
    }

    enabled_log {
        category = "Policy"
    }
}

resource "azurerm_storage_management_policy" "tfstate" {
    storage_account_id = azurerm_storage_account.tfstate.id

    rule {
        name    = "expire-old-state-versions"
        enabled = true

        filters {
            blob_types   = ["blockBlob"]
            prefix_match = ["${azurerm_storage_container.tfstate.name}/"]
        }

        actions {
            version {
                delete_after_days_since_creation = 90
            }
        }
    }

    rule {
        name    = "expire-activity-log"
        enabled = true

        filters {
            blob_types   = ["appendBlob"]
            prefix_match = ["insights-activity-logs/"]
        }

        actions {
            base_blob {
                delete_after_days_since_modification_greater_than = 365
            }
        }
    }
}
