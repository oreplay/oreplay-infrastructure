terraform {
    # An older Terraform refuses to read a state written by a newer one, so everyone applies with
    # the same version.
    required_version = "~> 1.16.1"

    required_providers {
        azurerm = {
            source  = "hashicorp/azurerm"
            version = "~>4.23"
        }
    }

    # This stack creates the account its own state lives in, so it was first applied with local
    # state and then migrated here.
    backend "azurerm" {
        subscription_id      = "61f3117d-ee5e-4acc-80c0-fe234ea241d7"
        resource_group_name  = "oreplay-tfstate"
        storage_account_name = "oreplaytfstate61f3117d"
        container_name       = "tfstate"
        key                  = "bootstrap/terraform.tfstate"
        use_azuread_auth     = true
    }
}

provider "azurerm" {
    features {}
    subscription_id = "61f3117d-ee5e-4acc-80c0-fe234ea241d7"

    # The state account refuses shared keys, so containers and blobs are reached with Entra ID.
    storage_use_azuread = true
}
