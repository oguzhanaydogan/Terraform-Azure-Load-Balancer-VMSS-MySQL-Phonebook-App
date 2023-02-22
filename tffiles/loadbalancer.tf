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

  loadbalancer_id     = azurerm_lb.example.id
  name                = "BackEndAddressPool"
}

resource "azurerm_lb_rule" "example" {
  name                   = "my-lb-rule"
  loadbalancer_id        = azurerm_lb.example.id
  backend_address_pool_ids = [azurerm_lb_backend_address_pool.bpepool.id]
  protocol               = "Tcp"
  frontend_port          = 80
  backend_port           = 80
  enable_floating_ip             = false
  idle_timeout_in_minutes        = 5
  frontend_ip_configuration_name = "PublicIPAddress"
  probe_id = azurerm_lb_probe.example.id
}

resource "azurerm_lb_rule" "ssh" {
  name                   = "my-lb-ssh"
  loadbalancer_id        = azurerm_lb.example.id
  backend_address_pool_ids = [azurerm_lb_backend_address_pool.bpepool.id]
  protocol               = "Tcp"
  frontend_port          = 22
  backend_port           = 22
  enable_floating_ip             = false
  idle_timeout_in_minutes        = 5
  frontend_ip_configuration_name = "PublicIPAddress"
  probe_id = azurerm_lb_probe.example2.id
}

resource "azurerm_lb_probe" "example" {
name = "my-health-probe"
loadbalancer_id = azurerm_lb.example.id
protocol = "Tcp"
port = 80
}

resource "azurerm_lb_probe" "example2" {
name = "my-health-probe-ssh"
loadbalancer_id = azurerm_lb.example.id
protocol = "Tcp"
port = 22
}

