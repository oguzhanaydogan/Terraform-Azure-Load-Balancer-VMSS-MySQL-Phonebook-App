# # provider
# terraform {
#   required_providers {
#     azurerm = {
#       source = "hashicorp/azurerm"
#       version = "3.43.0"
#     }
#   }
# }

# provider "azurerm" {
#   features {
    
#   }
# }

# # Define the resource group for the phonebook application
# resource "azurerm_resource_group" "phonebook_rg" {
#   name     = "phonebook-rg"
#   location = "eastus"
# }

# # Define the virtual network and subnet for the phonebook application
# resource "azurerm_virtual_network" "phonebook_vnet" {
#   name                = "phonebook-vnet"
#   address_space       = ["10.0.0.0/16"]
#   location            = "eastus"
#   resource_group_name = azurerm_resource_group.phonebook_rg.name

#   subnet {
#     name           = "phonebook-subnet"
#     address_prefix = "10.0.1.0/24"
#   }
# }

# # Define the public IP address for the phonebook application
# resource "azurerm_public_ip" "phonebook_public_ip" {
#   name                = "phonebook-public-ip"
#   location            = "eastus"
#   resource_group_name = azurerm_resource_group.phonebook_rg.name
#   allocation_method   = "Dynamic"
# }

# # Define the load balancer for the phonebook application
# resource "azurerm_lb" "phonebook_lb" {
#   name                = "phonebook-lb"
#   location            = "eastus"
#   resource_group_name = azurerm_resource_group.phonebook_rg.name

#   frontend_ip_configuration {
#     name                 = "phonebook-lb-feip"
#     public_ip_address_id = azurerm_public_ip.phonebook_public_ip.id
#   }

#   backend_address_pool {
#     name = "phonebook-backend-pool"
#   }

#   probe {
#     name                = "phonebook-lb-probe"
#     protocol            = "Tcp"
#     port                = 80
#     interval_in_seconds = 5
#     number_of_probes    = 2
#   }

#   load_balancing_rule {
#     name                           = "phonebook-lb-rule"
#     frontend_ip_configuration_name = "phonebook-lb-feip"
#     backend_address_pool_id        = azurerm_lb.phonebook_lb.backend_address_pool[0].id
#     probe_id                       = azurerm_lb.phonebook_lb.probes[0].id
#     protocol                       = "Tcp"
#     frontend_port                  = 80
#     backend_port                   = 80
#   }
# }

# resource "azurerm_lb_backend_address_pool" "phonebook_lb_backend_pool" {
#   name                = "phonebook-lb-backend-pool"
#   resource_group_name = azurerm_resource_group.phonebook_rg.name

#   # Associate the virtual machines with the backend address pool
#   virtual_machine_id   = [
#     azurerm_linux_virtual_machine.phonebook_vm[0].id,
#     azurerm_linux_virtual_machine.phonebook_vm[1].id
#   ]
# }

# # Define the network security group for the virtual machines
# resource "azurerm_network_security_group" "phonebook_nsg" {
#   name                = "phonebook-nsg"
#   location            = "eastus"
#   resource_group_name = azurerm_resource_group.phonebook_rg.name

#   security_rule {
#     name                       = "http-inbound-rule"
#     priority                   = 100
#     direction                  = "Inbound"
#     access                     = "Allow"
#     protocol                   = "Tcp"
#     source_port_range          = "*"
#     destination_port_range     = "80"
#     source_address_prefix      = "*"
#     destination_address_prefix = "*"
#   }
# }

# # Define the virtual machines for the phonebook application
# resource "azurerm_linux_virtual_machine" "phonebook_vm" {
#   count               = 2
#   name                = "phonebook-vm-${count.index}"
#   location            = "eastus"
#   resource_group_name = azurerm_resource_group.phonebook_rg.name
#   size                = "Standard_B1ms"
#   admin_username      = "phonebookadmin"
#   admin_password      = "Password123!"

#   storage_image_reference {
#     publisher = "Canonical"
#     offer     = "UbuntuServer"
#     sku       = "16"
#   }

#   os_disk {
#     name                 = "phonebook-vm-osdisk-${count.index}"
#     caching              = "ReadWrite"
#     storage_account_type = "Standard_LRS"
#   }
#   network_interface {
#     name                      = "phonebook-nic-${count.index}"
#     location                  = "eastus"
#     resource_group_name       = azurerm_resource_group.phonebook_rg.name
#     network_security_group_id = azurerm_network_security_group.phonebook_nsg.id

#     #   python
#     ip_configuration {
#       name                                   = "phonebook-ip-config-${count.index}"
#       subnet_id                              = azurerm_virtual_network.phonebook_vnet.subnet.id
#       load_balancer_backend_address_pool_ids = [azurerm_lb.phonebook_lb.backend_address_pool[0].id]
#       load_balancer_inbound_nat_rules_ids    = [azurerm_lb.phonebook_lb.inbound_nat_rules[count.index].id]
#     }
#   }
# }

# # Define the inbound NAT rules for the load balancer
# resource "azurerm_lb_nat_rule" "phonebook_nat_rule" {
#   count               = 2
#   name                = "phonebook-nat-rule-${count.index}"
#   resource_group_name = azurerm_resource_group.phonebook_rg.name
#   load_balancer_id    = azurerm_lb.phonebook_lb.id
#   protocol            = "Tcp"
#   frontend_port       = 5000 + count.index
#   backend_port        = 80
#   backend_ip_address  = azurerm_linux_virtual_machine.phonebook_vm[count.index].network_interface[0].private_ip_address
# }

# # Define the Azure SQL database for the phonebook application
# resource "azurerm_sql_server" "phonebook_sql_server" {
#   name                         = "phonebook-sql-server"
#   resource_group_name          = azurerm_resource_group.phonebook_rg.name
#   location                     = "eastus"
#   version                      = "12.0"
#   administrator_login          = "sqladmin"
#   administrator_login_password = "Password123!"

#   tags = {
#     environment = "dev"
#   }
# }

# resource "azurerm_sql_database" "phonebook_db" {
#   name                = "phonebook-db"
#   resource_group_name = azurerm_resource_group.phonebook_rg.name
#   server_name         = azurerm_sql_server.phonebook_sql_server.name
#   edition             = "Standard"
#   collation           = "SQL_Latin1_General_CP1_CI_AS"

#   tags = {
#     environment = "dev"
#   }
# }

# output "phonebook_lb_ip_address" {
#   value = azurerm_public_ip.phonebook_public_ip.ip_address
# }