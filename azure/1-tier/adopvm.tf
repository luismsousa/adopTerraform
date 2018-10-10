resource "azurerm_network_interface" "adopMainNic" {
  name                = "adop-nic"
  location            = "${azurerm_resource_group.sandbox.location}"
  resource_group_name = "${azurerm_resource_group.sandbox.name}"

  ip_configuration {
    name                          = "standard"
    subnet_id                     = "${azurerm_subnet.sandboxSubnet.id}"
    private_ip_address_allocation = "static"
    private_ip_address = "172.31.64.10"
    public_ip_address_id = "${azurerm_public_ip.adopEIP.id}"
  }
}

data "template_file" "ADOPInit" {
  template = "${file("${path.module}/scripts/init.tpl")}"

  vars {
    adop_username = "${var.adop_username}"
    adop_password = "${var.adop_password}"
  }
}

resource "azurerm_virtual_machine" "main" {
  name                  = "adop-vm"
  location              = "${azurerm_resource_group.sandbox.location}"
  resource_group_name   = "${azurerm_resource_group.sandbox.name}"
  network_interface_ids = ["${azurerm_network_interface.adopMainNic.id}"]
  vm_size               = "Standard_D4s_v3"

  
  delete_os_disk_on_termination = true

  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "7.3"
    version   = "latest"
  }

  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
    disk_size_gb = 50
    #need to split this from one disk to multiple like in AWS.
  }

  os_profile{
      computer_name = "ADOP"
      admin_username = "centos"
      custom_data = "${data.template_file.ADOPInit.rendered}"
  }
  os_profile_linux_config {
      disable_password_authentication = true
      ssh_keys {
          key_data = "${var.public_key}"
          path = "/home/centos/.ssh/authorized_keys"
      }
  }
}