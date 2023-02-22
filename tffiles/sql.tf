resource "azurerm_mysql_flexible_server" "example" {
  name                = "phonebook-app"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  administrator_login = "clouduser"
  administrator_password = "Password1234"
  sku_name = "GP_Standard_D2ds_v4"
  
}

resource "azurerm_mysql_flexible_server_configuration" "example" {
  name                = "example-configuration"
  resource_group_name = azurerm_resource_group.example.name
  server_name         = azurerm_mysql_flexible_server.example.name
  value               = <<CONFIG
  {
    "require_secure_transport": "OFF"
  }
  CONFIG
}

resource "azurerm_mysql_flexible_database" "example" {
  name                = "phonebook"
  resource_group_name = azurerm_resource_group.example.name
  server_name         = azurerm_mysql_flexible_server.example.name
  charset             = "latin1"
  collation           = "latin1_general_ci"
  
}


resource "azurerm_mysql_flexible_server_firewall_rule" "example" {
  name                = "FirewallRule1"
  resource_group_name = azurerm_resource_group.example.name
  server_name         = azurerm_mysql_flexible_server.example.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}