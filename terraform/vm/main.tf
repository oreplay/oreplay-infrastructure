resource "azurerm_public_ip" "vm_mod" {
    name                = "${var.name_prefix}-public-ip"
    location            = var.resource_group_location
    resource_group_name = var.resource_group_name
    allocation_method   = "Static"
    sku                 = "Standard"
}

resource "azurerm_subnet" "vm_mod" {
    name                 = "${var.name_prefix}-vm-subnet"
    resource_group_name  = var.resource_group_name
    virtual_network_name = var.virtual_network_name
    address_prefixes     = ["10.0.3.0/24"]

    private_endpoint_network_policies = "Enabled"
}

resource "azurerm_network_interface" "vm_mod" {
    name                = "${var.name_prefix}-nic"
    location            = var.resource_group_location
    resource_group_name = var.resource_group_name

    ip_configuration {
        name                          = "internal"
        subnet_id                     = azurerm_subnet.vm_mod.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.vm_mod.id
    }
}

resource "azurerm_network_interface_security_group_association" "vm_mod" {
    network_interface_id      = azurerm_network_interface.vm_mod.id
    network_security_group_id = var.network_security_group_id
}

resource "azurerm_linux_virtual_machine" "vm_mod" {
    name                  = "${var.name_prefix}-virtual-machine"
    resource_group_name   = var.resource_group_name
    location              = var.resource_group_location
    size                  = "Standard_B2s" # 2 vCPU 4 GB mem
    admin_username        = "vm_admin_user"
    network_interface_ids = [azurerm_network_interface.vm_mod.id]

    disable_password_authentication = true

    admin_ssh_key {
        username   = "vm_admin_user"
        public_key = file(var.ssh_pub_full_path)
    }

    os_disk {
        name                 = "${var.name_prefix}-os-disk"
        caching              = "ReadWrite"
        storage_account_type = "Standard_LRS"
        disk_size_gb         = 30
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "ubuntu-24_04-lts" # https://az-vm-image.info/
        sku       = "server"
        version   = "latest"
    }

    # The Azure Monitor agent extension authenticates with this identity.
    identity {
        type = "SystemAssigned"
    }

    custom_data = base64encode(templatefile("${path.module}/cloud-init.yaml", {
        nginx_config = file("${path.module}/nginx.conf")
    }))

    # cloud-init runs only on the first boot, so a changed custom_data means a new VM; ignoring it
    # keeps an edit to cloud-init.yaml or nginx.conf from replacing the running one.
    lifecycle {
        ignore_changes = [custom_data]
    }
}
