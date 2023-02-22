resource "azurerm_sql_server" "phonebook" {
  name                         = "phonebookdb"
  resource_group_name          = azurerm_resource_group.example.name
  location                     = "eastus"
  version                      = "12.0"
  administrator_login          = "clouduser"
  administrator_login_password = "Password1234"
}

resource "azurerm_sql_database" "phonebook" {
  name                = "phonebook"
  resource_group_name = azurerm_resource_group.example.name
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