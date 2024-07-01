output "azure_subscription_id" {
  description = "Azure Subscription ID"
  value = "${data.dome9_cloudaccount_azure.azure_data_source.subscription_id}"
}

output "cloud_account_id"{
  description = "Cloud Guard account ID"
  value = resource.dome9_awp_azure_onboarding.awp_azure_onboarding_resource.cloud_account_id
}

output "agentless_protection_enabled" {
  description = "AWP Status"
  value       = resource.dome9_awp_azure_onboarding.awp_azure_onboarding_resource.agentless_protection_enabled
}

output "should_update" {
  description = "This module is out of date and should be updated to the latest version."
  value       = resource.dome9_awp_azure_onboarding.awp_azure_onboarding_resource.should_update
}

output "missing_awp_private_network_regions" {
  description = "List of regions in which AWP has issue to create virtual private network (VPC)"
  value       = resource.dome9_awp_azure_onboarding.awp_azure_onboarding_resource.missing_awp_private_network_regions
}

output "account_issues" {
  description = "Indicates if there are any issues with AWP in the account"
  value       = resource.dome9_awp_azure_onboarding.awp_azure_onboarding_resource.account_issues
}
