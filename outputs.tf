output "get_azure_subscription_id" {
  value = "${data.dome9_cloudaccount_azure.azure_data_source.subscription_id}"
}
