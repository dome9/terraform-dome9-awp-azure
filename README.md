
# CloudGuard AWP (Azure) - Terraform Module

This Terraform module is designed to onboard Azure Subscribtion to Dome9 AWP (Agentless Workload Posture) service.
(https://www.checkpoint.com/dome9/) 

This module use [Check Point CloudGuard Dome9 Provider](https://registry.terraform.io/providers/dome9/dome9/latest/docs)

## Prerequisites

- Azure Account onboarded to Dome9 CloudGuard
- Dome9 CloudGuard API Key and Secret ([Dome9 Provider Authentication](https://registry.terraform.io/providers/dome9/dome9/latest/docs#authentication))
- Azure Credentials ([Azure Provider Authentication](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs#authenticating-to-azure)) (for more info follow: [AWP Documentation](https://sc1.checkpoint.com/documents/CloudGuard_Dome9/Documentation/Workload-Protection/AWP/AWP-Azure-SaaS-and-In-Account.htm))


## Usage

```hcl
module "terraform-dome9-awp-azure" {
  source = "dome9/awp-azure/dome9"

  # The Id of the Azure account,onboarded to CloudGuard (can be either the Dome9 Cloud Account ID or the Azure subscription id)
  awp_cloud_account_id = dome9_cloudaccount_azure.my_azure_cloud_account.id

  # The scan mode for the AWP. Valid values are "inAccount", "saas", "inAccountHub" or "inAccountSub".
  awp_scan_mode = "inAccount"

  # The Id of the centralized Azure account (can be either the Dome9 Cloud Account ID or the Azure subscription id), relevat only for inAccountSub mode
  awp_centralized_cloud_account_id = dome9_cloudaccount_azure.my_azure_centralized_account.id

  # Optional customizations:
  # e.g:
  awp_is_scanned_hub        = false # relevat only for inAccountHub mode
  management_group_id       = "management group id" # relevat only for inAccountHub mode
    

  # Optional account settings
  # e.g:  
  awp_account_settings_azure = {
    scan_machine_interval_in_hours  = 24
    skip_function_apps_scan         = false
    disabled_regions                = [] # e.g ["eastus", "westus"]
    custom_tags                     = {}   # e.g {"key1" = "value1", "key2" = "value2"} 
  }
}
```

## Examples

[examples](./examples) directory contains example usage of this module.
 - [basic](./examples/basic) - A basic example of using this module.
 - [complete](./examples/complete) - A complete example of using this module with all the available options.

## AWP Terraform template

| Version | 2    |
|---------|------| 

<!-- BEGIN_TF_HEADER_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | 3.99.0 |
| <a name="requirement_dome9"></a> [dome9](#requirement\_dome9) | >=1.29.7 |
<!-- END_TF_HEADER_DOCS -->

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_awp_cloud_account_id"></a> [awp_cloud_account_id](#input\_awp\_cloud\_account\_id) | The Id of the Azure account, onboarded to CloudGuard (can be either the Dome9 Cloud Account ID or the Azure subscription id) | `string` | n/a | yes |
| <a name="input_awp_scan_mode"></a> [awp_scan_mode](#input\_awp\_scan\_mode) | The scan mode for the AWP `[ "inAccount" \| "saas" \| "inAccountHub" \| "inAccountSub"]`| `string` | "inAccount" | yes |
| <a name="input_awp_centralized_cloud_account_id"></a> [awp_centralized_cloud_account_id](#input\_awp\_centralized\_cloud\_account\_id) | The Id of the centralized Azure account | `string` | `null` | no |
| <a name="input_awp_is_scanned_hub"></a> [awp_is_scanned_hub](#input\_awp\_is\_scan\_hub) | Is the hub subscription also scanned by AWP | `bool` | `false` | no |
| <a name="input_management_group_id"></a> [management_group_id](#input\_management\_group\_id) | Management group ID | `string` | `null` | no |
|  [awp_account_settings_azure](#input\_awp\_account\_settings\_azure) | AWP Account settings for Azure | object | `null` | no |

<br/>

**<a name="input_awp_account_settings_azure"></a> [awp_account_settings_azure](#input\_awp\_account\_settings\_azure) variable is an object that contains the following attributes:**
| Name | Description | Type | Default | Valid Values |Required |
|------|-------------|------|---------|:--------:|:--------:|
| <a name="input_scan_machine_interval_in_hours"></a> [scan_machine_interval_in_hours](#input\_scan\_machine\_interval\_in\_hours) | Scan machine interval in hours | `number` | `24` | InAccount: `>=4`, SaaS: `>=24` | no |
| <a name="input_skip_function_apps_scan"></a> [skip_function_apps_scan](#input\_skip\_function\_apps\_scan) | Skip Azure Function Apps scan | `bool` | `false` | `true` or `false` | no |
| <a name="input_max_concurrent_scans_per_region"></a> [max_concurrent_scans_per_region](#input\_max\_concurrent\_scans\_per\_region) | Maximum concurrent scans per region | `number` | `20` | `1` - `20` | no |
| <a name="input_custom_tags"></a> [custom_tags](#input\_custom\_tags) | Custom tags to be added to AWP dynamic resources | `map(string)` | `{}` | `{"key" = "value", ...}` | no |
| <a name="input_disabled_regions"></a> [disabled_regions](#input\_disabled\_regions) | List of Azure regions to disable AWP scanning | `list(string)` | `[]` | `["eastus", ...]`| no |

<!-- BEGIN_TF_DOCS -->
## Resources

| Name | Type |
|------|------|
| [azurerm_resource_group.cloudguard](https://registry.terraform.io/providers/hashicorp/azurerm/3.99.0/docs/resources/resource_group) | resource |
| [azurerm_resource_group.cloudguard_sub](https://registry.terraform.io/providers/hashicorp/azurerm/3.99.0/docs/resources/resource_group) | resource |
| [azurerm_role_assignment.cloudguard_function_apps_scan_operator_assignment](https://registry.terraform.io/providers/hashicorp/azurerm/3.99.0/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.cloudguard_function_apps_scanner_assignment](https://registry.terraform.io/providers/hashicorp/azurerm/3.99.0/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.cloudguard_function_apps_scanner_assignment_sub](https://registry.terraform.io/providers/hashicorp/azurerm/3.99.0/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.cloudguard_vm_data_share_assignment](https://registry.terraform.io/providers/hashicorp/azurerm/3.99.0/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.cloudguard_vm_data_share_assignment_sub](https://registry.terraform.io/providers/hashicorp/azurerm/3.99.0/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.cloudguard_vm_scan_operator_assignment](https://registry.terraform.io/providers/hashicorp/azurerm/3.99.0/docs/resources/role_assignment) | resource |
| [azurerm_role_definition.cloudguard_function_apps_scan_operator](https://registry.terraform.io/providers/hashicorp/azurerm/3.99.0/docs/resources/role_definition) | resource |
| [azurerm_role_definition.cloudguard_function_apps_scanner](https://registry.terraform.io/providers/hashicorp/azurerm/3.99.0/docs/resources/role_definition) | resource |
| [azurerm_role_definition.cloudguard_vm_data_share](https://registry.terraform.io/providers/hashicorp/azurerm/3.99.0/docs/resources/role_definition) | resource |
| [azurerm_role_definition.cloudguard_vm_scan_operator](https://registry.terraform.io/providers/hashicorp/azurerm/3.99.0/docs/resources/role_definition) | resource |
| [azurerm_user_assigned_identity.cloudguard_identity](https://registry.terraform.io/providers/hashicorp/azurerm/3.99.0/docs/resources/user_assigned_identity) | resource |
| [dome9_awp_azure_onboarding.awp_azure_onboarding_resource](https://registry.terraform.io/providers/dome9/dome9/latest/docs/resources/awp_azure_onboarding) | resource |
| [time_sleep.wait_for_role_creation](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_get_azure_subscription_id"></a> [get\_azure\_subscription\_id](#output\_get\_azure\_subscription\_id) | n/a |
<!-- END_TF_DOCS -->

## FAQ & Troubleshooting
