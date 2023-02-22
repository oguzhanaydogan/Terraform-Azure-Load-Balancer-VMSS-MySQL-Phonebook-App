resource "azurerm_mysql_server" "example" {
  name                = "phonebook-app"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  sku_name            = "B_Gen5_1"
  storage_mb          = 5120
  version             = "5.7"
  administrator_login = "clouduser"
  administrator_login_password = "Password1234"

  ssl_enforcement_enabled = true
}
# resource "azurerm_mysql_database" "example" {
#   name                = "phonebook"
#   resource_group_name = azurerm_resource_group.example.name
#   server_name         = azurerm_mysql_server.example.name
#   charset             = "utf8"
#   collation           = "utf8_unicode_ci"
# }

resource "azurerm_mysql_database" "example" {
  name                = "phonebook"
  resource_group_name = azurerm_resource_group.example.name
  server_name         = azurerm_mysql_server.example.name
  charset             = "utf8mb4"
  collation           = "utf8mb4_unicode_ci"
}

resource "azurerm_mysql_firewall_rule" "example" {
  name                = "FirewallRule1"
  resource_group_name = azurerm_resource_group.example.name
  server_name         = azurerm_mysql_server.example.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}