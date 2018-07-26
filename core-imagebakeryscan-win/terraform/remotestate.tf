data "terraform_remote_state" "corenetworking" {
  backend = "azure"
  config {
    storage_account_name = "${var.remote_storage_account_name}"
    container_name       = "${var.remote_container_name}"
    key                  = "${var.remote_key_network}"
    resource_group_name  = "${var.remote_resource_group_name}"
  }
}