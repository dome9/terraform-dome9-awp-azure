output "cloud_account_id" {
  description = "Cloud Guard account ID"
  value       = module.terraform-dome9-awp-azure[0].cloud_account_id
}