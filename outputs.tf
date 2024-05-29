output "get_azure_subscription_id" {
  value = "${data.azurerm_subscription.scanner.subscription_id}"
}
