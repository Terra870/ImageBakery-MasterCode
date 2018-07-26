resource "azurerm_network_interface" "nic" {
  name                      = "${var.AZ_engg_VM1_Name}-ni"
  resource_group_name       = "${var.az_engg_rg}"
  location                  = "${var.az_engg_loc}"
  
  ip_configuration {
    name                          = "engg-nic-config"
    subnet_id                     = "${data.terraform_remote_state.corenetworking.Network-Details.infrastructure_id}"
    private_ip_address_allocation = "dynamic"
  }
  
  tags {
    billing_id  = "${var.AZ_engg_Billing_Tag1}"
    CreatedBy   = "${var.AZ_engg_CreatedBy_Tag1}"
  }
}