# Configure the Azure provider
provider "azurerm" {
  features {}
}

# Create an Azure SQL Database
resource "azurerm_sql_server" "phonebook" {
  name                         = "phonebookdb"
  resource_group_name          = "my-resource-group"
  location                     = "eastus"
  version                      = "12.0"
  administrator_login          = "clouduser"
  administrator_login_password = "Password1234"
}

resource "azurerm_sql_database" "phonebook" {
  name                = "phonebook"
  resource_group_name = "my-resource-group"
  location            = "eastus"
  server_name         = azurerm_sql_server.phonebook.name
  edition             = "Standard"
  collation           = "SQL_Latin1_General_CP1_CI_AS"
}

resource "azurerm_sql_firewall_rule" "example" {
  name                = "FirewallRule1"
  resource_group_name = azurerm_resource_group.example.name
  server_name         = azurerm_sql_server.phonebook.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}

resource "github_repository_file" "dbendpoint" {
  content             = azurerm_sql_server.phonebook.fully_qualified_domain_name
  file                = "dbserver.endpoint"
  repository          = "terraform-lb-phonebook-app"
  branch              = "main"
  overwrite_on_create = true
}

resource "azurerm_resource_group" "example" {
  name     = "my-resource-group"
  location = "eastus"
}

resource "azurerm_virtual_network" "example" {
  name                = "phonebook-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_subnet" "example" {
  name                 = "phonebook-subnet"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.2.0/24"]
}


resource "azurerm_public_ip" "example" {
  name                = "phonebook-pip"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  allocation_method   = "Static"
  domain_name_label   = azurerm_resource_group.example.name
}

resource "azurerm_lb" "example" {
  name                = "phonebook-lb"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.example.id
  }
}

resource "azurerm_lb_backend_address_pool" "bpepool" {
  resource_group_name = azurerm_resource_group.example.name
  loadbalancer_id     = azurerm_lb.example.id
  name                = "BackEndAddressPool"
}

# resource "azurerm_lb_nat_pool" "lbnatpool" {
#   resource_group_name            = azurerm_resource_group.example.name
#   name                           = "ssh"
#   loadbalancer_id                = azurerm_lb.example.id
#   protocol                       = "Tcp"
#   frontend_port_start            = 50000
#   frontend_port_end              = 50119
#   backend_port                   = 22
#   frontend_ip_configuration_name = "PublicIPAddress"
# }

resource "azurerm_lb_probe" "example" {
  resource_group_name = azurerm_resource_group.example.name
  loadbalancer_id     = azurerm_lb.example.id
  name                = "http-probe"
  protocol            = "Http"
  request_path        = "/health"
  port                = 80
}

resource "azurerm_virtual_machine_scale_set" "example" {
  name                = "mytestscaleset-1"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  
  # automatic rolling upgrade
  automatic_os_upgrade = true
  upgrade_policy_mode  = "Rolling"

  rolling_upgrade_policy {
    max_batch_instance_percent              = 20
    max_unhealthy_instance_percent          = 20
    max_unhealthy_upgraded_instance_percent = 5
    pause_time_between_batches              = "PT0S"
  }

  # required when using rolling upgrade policy
  health_probe_id = azurerm_lb_probe.example.id

  sku {
    name     = "Standard_F2"
    tier     = "Standard"
    capacity = 2
  }

  storage_profile_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_profile_os_disk {
    name              = ""
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_profile_data_disk {
    lun           = 0
    caching       = "ReadWrite"
    create_option = "Empty"
    disk_size_gb  = 10
  }

  os_profile {
    computer_name_prefix = "testvm"
    admin_username       = "clouduser"
    custom_data = file(userdata.sh)
    # custom_data          = base64encode(file("${path.module}/userdata.sh"))
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/myadmin/.ssh/authorized_keys"
      key_data = file("~/Downloads/key/oguzhankey.pub")
    }
  }

  network_profile {
    name    = "terraformnetworkprofile"
    primary = true

    ip_configuration {
      name                                   = "TestIPConfiguration"
      primary                                = true
      subnet_subnet_id                       = azurerm_subnet.example.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.bpepool.id]
      load_balancer_inbound_nat_rules_ids    = [azurerm_lb_nat_pool.lbnatpool.id]
      network_security_group_id              = [azurerm_network_security_group.phonebook.id]
    }
  }

}

# Create an Azure Network Security Group to allow access to the phonebook application
resource "azurerm_network_security_group" "phonebook" {
name = "phonebook-nsg"
location = "eastus"
resource_group_name = "my-resource-group"

security_rule {
name = "AllowSSH"
priority = 1001
direction = "Inbound"
access = "Allow"
protocol = "Tcp"
source_port_range = ""
destination_port_range = "22"
source_address_prefix = ""
destination_address_prefix = "*"
}

security_rule {
name = "AllowHTTP"
priority = 1002
direction = "Inbound"
access = "Allow"
protocol = "Tcp"
source_port_range = ""
destination_port_range = "80"
source_address_prefix = ""
destination_address_prefix = "*"
}

security_rule {
name = "AllowHTTPS"
priority = 1003
direction = "Inbound"
access = "Allow"
protocol = "Tcp"
source_port_range = ""
destination_port_range = "443"
source_address_prefix = ""
destination_address_prefix = "*"
}

security_rule {
name = "AllowSQLServer"
priority = 1004
direction = "Inbound"
access = "Allow"
protocol = "Tcp"
source_port_range = ""
destination_port_range = "1433"
source_address_prefix = ""
destination_address_prefix = "*"
}
}