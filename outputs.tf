output "get_azure_subscription_id" {
  value = "${data.azurerm_subscription.scanner.subscription_id}"
}

output "app_object_id" {
  value = data.external.get_application_id.result["appId"]
}