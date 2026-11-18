# Azure keeps the Activity Log for 90 days only; this copy lets us still answer who changed what
# after that. It lives in its own account so that access to the states or the workloads grants
# nothing over the record of what was done with them.

locals {
    audit_retention_days = 365
    # The policy is locked, so this can only be raised, never lowered, and Azure allows only a few
    # raises: go straight to the final value.
    audit_immutability_days = 30
}

resource "azurerm_resource_group" "audit" {
    name     = "oreplay-audit"
    location = local.location

    lifecycle {
        prevent_destroy = true
    }
}

resource "azurerm_management_lock" "audit" {
    name       = "do-not-delete-audit-logs"
    scope      = azurerm_resource_group.audit.id
    lock_level = "CanNotDelete"
    notes      = "Holds the exported Activity Log of the subscription."
}

resource "azurerm_storage_account" "audit" {
    name                     = "oreplayaudit${substr(data.azurerm_client_config.current.subscription_id, 0, 8)}"
    resource_group_name      = azurerm_resource_group.audit.name
    location                 = azurerm_resource_group.audit.location
    account_kind             = "StorageV2"
    account_tier             = "Standard"
    account_replication_type = "LRS"

    https_traffic_only_enabled      = true
    min_tls_version                 = "TLS1_2"
    allow_nested_items_to_be_public = false
    shared_access_key_enabled       = false
    default_to_oauth_authentication = true
    local_user_enabled              = false

    # Version-level immutability needs versioning.
    blob_properties {
        versioning_enabled = true
    }

    # No one can modify or delete a log blob during the immutability period. Azure Monitor appends
    # to hourly blobs, which protected append writes still allow.
    immutability_policy {
        state                         = "Locked"
        period_since_creation_in_days = local.audit_immutability_days
        allow_protected_append_writes = true
    }

    lifecycle {
        prevent_destroy = true
    }
}

resource "azurerm_monitor_diagnostic_setting" "activity_log" {
    name               = "activity-log-to-storage"
    target_resource_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
    storage_account_id = azurerm_storage_account.audit.id

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

resource "azurerm_storage_management_policy" "audit" {
    storage_account_id = azurerm_storage_account.audit.id

    rule {
        name    = "expire-activity-log"
        enabled = true

        filters {
            blob_types   = ["appendBlob"]
            prefix_match = ["insights-activity-logs/"]
        }

        actions {
            base_blob {
                delete_after_days_since_modification_greater_than = local.audit_retention_days
            }
        }
    }
}

# The account holds nothing but logs, so reading all of it is safe.
resource "azurerm_role_assignment" "audit_reader" {
    scope                = azurerm_storage_account.audit.id
    role_definition_name = "Storage Blob Data Reader"
    principal_id         = data.azurerm_client_config.current.object_id
}
