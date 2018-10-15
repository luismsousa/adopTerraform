resource "azurerm_network_interface" "adopMainNic" {
  name                = "adop-nic"
  location            = "${azurerm_resource_group.sandbox.location}"
  resource_group_name = "${azurerm_resource_group.sandbox.name}"
  network_security_group_id = "${azurerm_network_security_group.adopSecurityGroup.id}"

  ip_configuration {
    name                          = "standard"
    subnet_id                     = "${azurerm_subnet.sandboxSubnet.id}"
    private_ip_address_allocation = "static"
    private_ip_address = "172.31.64.10" ## TODO: need to make this dinamic but static
    public_ip_address_id = "${azurerm_public_ip.adopEIP.id}"
  }
}

resource "azurerm_virtual_machine" "adopVM" {
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
  }
  os_profile_linux_config {
      disable_password_authentication = true
      ssh_keys {
          key_data = "${var.public_key}"
          path = "/home/centos/.ssh/authorized_keys"
      }
  }
  depends_on = ["azurerm_network_security_group.adopSecurityGroup", "azurerm_route_table.sandboxRT"]
}

resource "azurerm_virtual_machine_extension" "adopUserData" {
  name                 = "adopSetup"
  location             = "${azurerm_resource_group.sandbox.location}"
  resource_group_name  = "${azurerm_resource_group.sandbox.name}"
  virtual_machine_name = "${azurerm_virtual_machine.adopVM.name}"
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
    {
        "commandToExecute": "sleep 30 && curl -L https://raw.githubusercontent.com/luismsousa/adopTerraform/master/azure/1-tier/scripts/userData.sh > ~/userData.sh && chmod +x ~/userData.sh && export INITIAL_ADMIN_USER=${var.adop_username} && export INITIAL_ADMIN_PASSWORD_PLAIN=${var.adop_password} && cd ~/ && ./userData.sh"
    }
SETTINGS

  depends_on = ["azurerm_network_security_group.adopSecurityGroup", "azurerm_route_table.sandboxRT"]
}