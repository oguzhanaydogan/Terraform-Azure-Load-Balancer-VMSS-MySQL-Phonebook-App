# Output the load balancer public IP address
output "phonebook_lb_public_ip" {
  value = azurerm_public_ip.phonebook_public_ip.ip_address
}

