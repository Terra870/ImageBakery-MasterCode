# Create a storage account for the infrastructure
/*resource "azurerm_storage_account" "az-engg-sa" {
  name                   = "imagebakerytemp12345"
  resource_group_name    = "${var.az_engg_rg}"
  location               = "${var.az_engg_loc}"
  account_tier          = "${var.az_engg_sa_account_tier}"
  account_replication_type = "${var.az_engg_sa_account_replication_type}"

  enable_blob_encryption = true

  tags {
    environment = "${var.AZ_engg_Env_Tag1}"
    billing_id  = "${var.AZ_engg_Billing_Tag1}"
    CreatedBy   = "${var.AZ_engg_CreatedBy_Tag1}"
  }
}

resource "azurerm_storage_container" "az-engg-sc1" {
  name                  = "vhds"
  resource_group_name    = "${var.az_engg_rg}"
  storage_account_name  = "${azurerm_storage_account.az-engg-sa.name}"
  container_access_type = "private"
}*/
