# Output the load balancer public IP address
output "phonebook_lb_public_ip" {
  value = azurerm_public_ip.example.ip_address
}

