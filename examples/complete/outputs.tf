# Optional: output usage

output "azure_subscription_id" {
  description = "Azure Subscription ID"
  value       = module.terraform-dome9-awp-azure[0].azure_subscription_id
}

output "cloud_account_id" {
  description = "CloudGuard account ID"
  value       = module.terraform-dome9-awp-azure[0].cloud_account_id
}

output "agentless_protection_enabled" {
  description = "AWP Status"
  value       = module.terraform-dome9-awp-azure[0].agentless_protection_enabled
}

output "should_update" {
  description = "Should update"
  value       = module.terraform-dome9-awp-azure[0].should_update
}

output "missing_awp_private_network_regions" {
  description = "List of regions in which AWP has issue to create virtual private network (VPC)"
  value       = module.terraform-dome9-awp-azure[0].missing_awp_private_network_regions
}

output "account_issues" {
  description = "Indicates if there are any issues with AWP in the account"
  value       = module.terraform-dome9-awp-azure[0].account_issues
}