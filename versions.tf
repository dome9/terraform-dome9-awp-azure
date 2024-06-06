terraform {
  required_version = ">= 1.0"
  
  required_providers {
    dome9 = {
      source = "dome9/dome9"
      version = ">=1.29.7"
    }
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.99.0"
    }
    time = {
      source = "hashicorp/time"
      version = "0.11.2"
    }
  }
}
