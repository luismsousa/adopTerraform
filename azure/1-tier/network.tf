resource "azurerm_virtual_network" "sandboxNetwork" {
  name                = "sandbox-network"
  address_space       = ["172.31.0.0/16"]
  location            = "${azurerm_resource_group.sandbox.location}"
  resource_group_name = "${azurerm_resource_group.sandbox.name}"

}

resource "azurerm_route_table" "sandboxRT" {
  name                = "sandboxRT"
  location            = "${azurerm_resource_group.sandbox.location}"
  resource_group_name = "${azurerm_resource_group.sandbox.name}"
  
  disable_bgp_route_propagation = false

  route {
    name           = "route1"
    address_prefix = "172.31.64.0/28"
    next_hop_type  = "vnetlocal"
  }
  route {
    name           = "route2"
    address_prefix = "0.0.0.0/0"
    next_hop_type  = "Internet"
  }
}

resource "azurerm_subnet" "sandboxSubnet" {
  name                 = "sandboxSubnet"
  resource_group_name  = "${azurerm_resource_group.sandbox.name}"
  virtual_network_name = "${azurerm_virtual_network.sandboxNetwork.name}"
  address_prefix       = "172.31.64.0/28"
  route_table_id = "${azurerm_route_table.sandboxRT.id}"
}

resource "azurerm_public_ip" "adopEIP" {
  name                         = "adopEIP"
  location                     = "West Europe"
  resource_group_name          = "${azurerm_resource_group.sandbox.name}"
  public_ip_address_allocation = "static"
}

resource "azurerm_network_security_group" "adopSecurityGroup" {
  name                = "adopSecurityGroup"
  location            = "${azurerm_resource_group.sandbox.location}"
  resource_group_name = "${azurerm_resource_group.sandbox.name}"
}

resource "azurerm_network_security_rule" "allow_DockerUDP" {
  name                       = "allow_DockerUDP"
  priority                   = 120
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Udp"
  source_port_range          = "*"
  destination_port_range     = "25826"
  source_address_prefix      = "*"
  destination_address_prefix = "*"
  resource_group_name         = "${azurerm_resource_group.sandbox.name}"
  network_security_group_name = "${azurerm_network_security_group.adopSecurityGroup.name}"
}

resource "azurerm_network_security_rule" "allow_HTTPS" {
  name                       = "allow_HTTPS"
  priority                   = 112
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "443"
  source_address_prefix      = "*"
  destination_address_prefix = "*"
  resource_group_name         = "${azurerm_resource_group.sandbox.name}"
  network_security_group_name = "${azurerm_network_security_group.adopSecurityGroup.name}"
}

resource "azurerm_network_security_rule" "allow_DockerTCP" {
  name                       = "allow_DockerTCP"
  priority                   = 121
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "2376"
  source_address_prefix      = "*"
  destination_address_prefix = "*"
  resource_group_name         = "${azurerm_resource_group.sandbox.name}"
  network_security_group_name = "${azurerm_network_security_group.adopSecurityGroup.name}"
}

resource "azurerm_network_security_rule" "allow_HTTP" {
  name                       = "allow_HTTP"
  priority                   = 122
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "80"
  source_address_prefix      = "*"
  destination_address_prefix = "*"
  resource_group_name         = "${azurerm_resource_group.sandbox.name}"
  network_security_group_name = "${azurerm_network_security_group.adopSecurityGroup.name}"
}

resource "azurerm_network_security_rule" "allow_SSH" {
  name                       = "allow_SSH"
  priority                   = 133
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "22"
  source_address_prefix      = "*"
  destination_address_prefix = "*"
  resource_group_name         = "${azurerm_resource_group.sandbox.name}"
  network_security_group_name = "${azurerm_network_security_group.adopSecurityGroup.name}"
}