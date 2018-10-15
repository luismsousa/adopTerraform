resource "azurerm_virtual_network" "sandboxNetwork" {
  name                = "sandbox-network"
  address_space       = ["172.31.0.0/16"]
  location            = "${azurerm_resource_group.sandbox.location}"
  resource_group_name = "${azurerm_resource_group.sandbox.name}"

}

resource "azurerm_route_table" "sandboxRT" {
  name                = "acceptanceTestSecurityGroup1"
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
  network_security_group_id = "${azurerm_network_security_group.adopSecurityGroup.id}"
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

  security_rule {
    name                       = "SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "22"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "HTTP"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "80"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "HTTPS"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "443"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "DockerTCP"
    priority                   = 103
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "2376"
    destination_port_range     = "2376"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "DockerUDP"
    priority                   = 104
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "25826"
    destination_port_range     = "25826"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }


}