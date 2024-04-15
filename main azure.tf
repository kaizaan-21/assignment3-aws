# Define Azure provider
provider "azurerm" {
  features {}
}

# Define Virtual Network
resource "azurerm_virtual_network" "my_vnet" {
  name                = "keshwaniVNet"
  address_space       = ["10.0.0.0/16"]
  location            = "East US"
  resource_group_name = azurerm_resource_group.my_rg.name
}

# Define Subnets
resource "azurerm_subnet" "subnet1" {
  name                 = "keshwanisubnet1"
  resource_group_name  = azurerm_resource_group.my_rg.name
  virtual_network_name = azurerm_virtual_network.my_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "subnet2" {
  name                 = "keshwanisubnet2"
  resource_group_name  = azurerm_resource_group.my_rg.name
  virtual_network_name = azurerm_virtual_network.my_vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Define Application Load Balancer
resource "azurerm_lb" "my_alb" {
  name                = "keshwaniALB"
  resource_group_name = azurerm_resource_group.my_rg.name
  location            = "East US"
  sku                 = "Standard"
}

# Define NSGs for Subnets
resource "azurerm_network_security_group" "subnet1_nsg" {
  name                = "keshwanisubnet1NSG"
  location            = "East US"
  resource_group_name = azurerm_resource_group.my_rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "subnet2_nsg" {
  name                = "keshwanisubnet2NSG"
  location            = "East US"
  resource_group_name = azurerm_resource_group.my_rg.name

  security_rule {
    name                       = "HTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Attach NSGs to Subnets
resource "azurerm_subnet_network_security_group_association" "subnet1_nsg_association" {
  subnet_id                 = keshwani_subnet.subnet1.id
  network_security_group_id = keshwani_network_security_group.subnet1_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "subnet2_nsg_association" {
  subnet_id                 = keshwani_subnet.subnet2.id
  network_security_group_id = keshwani_network_security_group.subnet2_nsg.id
}

# Define Backend Address Pool for ALB
resource "azurerm_lb_backend_address_pool" "my_alb_backend_pool" {
  name                = "backendPool"
  loadbalancer_id     = keshwani_lb.my_alb.id
}

