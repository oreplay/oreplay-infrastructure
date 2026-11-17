variable "name_prefix" {
    description = "For example: o-replay2024"
    type = string
}

variable "admin_password" {
    description = "MySQL admin password. The app logs in with it, so it must match DATABASE_URL in oreplay.production.env."
    type      = string
    ephemeral = true
}

variable "ssh_pub_full_path" {
    description = "Full path to the ssh pub file. E.g: ~/.ssh/id_rsa_azure_oreplay.pub"
    default = "~/.ssh/id_rsa_azure_oreplay.pub"
    type = string
}

variable "resource_group_location" {
    type        = string
    default     = "spaincentral"
    description = "Location of the resource group."
}
