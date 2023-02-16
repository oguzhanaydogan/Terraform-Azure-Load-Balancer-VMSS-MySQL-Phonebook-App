# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.43.0"
    }
  }
}

provider "azurerm" {
  features {
    
  }
}

# Create an Azure SQL Server and Database
resource "azurerm_sql_server" "phonebook_db_server" {
  name                         = "phonebook-db-server"
  resource_group_name          = "phonebook-resource-group"
  location                     = "eastus"
  version                      = "12.0"
  administrator_login          = "clouduser"
  administrator_login_password = "Password1234"
}

resource "azurerm_sql_database" "phonebook_db" {
  name                = "phonebook-db"
  resource_group_name = "phonebook-resource-group"
  server_name         = azurerm_sql_server.phonebook_db_server.name
  edition             = "Standard"
  collation           = "SQL_Latin1_General_CP1_CI_AS"
  max_size_gb         = 1
}

# Create an Azure Load Balancer
resource "azurerm_lb" "phonebook_lb" {
  name                = "phonebook-lb"
  location            = "eastus"
  resource_group_name = "phonebook-resource-group"

  frontend_ip_configuration {
    name                          = "public-ip"
    public_ip_address_id          = azurerm_public_ip.phonebook_public_ip.id
  }

  backend_address_pool {
    name                = "vm-backend-pool"
  }

  probe {
    name                      = "tcp-probe"
    protocol                  = "Tcp"
    port                      = 80
    interval_in_seconds       = 5
    number_of_probes          = 2
  }

  load_balancing_rule {
    name                       = "http-lb-rule"
    frontend_ip_configuration = azurerm_lb.phonebook_lb.frontend_ip_configuration[0].id
    backend_address_pool_id    = azurerm_lb.phonebook_lb.backend_address_pool[0].id
    protocol                   = "Tcp"
    frontend_port              = 80
    backend_port               = 80
    probe_id                   = azurerm_lb.phonebook_lb.probe[0].id
  }

  # Enable auto-scaling
  autoscale_profile {
    name = "scale-out"
    capacity {
      default = 2
      minimum = 2
      maximum = 4
    }
    rules {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Compute/virtualMachinesScaleSets/${var.vm_scale_set_name}"
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        operator           = "GreaterThan"
        threshold          = 70
      }
      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }
  }

  # Configure the backend pool for the virtual machines
  dynamic "backend_address_pool" {
    for_each = var.vm_instances
    content {
      name = "vm-${backend_address_pool.key}"
      backend_address {
        ip_address = backend_address_pool.value
      }
    }
  }
}

# Create an Azure Public IP address for the Load Balancer
resource "azurerm_public_ip" "phonebook_public_ip" {
name = "phonebook-public-ip"
location = "eastus"
resource_group_name = "phonebook-resource-group"
allocation_method = "Dynamic"
}

# Create an Azure Network Security Group for the virtual machines
resource "azurerm_network_security_group" "phonebook_nsg" {
name = "phonebook-nsg"
location = "eastus"
resource_group_name = "phonebook-resource-group"

security_rule {
name = "http-inbound-rule"
priority = 100
direction = "Inbound"
access = "Allow"
protocol = "Tcp"
source_port_range = ""
destination_port_range = "80"
source_address_prefix = ""
destination_address_prefix = "*"
}
}

# Create an Azure Virtual Machine Scale Set with two virtual machines
resource "azurerm_linux_virtual_machine_scale_set" "phonebook_vm_scale_set" {
name = "phonebook-vm-scale-set"
location = "eastus"
resource_group_name = "phonebook-resource-group"
sku = "Standard_D2_v3"
instances = 2

storage_image_reference {
publisher = "Canonical"
offer = "UbuntuServer"
sku = "16.04-LTS"
version = "latest"
}

os_disk {
name = "phonebook-vm-os-disk"
caching = "ReadWrite"
storage_account_type = "Standard_LRS"
}

network_interface {
name = "phonebook-vm-nic"
primary = true

# python
ip_configuration {
  name                          = "phonebook-vm-ipconfig"
  subnet_id                     = azurerm_subnet.phonebook_subnet.id
  load_balancer_backend_address_pool_ids = [
    azurerm_lb.phonebook_lb.backend_address_pool[0].id,
  ]
}
}

extension {
name = "customScript"
publisher = "Microsoft.Azure.Extensions"
type = "CustomScript"
type_handler_version = "2.0"
settings = jsonencode({
  commandToExecute = "/bin/bash /opt/scripts/install_phonebook.sh",
})

protected_settings = jsonencode({
  storageAccountName = "<storage-account-name>"
  storageAccountKey  = "<storage-account-key>"
})
}

admin_username = "clouduser"
admin_password = "Password1234"
}

# Create an Azure Virtual Network and Subnet
resource "azurerm_virtual_network" "phonebook_vnet" {
name = "phonebook-vnet"
address_space = ["10.0.0.0/16"]
location = "eastus"
resource_group_name = "phonebook-resource-group"

subnet {
name = "phonebook-subnet"
address_prefix = "10.0.1.0/24"
}
}