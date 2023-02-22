resource "azurerm_virtual_machine_scale_set" "example" {
  name                = "mytestscaleset-1"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  depends_on = [
    github_repository_file.dbendpoint
  ]
  
#   automatic rolling upgrade
   automatic_os_upgrade = false
   upgrade_policy_mode  = "Manual"

  # rolling_upgrade_policy {
  #   max_batch_instance_percent              = 20
  #   max_unhealthy_instance_percent          = 20
  #   max_unhealthy_upgraded_instance_percent = 5
  #   pause_time_between_batches              = "PT0S"
  # }

#   required when using rolling upgrade policy
  # health_probe_id = azurerm_lb_probe.example.id

  sku {
    name     = "Standard_F2"
    tier     = "Standard"
    capacity = 2
  }

  storage_profile_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
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
    admin_password = "Password1234"
    custom_data = file("userdata.sh")
    # custom_data          = base64encode(file("${path.module}/userdata.sh"))
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/clouduser/.ssh/authorized_keys"
      key_data = file("~/Downloads/key/oguzhankey.pub")
    }
  }

  network_profile {
    name    = "terraformnetworkprofile"
    primary = true
    network_security_group_id = azurerm_network_security_group.phonebook.id

    ip_configuration {
      name                                   = "TestIPConfiguration"
      primary                                = true
      subnet_id                              = azurerm_subnet.example.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.bpepool.id]
    }
  }

}