data "azurerm_image" "search" {
  name                = "${var.imagename}"
  resource_group_name = "${var.az_engg_rg}"
}

resource "azurerm_virtual_machine" "vm" {
  name                          = "${var.AZ_engg_VM1_Name}"
  resource_group_name           = "${var.az_engg_rg}"
  location                      = "${var.az_engg_loc}"
  network_interface_ids         = ["${azurerm_network_interface.nic.id}"]
  vm_size                       = "Standard_DS2_v2"
  license_type                  = "Windows_Server"
  delete_os_disk_on_termination = "true"

  storage_image_reference {
    id="${data.azurerm_image.search.id}"
  }

  storage_os_disk {
    name              = "${var.AZ_engg_VM1_Name}-os-dsk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_data_disk {
    name            = "${azurerm_managed_disk.backup.name}"
    managed_disk_id = "${azurerm_managed_disk.backup.id}"
    create_option   = "Attach"
    lun             = 1
    disk_size_gb    = "${azurerm_managed_disk.backup.disk_size_gb}"
  }

  storage_data_disk {
    name            = "${azurerm_managed_disk.install.name}"
    managed_disk_id = "${azurerm_managed_disk.install.id}"
    create_option   = "Attach"
    lun             = 2
    disk_size_gb    = "${azurerm_managed_disk.install.disk_size_gb}"
  }

  storage_data_disk {
    name            = "${azurerm_managed_disk.systemdb01.name}"
    managed_disk_id = "${azurerm_managed_disk.systemdb01.id}"
    create_option   = "Attach"
    lun             = 3
    disk_size_gb    = "${azurerm_managed_disk.systemdb01.disk_size_gb}"
  }

  storage_data_disk {
    name            = "${azurerm_managed_disk.tempdbdata01.name}"
    managed_disk_id = "${azurerm_managed_disk.tempdbdata01.id}"
    create_option   = "Attach"
    lun             = 4
    disk_size_gb    = "${azurerm_managed_disk.tempdbdata01.disk_size_gb}"
  }

  storage_data_disk {
    name            = "${azurerm_managed_disk.tempdblog01.name}"
    managed_disk_id = "${azurerm_managed_disk.tempdblog01.id}"
    create_option   = "Attach"
    lun             = 5
    disk_size_gb    = "${azurerm_managed_disk.tempdblog01.disk_size_gb}"
  }

  storage_data_disk {
    name            = "${azurerm_managed_disk.userdbdata01.name}"
    managed_disk_id = "${azurerm_managed_disk.userdbdata01.id}"
    create_option   = "Attach"
    lun             = 6
    disk_size_gb    = "${azurerm_managed_disk.userdbdata01.disk_size_gb}"
  }

  storage_data_disk {
    name            = "${azurerm_managed_disk.userdblog01.name}"
    managed_disk_id = "${azurerm_managed_disk.userdblog01.id}"
    create_option   = "Attach"
    lun             = 7
    disk_size_gb    = "${azurerm_managed_disk.userdblog01.disk_size_gb}"
  }

  storage_data_disk {
    name            = "${azurerm_managed_disk.mount.name}"
    managed_disk_id = "${azurerm_managed_disk.mount.id}"
    create_option   = "Attach"
    lun             = 8
    disk_size_gb    = "${azurerm_managed_disk.mount.disk_size_gb}"
  }

  os_profile {
    computer_name  = "${var.AZ_engg_VM1_Name}"
    admin_username = "${var.AZ_engg_VM1_UserName}"
    admin_password = "${var.AZ_engg_VM1_Pass}"
  }

  os_profile_windows_config {
    provision_vm_agent        = true
    enable_automatic_upgrades = true  
    winrm {
      protocol = "http"
    } 
  }

  tags {
    billing_id  = "${var.AZ_engg_Billing_Tag1}"
    CreatedBy   = "${var.AZ_engg_CreatedBy_Tag1}"
    Name        = "${var.AZ_engg_VM1_Name}"
  }
}
