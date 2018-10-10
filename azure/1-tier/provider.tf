# Configure the Azure Provider
provider "azurerm" { 
    subscription_id = "${var.subscription_id}"
    client_id = "${var.client_id}"
    client_secret = "${var.client_secret}"
    tenant_id = "${var.tenant_id}"
}

# Create a resource group
resource "azurerm_resource_group" "sandbox" {
  name     = "sandbox"
  location = "West Europe"
}
