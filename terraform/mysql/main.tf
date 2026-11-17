# Manages the MySQL Flexible Server
resource "azurerm_mysql_flexible_server" "default" {
    name                         = "${var.name_prefix}-mysql-flexible-server"
    resource_group_name          = var.resource_group_name
    location                     = var.resource_group_location
    administrator_login          = "or_mysql_admin"
    backup_retention_days        = 7

    # Write-only, so the password never reaches the plan or the state. It is sent to Azure only
    # when the version changes: bump it to rotate the password.
    administrator_password_wo         = var.mysql_admin_password
    administrator_password_wo_version = 1

    geo_redundant_backup_enabled = false
    sku_name                     = "B_Standard_B1ms" # GP_Standard_D2ds_v4
    version                      = "8.0.21"

    #delegated_subnet_id          = var.delegated_subnet_id # azurerm_subnet.default.id
    #private_dns_zone_id          = var.private_dns_zone_id # azurerm_private_dns_zone.default.id

    #high_availability {
    #    mode = "SameZone"
    #}
    #maintenance_window {
    #    day_of_week  = 0
    #    start_hour   = 8
    #    start_minute = 0
    #}
    storage {
        iops    = 360
        size_gb = 20
    }

    # Storage auto-grow resizes the disk as the data grows, and Azure cannot shrink it again, so
    # applying these initial values would replace the server.
    lifecycle {
        ignore_changes = [storage[0].size_gb, storage[0].iops]
    }

#    depends_on = [azurerm_private_dns_zone_virtual_network_link.default]
}

resource "azurerm_mysql_flexible_server_configuration" "require_secure_transport" {
    name                = "require_secure_transport"
    resource_group_name = var.resource_group_name
    server_name         = azurerm_mysql_flexible_server.default.name
    value               = "OFF"
}

# Allow all IPs to access MySQL server (NOT recommended for production)
resource "azurerm_mysql_flexible_server_firewall_rule" "allow_all" {
    name                = "allow-all-ips"
    resource_group_name = var.resource_group_name
    server_name         = azurerm_mysql_flexible_server.default.name
    start_ip_address    = "0.0.0.0"
    end_ip_address      = "255.255.255.255"
}

# Manages the MySQL Flexible Server Database
resource "azurerm_mysql_flexible_database" "main" {
    charset             = "utf8mb4"
    collation           = "utf8mb4_unicode_ci"
    name                = "app_rest"
    resource_group_name = var.resource_group_name
    server_name         = azurerm_mysql_flexible_server.default.name
}
