
# CloudGuard AWP (Azure) - Terraform Module

This Terraform module is designed to onboard Azure Subscribtion to Dome9 AWP (Agentless Workload Posture) service.
(https://www.checkpoint.com/dome9/) 

This module use [Check Point CloudGuard Dome9 Provider](https://registry.terraform.io/providers/dome9/dome9/latest/docs)

## Prerequisites


## Usage


## Examples


## AWP Terraform template


<!-- BEGIN_TF_HEADER_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | 3.99.0 |
| <a name="requirement_dome9"></a> [dome9](#requirement\_dome9) | >=1.29.7 |
<!-- END_TF_HEADER_DOCS -->

## Inputs


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

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_app_object_id"></a> [app\_object\_id](#output\_app\_object\_id) | n/a |
| <a name="output_get_azure_subscription_id"></a> [get\_azure\_subscription\_id](#output\_get\_azure\_subscription\_id) | n/a |
<!-- END_TF_DOCS -->

## FAQ & Troubleshooting
