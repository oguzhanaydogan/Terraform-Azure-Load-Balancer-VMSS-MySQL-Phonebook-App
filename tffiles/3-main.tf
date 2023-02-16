# Define the virtual machine scale set
resource "azurerm_linux_virtual_machine_scale_set" "phonebook_vmss" {
  name                = "phonebook-vmss"
  resource_group_name = azurerm_resource_group.phonebook_rg.name
  location            = azurerm_resource_group.phonebook_rg.location
  sku                 = "Standard_DS1_v2"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "phonebook-vmss-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name_prefix = "phonebook-vmss"
    admin_username       = "adminuser"
    admin_password       = "P@ssw0rd123!"
    custom_data          = base64encode(file("${path.module}/startup-script.sh"))
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  network_profile {
    network_interface {
      name    = "phonebook-nic"
      primary = true
      ip_configuration {
        name                          = "phonebook-ipconfig"
        subnet_id                     = azurerm_subnet.phonebook_subnet.id
        load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.phonebook_lb_backend_pool.id]
      }
    }
  }

  upgrade_policy_mode = "Automatic"

  # Define the scaling settings
  capacity {
    minimum = 2
    maximum = 5
    default = 2
  }

  # Define the autoscaling rules
  automatic_os_upgrade = true

  automatic_scaling {
    cooldown = "5m"

    metric_trigger {
      metric_name        = "Percentage CPU"
      metric_resource_id = azurerm_linux_virtual_machine_scale_set.phonebook_vmss.id
      time_grain         = "PT1M"
      statistic          = "Average"
      time_window        = "PT5M"
      operator           = "GreaterThan"
      threshold          = 70
    }

    scale_in_policy {
      rules = [
        {
          metric_trigger {
            metric_name        = "Percentage CPU"
            metric_resource_id = azurerm_linux_virtual_machine_scale_set.phonebook_vmss.id
            time_grain         = "PT1M"
            statistic          = "Average"
            time_window       = "PT5M"
            operator = "LessThan"
            threshold = 30
}
recurrence {
time_zone = "UTC"
schedule {
days_of_week = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
hours = [3]
minutes = [0]
}}
},
{
metric_trigger {
metric_name = "Percentage CPU"
metric_resource_id = azurerm_linux_virtual_machine_scale_set.phonebook_vmss.id
time_grain = "PT1M"
statistic = "Average"
time_window = "PT5M"
operator = "LessThan"
threshold = 30
}
recurrence {
time_zone = "UTC"
schedule {
days_of_week = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
hours = [10]
minutes = [0]
}
}
}
]
}
scale_out_policy {
  rules = [
    {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.phonebook_vmss.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        operator           = "GreaterThan"
        threshold          = 70
      }
      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = 1
        cooldown  = "PT5M"
      }
    }
  ]
}
}
}
