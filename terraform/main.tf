## terraform destroy
# terraform init -upgrade
# terraform validate
## export BROWSER="/usr/bin/firefox"
# az login --tenant 3326c0e7-e6aa-4e04-bbdf-0b325951674c
# terraform plan -out main.tfplan
# terraform apply main.tfplan
## export TF_LOG=WARN # TRACE, DEBUG, INFO, WARN or ERROR
## sudo cloud-init status --long
## ssh vm_admin_user@www.oreplay.es
resource "azurerm_resource_group" "rg" {
    location = var.resource_group_location
    name     = "${var.name_prefix}-resource-group"

    tags = {
        "O-Replay" = "grupo de recursos"
    }
}

## Generate random value for the name
#resource "random_string" "name" {
#    length  = 8
#    lower   = true
#    numeric = false
#    special = false
#    upper   = false
#}

module "network" {
    source = "./network"
    resource_group_location = var.resource_group_location
    resource_group_name = azurerm_resource_group.rg.name
    name_prefix = var.name_prefix
}

module "vm" {
    source               = "./vm"
    resource_group_location = var.resource_group_location
    resource_group_name = azurerm_resource_group.rg.name
    network_security_group_id = module.network.network_security_group_id
    virtual_network_name = module.network.virtual_network_name
    name_prefix = var.name_prefix
    ssh_pub_full_path = var.ssh_pub_full_path
}

module "mysql" {
    source               = "./mysql"
    depends_on = [module.network.azurerm_private_dns_zone_virtual_network_link]
    mysql_admin_password = var.admin_password
    delegated_subnet_id = module.network.azurerm_subnet_id # azurerm_subnet.default.id
    private_dns_zone_id = module.network.private_dns_zone_id # azurerm_private_dns_zone.default.id
    resource_group_location = var.resource_group_location
    resource_group_name = azurerm_resource_group.rg.name
    name_prefix = var.name_prefix
}
