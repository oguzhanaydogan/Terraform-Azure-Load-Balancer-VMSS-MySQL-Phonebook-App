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
  administrator_login          = "phonebookadmin"
  administrator_login_password = "supersecurepassword"

  tags = {
    environment = "dev"
  }
}

resource "azurerm_sql_database" "phonebook" {
  name                = "phonebook"
  resource_group_name = "my-resource-group"
  location            = "eastus"
  server_name         = azurerm_sql_server.phonebook.name
  edition             = "Standard"
  collation           = "SQL_Latin1_General_CP1_CI_AS"

  tags = {
    environment = "dev"
  }
}

# Create an Azure Load Balancer
resource "azurerm_lb" "phonebook" {
  name                = "phonebook-lb"
  location            = "eastus"
  resource_group_name = "my-resource-group"

  frontend_ip_configuration {
    name                          = "LB-Frontend"
    public_ip_address_id          = azurerm_public_ip.phonebook.id
  }

  dynamic "backend_address_pool" {
    for_each = azurerm_virtual_machine_scale_set.phonebook.*.instance_id

    content {
      name = "${backend_address_pool.value}-pool"
    }
  }

  dynamic "probe" {
    for_each = azurerm_virtual_machine_scale_set.phonebook.*.instance_id

    content {
      name                   = "${probe.value}-probe"
      protocol               = "tcp"
      port                   = 80
      interval               = 30
      number_of_probes       = 2
      request_path           = "/"
      backend_address_pool_id = "${azurerm_lb.phonebook.backend_address_pool[probe.key].id}"
    }
  }

  dynamic "rule" {
    for_each = azurerm_virtual_machine_scale_set.phonebook.*.instance_id

    content {
      name                           = "${rule.value}-rule"
      protocol                       = "tcp"
      frontend_port                  = 80
      backend_port                   = 80
      frontend_ip_configuration_name = "LB-Frontend"
      backend_address_pool_id        = "${azurerm_lb.phonebook.backend_address_pool[rule.key].id}"
      probe_id                       = "${azurerm_lb.phonebook.probe[rule.key].id}"
    }
  }

  tags = {
    environment = "dev"
  }
}

resource "azurerm_public_ip" "phonebook" {
  name                = "phonebook-lb-public-ip"
  location            = "eastus"
  resource_group_name = "my-resource-group"
  allocation_method   = "Static"

  tags = {
    environment = "dev"
  }
}

# Create a Virtual Machine Scale Set with auto scaling
resource "azurerm_virtual_machine_scale_set" "phonebook" {
  name                         = "phonebook-vmss"
  resource_group_name          = "my-resource-group"
  location                     = "eastus"
  sku                          = "Standard_DS1_v2"
  instances                    = 2
  automatic_repair_enabled     = true
  upgrade_policy_mode          = "Automatic"
  health_probe_id              = azurerm_lb.phonebook.probe[0].id
  virtual_network_subnet_id    = az

#   Connect to the Virtual Machine Scale Set through SSH
os_profile {
computer_name_prefix = "phonebook"
admin_username = "azureuser"
admin_password = "SuperSecretPassword123"
}

storage_image_reference {
publisher = "Canonical"
offer = "UbuntuServer"
sku = "16.04-LTS"
version = "latest"
}

storage_os_disk {
name = "phonebook-os-disk"
caching = "ReadWrite"
create_option = "FromImage"
managed_disk_type = "Premium_LRS"
}

os_disk {
name = "phonebook-os-disk"
caching = "ReadWrite"
create_option = "FromImage"
managed_disk_type = "Premium_LRS"
}

network_interface {
name = "phonebook-nic"
primary = true
network_security_group_id = azurerm_network_security_group.phonebook.id
ip_configuration {
name = "phonebook-ipconfig"
subnet_id = azurerm_subnet.phonebook.id
load_balancer_backend_address_pool_ids = [azurerm_lb.phonebook.backend_address_pool[0].id]
load_balancer_inbound_nat_rules_ids = []
}
}

scale_in_policy {
time_grain = "PT1M"
cool_down = "PT5M"
evaluation_interval = "PT5M"
rules {
metric_trigger {
metric_name = "Percentage CPU"
metric_resource_id = "${azurerm_virtual_machine_scale_set.phonebook.id}"
time_grain = "PT1M"
statistic = "Average"
time_window = "PT5M"
operator = "GreaterThan"
threshold = 70
}
scale_action {
direction = "In"
type = "ChangeCount"
value = 1
cooldown = "PT5M"
}
}
}

scale_out_policy {
time_grain = "PT1M"
cool_down = "PT5M"
evaluation_interval = "PT5M"
rules {
metric_trigger {
metric_name = "Percentage CPU"
metric_resource_id = "${azurerm_virtual_machine_scale_set.phonebook.id}"
time_grain = "PT1M"
statistic = "Average"
time_window = "PT5M"
operator = "GreaterThan"
threshold = 50
}
scale_action {
direction = "Out"
type = "ChangeCount"
value = 1
cooldown = "PT5M"
}
}
}

tags = {
environment = "dev"
}
}

