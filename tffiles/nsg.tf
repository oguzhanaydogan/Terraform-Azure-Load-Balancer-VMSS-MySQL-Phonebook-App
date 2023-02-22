# Create an Azure Network Security Group to allow access to the phonebook application
resource "azurerm_network_security_group" "phonebook" {
name = "phonebook-nsg"
location = "eastus"
resource_group_name = azurerm_resource_group.example.name

security_rule {
name = "AllowSSH"
priority = 1001
direction = "Inbound"
access = "Allow"
protocol = "Tcp"
source_port_range = "*"
destination_port_range = "22"
source_address_prefix = "*"
destination_address_prefix = "*"
}

security_rule {
name = "AllowHTTP"
priority = 1002
direction = "Inbound"
access = "Allow"
protocol = "Tcp"
source_port_range = "*"
destination_port_range = "80"
source_address_prefix = "*"
destination_address_prefix = "*"
}

security_rule {
name = "AllowHTTPS"
priority = 1003
direction = "Inbound"
access = "Allow"
protocol = "Tcp"
source_port_range = "*"
destination_port_range = "443"
source_address_prefix = "*"
destination_address_prefix = "*"
}

security_rule {
name = "AllowSQLServer"
priority = 1004
direction = "Inbound"
access = "Allow"
protocol = "Tcp"
source_port_range = "*"
destination_port_range = "1433"
source_address_prefix = "*"
destination_address_prefix = "*"
}
}