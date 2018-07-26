resource "azurerm_virtual_machine" "vm" {
  name                          = "${var.AZ_engg_VM1_Name}"
  resource_group_name           = "${var.az_engg_rg}"
  location                      = "${var.az_engg_loc}"
  network_interface_ids         = ["${azurerm_network_interface.nic.id}"]
  vm_size                       = "Standard_DS2_v2"
  license_type                  = "Windows_Server"
  delete_os_disk_on_termination = "true"

  storage_image_reference {
    id = "${var.image_id}" 
  }

  storage_os_disk {
    name              = "${var.AZ_engg_VM1_Name}-os-dsk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "${var.AZ_engg_VM1_Name}"
    admin_username = "${var.AZ_engg_VM1_UserName}"
    admin_password = "${var.AZ_engg_VM1_Pass}"
  }

  os_profile_windows_config {
    provision_vm_agent        = true
    #enable_automatic_upgrades = true  
    #winrm {
    #  protocol = "http"
    #} 
  }

  tags {
    billing_id  = "${var.AZ_engg_Billing_Tag}"
    CreatedBy   = "${var.AZ_engg_CreatedBy_Tag}"
    Name        = "${var.AZ_engg_VM1_Name}"
    instancetype = "tempimagebakeryvm"
  }
}
