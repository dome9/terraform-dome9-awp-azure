
# CloudGuard AWP (Azure) - Terraform Module

This Terraform module is designed to enable AWP (Agentless Workload Posture) on Azure Subscribtion.
(https://www.checkpoint.com/dome9/) 

This module use [Check Point CloudGuard Dome9 Provider](https://registry.terraform.io/providers/dome9/dome9/latest/docs)

## Prerequisites

- Azure Account onboarded to CloudGuard
- CloudGuard API Key and Secret ([CloudGuard Provider Authentication](https://registry.terraform.io/providers/dome9/dome9/latest/docs#authentication))
- Azure Credentials ([Azure Provider Authentication](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs#authenticating-to-azure)) (for more info follow: [AWP Documentation](https://sc1.checkpoint.com/documents/CloudGuard_Dome9/Documentation/Workload-Protection/AWP/AWP-Azure-SaaS-and-In-Account.htm))


## Usage

```hcl
module "terraform-dome9-awp-azure" {
  source = "dome9/awp-azure/dome9"

  # The Id of the Azure account, onboarded to CloudGuard (can be either the CloudGuard Cloud Account ID or the Azure subscription ID)
  awp_cloud_account_id = dome9_cloudaccount_azure.my_azure_cloud_account.id

  # The AWP scan mode. Possible values are "inAccount", "saas", "inAccountHub" or "inAccountSub".
  awp_scan_mode = "inAccount"

  # In case of centralized onboarding, this should be the account id (CloudGuard account id or Azure subscription id) of the centralized account
  awp_centralized_cloud_account_id = dome9_cloudaccount_azure.my_azure_centralized_account.id

  # Optional customizations:
  # e.g:
  management_group_id       = "management group id" # relevat only for inAccountHub mode
    

  # Optional account settings
  # e.g:  
  awp_account_settings_azure = {
    scan_machine_interval_in_hours  = 24
    skip_function_apps_scan         = false
    max_concurrent_scans_per_region = 20
    disabled_regions                = [] # e.g ["eastus", "westus"]
    in_account_scanner_vpc          = "ManagedByAWP" # e.g "ManagedByAWP" or "ManagedByCustomer"
    sse_cmk_encrypted_disks_scan    = false
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
| <a name="requirement_dome9"></a> [dome9](#requirement\_dome9) | >=1.35.9 |
| <a name="requirement_time"></a> [time](#requirement\_time) | 0.11.2 |
<!-- END_TF_HEADER_DOCS -->

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_awp_cloud_account_id"></a> [awp_cloud_account_id](#input\_awp\_cloud\_account\_id) | The Id of the Azure account, onboarded to CloudGuard (can be either the CloudGuard Cloud Account ID or the Azure subscription ID) | `string` | n/a | yes |
| <a name="input_awp_scan_mode"></a> [awp_scan_mode](#input\_awp\_scan\_mode) | The scan mode for the AWP `[ "inAccount" \| "saas" \| "inAccountHub" \| "inAccountSub"]`| `string` | "inAccount" | yes |
| <a name="input_awp_centralized_cloud_account_id"></a> [awp_centralized_cloud_account_id](#input\_awp\_centralized\_cloud\_account\_id) | The Id of the centralized Azure account | `string` | `null` | in case of inAccountSub scan mode |
| <a name="input_management_group_id"></a> [management_group_id](#input\_management\_group\_id) | Management group ID | `string` | `null` | no |
|  [awp_account_settings_azure](#input\_awp\_account\_settings\_azure) | AWP Account settings for Azure | object | `null` | no |

<br/>

**<a name="input_awp_account_settings_azure"></a> [awp_account_settings_azure](#input\_awp\_account\_settings\_azure) variable is an object that contains the following attributes:**
| Name | Description | Type | Default | Valid Values |Required |
|------|-------------|------|---------|:--------:|:--------:|
| <a name="input_scan_machine_interval_in_hours"></a> [scan_machine_interval_in_hours](#input\_scan\_machine\_interval\_in\_hours) | Scan machine interval in hours | `number` | `24` | InAccount: `>=4`, SaaS: `>=24` | no |
| <a name="input_skip_function_apps_scan"></a> [skip_function_apps_scan](#input\_skip\_function\_apps\_scan) | Skip Azure Function Apps scan | `bool` | `false` | `true` or `false` | no |
| <a name="input_max_concurrent_scans_per_region"></a> [max_concurrent_scans_per_region](#input\_max\_concurrent\_scans\_per\_region) | Maximum concurrent scans per region | `number` | `20` | `1` - `20` | no |
| <a name="input_in_account_scanner_vpc"></a> [in_account_scanner_vpc](#input\_in\_account\_scanner\_vpc) |  The VPC Mode | `string` | `ManagedByAWP` | `ManagedByAWP`,`ManagedByCustomer` | no |                
| <a name="input_custom_tags"></a> [custom_tags](#input\_custom\_tags) | Custom tags to be added to AWP resources that are created during the scan process | `map(string)` | `{}` | `{"key" = "value", ...}` | no |
| <a name="input_sse_cmk_encrypted_disks_scan"></a> [sse_cmk_encrypted_disks_scan](#input\_sse\_cmk\_encrypted\_disks\_scan) | Enable SSE CMK scanning | `bool` | `false` | `true` or `false` | no |
| <a name="input_disabled_regions"></a> [disabled_regions](#input\_disabled\_regions) | List of Azure regions to disable AWP scanning | `list(string)` | `[]` | `["eastus", ...]`| no |

<!-- BEGIN_TF_DOCS -->
## Resources

| Name | Type |
|------|------|
| [azurerm_resource_group.cloudguard](https://registry.terraform.io/providers/hashicorp/azurerm/3.99.0/docs/resources/resource_group) | resource |
| [azurerm_resource_group.cloudguard_sub](https://registry.terraform.io/providers/hashicorp/azurerm/3.99.0/docs/resources/resource_group) | resource |
| [azurerm_role_assignment.cloudguard_crypto_creator_assignment](https://registry.terraform.io/providers/hashicorp/azurerm/3.99.0/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.cloudguard_function_apps_scan_operator_assignment](https://registry.terraform.io/providers/hashicorp/azurerm/3.99.0/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.cloudguard_function_apps_scanner_assignment](https://registry.terraform.io/providers/hashicorp/azurerm/3.99.0/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.cloudguard_function_apps_scanner_assignment_sub](https://registry.terraform.io/providers/hashicorp/azurerm/3.99.0/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.cloudguard_vm_data_share_assignment](https://registry.terraform.io/providers/hashicorp/azurerm/3.99.0/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.cloudguard_vm_data_share_assignment_sub](https://registry.terraform.io/providers/hashicorp/azurerm/3.99.0/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.cloudguard_vm_scan_operator_assignment](https://registry.terraform.io/providers/hashicorp/azurerm/3.99.0/docs/resources/role_assignment) | resource |
| [azurerm_role_definition.cloudguard_crypto_creator](https://registry.terraform.io/providers/hashicorp/azurerm/3.99.0/docs/resources/role_definition) | resource |
| [azurerm_role_definition.cloudguard_disk_encryptor](https://registry.terraform.io/providers/hashicorp/azurerm/3.99.0/docs/resources/role_definition) | resource |
| [azurerm_role_definition.cloudguard_function_apps_scan_operator](https://registry.terraform.io/providers/hashicorp/azurerm/3.99.0/docs/resources/role_definition) | resource |
| [azurerm_role_definition.cloudguard_function_apps_scanner](https://registry.terraform.io/providers/hashicorp/azurerm/3.99.0/docs/resources/role_definition) | resource |
| [azurerm_role_definition.cloudguard_vm_data_share](https://registry.terraform.io/providers/hashicorp/azurerm/3.99.0/docs/resources/role_definition) | resource |
| [azurerm_role_definition.cloudguard_vm_scan_operator](https://registry.terraform.io/providers/hashicorp/azurerm/3.99.0/docs/resources/role_definition) | resource |
| [azurerm_user_assigned_identity.cloudguard_identity](https://registry.terraform.io/providers/hashicorp/azurerm/3.99.0/docs/resources/user_assigned_identity) | resource |
| [dome9_awp_azure_onboarding.awp_azure_onboarding_resource](https://registry.terraform.io/providers/dome9/dome9/latest/docs/resources/awp_azure_onboarding) | resource |
| [time_sleep.wait_for_crypto_creator_role_creation](https://registry.terraform.io/providers/hashicorp/time/0.11.2/docs/resources/sleep) | resource |
| [time_sleep.wait_for_function_apps_scan_operator_role_creation](https://registry.terraform.io/providers/hashicorp/time/0.11.2/docs/resources/sleep) | resource |
| [time_sleep.wait_for_function_apps_scanner_role_creation](https://registry.terraform.io/providers/hashicorp/time/0.11.2/docs/resources/sleep) | resource |
| [time_sleep.wait_for_vm_data_share_role_creation](https://registry.terraform.io/providers/hashicorp/time/0.11.2/docs/resources/sleep) | resource |
| [time_sleep.wait_for_vm_scan_operator_role_creation](https://registry.terraform.io/providers/hashicorp/time/0.11.2/docs/resources/sleep) | resource |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_agentless_protection_enabled"></a> [agentless\_protection\_enabled](#output\_agentless\_protection\_enabled) | AWP Status |
| <a name="output_azure_subscription_id"></a> [azure\_subscription\_id](#output\_azure\_subscription\_id) | Azure Subscription ID |
| <a name="output_cloud_account_id"></a> [cloud\_account\_id](#output\_cloud\_account\_id) | CloudGuard account ID |
| <a name="output_missing_awp_private_network_regions"></a> [missing\_awp\_private\_network\_regions](#output\_missing\_awp\_private\_network\_regions) | List of regions in which AWP has issue to create virtual private network (VPC) |
| <a name="output_should_update"></a> [should\_update](#output\_should\_update) | This module is out of date and should be updated to the latest version. |
<!-- END_TF_DOCS -->

## FAQ & Troubleshooting
### Centralized Offboarding with sse_cmk_encrypted_disks_scan Enabled

When performing centralized offboarding and sse_cmk_encrypted_disks_scan is enabled, you can delete AWP Keys manually.
If using only the Terraform offboarding, the keys will remain in a "soft delete" state for a retention period before being permanently deleted by Azure.

Steps:
1. Identify Key Vaults tagged with CG_AWP_OWNER=CG.AWP.
2. In those Key Vaults, locate and delete the keys tagged with CG_AWP_OWNER=CG.AWP.

This should be done before completing the offboarding process to prevent potential issues.


```