# Create a Virtual Machine Scale Set Extension to install and configure the Phonebook Application
resource "azurerm_virtual_machine_scale_set_extension" "phonebook" {
name = "phonebook-extension"
resource_group_name = "my-resource-group"
location = "eastus"
virtual_machine_scale_set_id = azurerm_virtual_machine_scale_set.phonebook.id
publisher = "Microsoft.Azure.Extensions"
type = "CustomScript"
type_handler_version = "2.1"

settings = <<SETTINGS
{
"commandToExecute": "python3 /path/to/phonebook-app.py"
}
SETTINGS

tags = {
environment = "dev"
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

tags = {
environment = "dev"
}
}

# Create an Azure Load Balancer to distribute traffic to the Phonebook Application
resource "azurerm_lb" "phonebook" {
name = "phonebook-lb"
location = "eastus"
resource_group_name = "my-resource-group"

frontend_ip_configuration {
name = "phonebook-ipconfig"
public_ip_address_id = azurerm_public_ip.phonebook.id
}

backend_address_pool {
name = "phonebook-backend-pool"
}

probe {
name = "phonebook-probe"
protocol = "Tcp"
port = 80
}

load_balancing_rule {
name = "phonebook-lb-rule"
frontend_ip_configuration_name = "phonebook-ipconfig"
backend_address_pool_id = azurerm_lb_backend_address_pool.phonebook.id
probe_id = azurerm_lb_probe.phonebook.id
protocol = "Tcp"
frontend_port = 80
backend_port = 80
}

tags = {
environment = "dev"
}
}

# Create an Azure Load Balancer Backend Address Pool to direct traffic to the virtual machines
resource "azurerm_lb_backend_address_pool" "phonebook" {
name = "phonebook-backend-pool"
load_balancer_id = azurerm_lb.phonebook.id
}

# Create an Azure Load Balancer Probe to check the health of the virtual machines
resource "azurerm_lb_probe" "phonebook" {
name = "phonebook-probe"
load_balancer_id = azurerm_lb.phonebook.id
protocol = "Tcp"
port = 80
interval_in_seconds = 5
number_of_probes = 2
}

# Create an Azure Public IP Address for the Load Balancer
resource "azurerm_public_ip" "phonebook" {
name = "phonebook-publicip"
location = "eastus"
resource_group_name = "my-resource-group"
allocation_method = "Static"
sku = "Standard"
tags = {
environment = "dev"
}
}

# Create an Azure Virtual Network
resource "azurerm_virtual_network" "phonebook" {
name = "phonebook-vnet"
address_space = ["10.0.0.0/16"]
location = "eastus"
resource_group_name = "my-resource-group"

subnet {
name = "phonebook-subnet"
address_prefix = "10.0.1.0/24"
}

tags = {
environment = "dev"
}
}

# Create an Azure Network Security Group to secure the virtual machines
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

tags = {
environment = "dev"
}
}

# Create an Azure Virtual Machine Scale Set with auto scaling enabled
resource "azurerm_linux_virtual_machine_scale_set" "phonebook" {
name = "phonebook-vmss"
location = "eastus"
resource_group_name = "my-resource-group"
vm_size = "Standard_B1s"
automatic_repairs_enabled = true
upgrade_policy_mode = "Automatic"
single_placement_group = true
platform_fault_domain_count = 1
platform_update_domain_count = 5
health_probe_id = azurerm_lb_probe.phonebook.id
load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.phonebook.id]
network_interface_ids = azurerm_network_interface.phonebook.*.id
admin_username = "adminuser"
admin_password = "Admin12345!"

source_image_reference {
publisher = "Canonical"
offer = "UbuntuServer"
sku = "18.04-LTS"
version = "latest"
}

os_disk {
caching = "ReadWrite"
storage_account_type = "Premium_LRS"
}

os_profile {
computer_name_prefix = "phonebook-vm"
admin_username = "adminuser"
admin_password = "Admin12345!"
}

extension {
name = "customScript"
publisher = "Microsoft.Azure.Extensions"
type = "CustomScript"
type_handler_version = "2.1"
settings = jsonencode({
  "fileUris": [
    "https://raw.githubusercontent.com/Azure-Samples/compute-automation-configurations/master/terraform-vmss-ubuntu/install_apache.sh",
    "https://raw.githubusercontent.com/Azure-Samples/compute-automation-configurations/master/terraform-vmss-ubuntu/phonebook-app.py"
  ]
})

protected_settings = jsonencode({
  "commandToExecute": "bash install_apache.sh"
})
}

storage_image_reference {
id = "/subscriptions/${var.subscription_id}/resourceGroups/${azurerm_lb.phonebook.resource_group_name}/providers/Microsoft.Compute/images/${azurerm_linux_virtual_machine_scale_set.phonebook.name}-Image"
}
# Enable auto scaling
automatic_repair_enabled = true
upgrade_policy_mode = "Automatic"
max_batch_instance_percent = 20
scale_in_policy {
rules = jsonencode([
{
metric_trigger {
metric_name = "Percentage CPU"
metric_resource_id = azurerm_linux_virtual_machine_scale_set.phonebook.id
time_grain = "PT1M"
statistic = "Average"
time_window = "PT5M"
operator = "GreaterThan"
threshold = 70
}
scale_action {
direction = "In"
type = "ChangeCount"
value = 1
cooldown = "PT5M"
}
},
{
metric_trigger {
metric_name = "Percentage CPU"
metric_resource_id = azurerm_linux_virtual_machine_scale_set.phonebook.id
time_grain = "PT1M"
statistic = "Average"
time_window = "PT5M"
operator = "LessThan"
threshold = 30
}
scale_action {
direction = "Out"
type = "ChangeCount"
value = 1
cooldown = "PT5M"
}
}
])
}

tags = {
environment = "dev"
}
}

