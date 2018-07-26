resource "azurerm_managed_disk" "backup" {
  name                 = "${var.AZ_engg_VM1_Name}-backup-dsk"
  location             = "${var.az_engg_loc}"
  resource_group_name  = "${var.az_engg_rg}"
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "100"
  tags {
    name = "${var.AZ_engg_VM1_Name}-backupdisk"
    CreatedBy = "${var.AZ_engg_CreatedBy_Tag1}"
  }
}

resource "azurerm_managed_disk" "install" {
  name                 = "${var.AZ_engg_VM1_Name}-installdsk"
  location             = "${var.az_engg_loc}"
  resource_group_name  = "${var.az_engg_rg}"
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "100"
  tags {
    name = "${var.AZ_engg_VM1_Name}-installdisk"
    CreatedBy = "${var.AZ_engg_CreatedBy_Tag1}"
  }
}

resource "azurerm_managed_disk" "systemdb01" {
  name                 = "${var.AZ_engg_VM1_Name}-systemdb01-dsk"
  location             = "${var.az_engg_loc}"
  resource_group_name  = "${var.az_engg_rg}"
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "50"
  tags {
    name = "${var.AZ_engg_VM1_Name}-systemdb01disk"
    CreatedBy = "${var.AZ_engg_CreatedBy_Tag1}"
  }
}

resource "azurerm_managed_disk" "tempdbdata01" {
  name                 = "${var.AZ_engg_VM1_Name}-tempdbdata01-dsk"
  location             = "${var.az_engg_loc}"
  resource_group_name  = "${var.az_engg_rg}"
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "50"
  tags {
    name = "${var.AZ_engg_VM1_Name}-tempdbdata01disk"
    CreatedBy = "${var.AZ_engg_CreatedBy_Tag1}"
  }
}

resource "azurerm_managed_disk" "tempdblog01" {
  name                 = "${var.AZ_engg_VM1_Name}-tempdblog01-dsk"
  location             = "${var.az_engg_loc}"
  resource_group_name  = "${var.az_engg_rg}"
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "50"
  tags {
    name = "${var.AZ_engg_VM1_Name}-tempdblog01disk"
    CreatedBy = "${var.AZ_engg_CreatedBy_Tag1}"
  }
}

resource "azurerm_managed_disk" "userdbdata01" {
  name                 = "${var.AZ_engg_VM1_Name}-userdbdata01-dsk"
  location             = "${var.az_engg_loc}"
  resource_group_name  = "${var.az_engg_rg}"
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "50"
  tags {
    name = "${var.AZ_engg_VM1_Name}-userdbdata01"
    CreatedBy = "${var.AZ_engg_CreatedBy_Tag1}"
  }
}

resource "azurerm_managed_disk" "userdblog01" {
  name                 = "${var.AZ_engg_VM1_Name}-userdblog01-dsk"
  location             = "${var.az_engg_loc}"
  resource_group_name  = "${var.az_engg_rg}"
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "50"
  tags {
    name = "${var.AZ_engg_VM1_Name}-userdblog01"
    CreatedBy = "${var.AZ_engg_CreatedBy_Tag1}"
  }
}

resource "azurerm_managed_disk" "mount" {
  name                 = "${var.AZ_engg_VM1_Name}-mount-dsk"
  location             = "${var.az_engg_loc}"
  resource_group_name  = "${var.az_engg_rg}"
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "4"
  tags {
    name = "${var.AZ_engg_VM1_Name}-mount"
    CreatedBy = "${var.AZ_engg_CreatedBy_Tag1}"
  }
}