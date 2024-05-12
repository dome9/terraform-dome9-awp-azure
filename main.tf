data "external" "get_application_id" {
  program = ["bash", "-c", "az ad sp show --id ${"data.?"} --query '{appId: id}' --output json"]
}

# locals
locals {
  awp_module_version = "2"
  scan_mode = var.awp_scan_mode
  awp_cloud_account_id = "data.?"
  app_object_id = data.external.get_application_id.result["appId"]
  awp_centralized_cloud_account_id = "data.?"
  awp_is_scanned_hub = var.awp_is_scanned_hub # the default for hub subscription is not scanned
  awp_skip_function_app_scan = var.awp_skip_function_app_scan
  location = "data.?" # "West US"
  
  # Constants
  SCAN_MODE_SAAS = "saas"
  SCAN_MODE_IN_ACCOUNT = "inAccount"
  SCAN_MODE_IN_ACCOUNT_SUB = "inAccountSub"
  SCAN_MODE_IN_ACCOUNT_HUB = "inAccountHub"

  AWP_VM_OP_ROLE_NAME_PREFIX = "CloudGuard AWP VM Scan Operator"
  AWP_VM_SCAN_OPERATOR_ROLE_DESCRIPTION = "Grants all needed permissions for CloudGuard app registration to scan VMs (version: ${local.awp_module_version})"
  AWP_VM_SCAN_OPERATOR_ROLE_ACTIONS = [
    "Microsoft.Compute/disks/read",
    "Microsoft.Compute/disks/write",
    "Microsoft.Compute/disks/delete",
    "Microsoft.Compute/disks/beginGetAccess/action",
    "Microsoft.Compute/snapshots/read",
    "Microsoft.Compute/snapshots/write",
    "Microsoft.Compute/snapshots/delete",
    "Microsoft.Compute/snapshots/beginGetAccess/action",
    "Microsoft.Compute/snapshots/endGetAccess/action",
    "Microsoft.Network/networkInterfaces/join/action",
    "Microsoft.Network/networkInterfaces/write",
    "Microsoft.Compute/virtualMachines/write",
    "Microsoft.Compute/virtualMachines/delete",
    "Microsoft.Network/networkSecurityGroups/write",
    "Microsoft.Network/networkSecurityGroups/join/action",
    "Microsoft.Network/virtualNetworks/write",
    "Microsoft.Network/virtualNetworks/subnets/join/action",
    "Microsoft.Resources/subscriptions/resourceGroups/read",
    "Microsoft.Resources/subscriptions/resourceGroups/write"
  ]

  AWP_VM_DATA_SHARE_ROLE_NAME_PREFIX = "CloudGuard AWP VM Data Share"
  AWP_VM_DATA_SHARE_ROLE_DESCRIPTION = "Grants needed permissions for CloudGuard app registration to read VMs data (version: ${local.awp_module_version})"
  AWP_VM_DATA_SHARE_ROLE_ACTIONS = [
    "Microsoft.Compute/disks/beginGetAccess/action",
    "Microsoft.Compute/virtualMachines/read"
  ]

  AWP_FA_MANAGED_IDENTITY_NAME = "CloudGuardAWPScannerManagedIdentity"

  AWP_FA_SCANNER_ROLE_NAME_PREFIX = "CloudGuard AWP Function Apps Scanner"
  AWP_FA_SCANNER_ROLE_DESCRIPTION = "Grants needed permissions for CloudGuard AWP function-apps scanner (version: ${local.awp_module_version})"
  AWP_FA_SCANNER_ROLE_ACTIONS = [
    "Microsoft.Web/sites/publish/Action",
    "Microsoft.Web/sites/config/list/Action",
    "microsoft.web/sites/functions/read"
  ]

  AWP_FA_SCAN_OPERATOR_ROLE_NAME_PREFIX = "CloudGuard AWP FunctionApp Scan Operator"
  AWP_FA_SCAN_OPERATOR_ROLE_DESCRIPTION = "Grants all needed permissions for CloudGuard app registration to scan function-apps (version: ${local.awp_module_version})"

  AWP_FA_SCAN_OPERATOR_ROLE_ACTIONS = [
    "Microsoft.Compute/virtualMachines/write",
    "Microsoft.Compute/virtualMachines/extensions/write",
    "Microsoft.Network/networkSecurityGroups/write",
    "Microsoft.Network/networkSecurityGroups/join/action",
    "Microsoft.Network/virtualNetworks/write",
    "Microsoft.Network/virtualNetworks/subnets/join/action",
    "Microsoft.ManagedIdentity/userAssignedIdentities/assign/action",
    "Microsoft.Resources/subscriptions/resourceGroups/read",
    "Microsoft.Resources/subscriptions/resourceGroups/write"
  ]

  AWP_RESOURCE_GROUP_NAME_PREFIX = "cloudguard-AWP"
  AWP_OWNER_TAG = "Owner=CG.AWP"
  AWP_VERSION_TAG = "CloudGuard.AWP.Version=${local.awp_module_version}"
}

data "dome9_cloudaccount_azure" "azure_ds" {
  id = local.scan_mode == local.SCAN_MODE_IN_ACCOUNT_SUB ? local.awp_centralized_cloud_account_id : local.awp_cloud_account_id
}

data "dome9_cloudaccount_azure" "azure_ds_sub" {
  count = local.scan_mode == local.SCAN_MODE_IN_ACCOUNT_SUB ? 1: 0
  id = local.awp_cloud_account_id
}

# Provider block for the scanner account
provider "azurerm" {
  skip_provider_registration = true
  alias   = "scanner"
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  subscription_id = data.dome9_cloudaccount_azure.azure_ds.subscription_id
}

# Data source to retrieve information about the current scanner account Azure subscription
data "azurerm_subscription" "scanner" {
  provider = azurerm.scanner
}

# Data source to retrieve information about the current scanner account Azure client config
data "azurerm_client_config" "scanner-client-config" {
  provider = azurerm.scanner
}

# Define the resource group where CloudGuard resources will be deployed
resource "azurerm_resource_group" "cloudguard" {
  count = local.scan_mode == local.SCAN_MODE_IN_ACCOUNT || local.scan_mode == local.SCAN_MODE_IN_ACCOUNT_HUB ? 1 : 0
  provider = azurerm.scanner
  name     = local.AWP_RESOURCE_GROUP_NAME_PREFIX
  location = local.location
  tags     = {
    Owner   = local.AWP_OWNER_TAG
    Version = local.AWP_VERSION_TAG
  }
}

# Define the resource group where CloudGuard resources will be deployed for sub account
resource "azurerm_resource_group" "cloudguard_sub" {
  count = local.scan_mode == local.SCAN_MODE_IN_ACCOUNT_SUB || (local.scan_mode == local.SCAN_MODE_IN_ACCOUNT_HUB && local.awp_is_scanned_hub )? 1 : 0
  provider = azurerm.scanner
  name     = "${local.AWP_RESOURCE_GROUP_NAME_PREFIX}_${local.scan_mode == local.SCAN_MODE_IN_ACCOUNT_SUB ? data.dome9_cloudaccount_azure.azure_ds_sub[count.index].subscription_id : data.azurerm_subscription.scanner.subscription_id}"
  location = local.location
  tags     = {
    Owner   = local.AWP_OWNER_TAG
    Version = local.AWP_VERSION_TAG
  }
}

# Define custom roles based on scan mode
resource "azurerm_role_definition" "cloudguard_vm_data_share" {
  count           = local.scan_mode != local.SCAN_MODE_IN_ACCOUNT_SUB ? 1 : 0
  provider = azurerm.scanner
  name            = "${local.AWP_VM_DATA_SHARE_ROLE_NAME_PREFIX} ${data.azurerm_subscription.scanner.subscription_id}" 
  description = local.AWP_VM_DATA_SHARE_ROLE_DESCRIPTION
  scope           = local.scan_mode == local.SCAN_MODE_IN_ACCOUNT || local.scan_mode == local.SCAN_MODE_SAAS ? "/subscriptions/${data.azurerm_subscription.scanner.subscription_id}" : "/providers/Microsoft.Management/managementGroups/${data.azurerm_subscription.scanner.tenant_id}"
  permissions {
    actions     = local.AWP_VM_DATA_SHARE_ROLE_ACTIONS
    not_actions = []
  }
}

resource "azurerm_role_definition" "cloudguard_vm_scan_operator" {
  count           = local.scan_mode == local.SCAN_MODE_IN_ACCOUNT || local.scan_mode == local.SCAN_MODE_IN_ACCOUNT_HUB ? 1 : 0
  provider        = azurerm.scanner
  name            = "${local.AWP_VM_OP_ROLE_NAME_PREFIX} ${data.azurerm_subscription.scanner.subscription_id}"
  scope           = "/subscriptions/${data.azurerm_subscription.scanner.subscription_id}"
  description     = local.AWP_VM_SCAN_OPERATOR_ROLE_DESCRIPTION

  permissions {
    actions     = local.AWP_VM_SCAN_OPERATOR_ROLE_ACTIONS
    not_actions = []
  }
}


resource "azurerm_role_definition" "cloudguard_function_apps_scanner" {
  count           = (local.scan_mode == local.SCAN_MODE_IN_ACCOUNT || local.scan_mode == local.SCAN_MODE_IN_ACCOUNT_HUB)  && !local.awp_skip_function_app_scan ? 1 : 0
  provider = azurerm.scanner
  name            = "${local.AWP_FA_SCANNER_ROLE_NAME_PREFIX} ${data.azurerm_subscription.scanner.subscription_id}"
  description = local.AWP_FA_SCANNER_ROLE_DESCRIPTION
  scope           = local.scan_mode == local.SCAN_MODE_IN_ACCOUNT ? "/subscriptions/${data.azurerm_subscription.scanner.subscription_id}" : "/providers/Microsoft.Management/managementGroups/${data.azurerm_subscription.scanner.tenant_id}"
  permissions {
    actions     = local.AWP_FA_SCANNER_ROLE_ACTIONS
    not_actions = []
  }
}

resource "azurerm_role_definition" "cloudguard_function_apps_scan_operator" {
  count           = (local.scan_mode == local.SCAN_MODE_IN_ACCOUNT || local.scan_mode == local.SCAN_MODE_IN_ACCOUNT_HUB)  && !local.awp_skip_function_app_scan ? 1 : 0
  provider = azurerm.scanner
  name            = "${local.AWP_FA_SCAN_OPERATOR_ROLE_NAME_PREFIX} ${data.azurerm_subscription.scanner.subscription_id}"
  description = local.AWP_FA_SCAN_OPERATOR_ROLE_DESCRIPTION
  scope           = "/subscriptions/${data.azurerm_subscription.scanner.subscription_id}"
  permissions {
    actions     = local.AWP_FA_SCAN_OPERATOR_ROLE_ACTIONS
    not_actions = []
  }
}
# END Define custom roles based on scan mode

# Define the managed identity for CloudGuard AWP
resource "azurerm_user_assigned_identity" "cloudguard_identity" {
  count    = (local.scan_mode == local.SCAN_MODE_IN_ACCOUNT || local.scan_mode == local.SCAN_MODE_IN_ACCOUNT_HUB) && !local.awp_skip_function_app_scan ? 1 : 0
  provider = azurerm.scanner
  name     = local.AWP_FA_MANAGED_IDENTITY_NAME
  location = azurerm_resource_group.cloudguard[count.index].location
  resource_group_name = azurerm_resource_group.cloudguard[count.index].name
    depends_on = [
      azurerm_resource_group.cloudguard
  ]
}

data "azurerm_user_assigned_identity" "cloudguard_identity_data" {
  count               = local.scan_mode == local.SCAN_MODE_IN_ACCOUNT_SUB ? 1 : 0
  provider            = azurerm.scanner
  name                = local.AWP_FA_MANAGED_IDENTITY_NAME
  resource_group_name = local.AWP_RESOURCE_GROUP_NAME_PREFIX
}

# Assign custom roles based on scan mode
resource "azurerm_role_assignment" "cloudguard_vm_data_share_assignment" {
  count                = local.scan_mode != local.SCAN_MODE_IN_ACCOUNT_SUB ? 1 : 0
  provider             = azurerm.scanner
  scope                = "/subscriptions/${data.azurerm_subscription.scanner.subscription_id}"
  role_definition_name = azurerm_role_definition.cloudguard_vm_data_share[count.index].name
  principal_id         = local.app_object_id
  
  depends_on = [
    azurerm_role_definition.cloudguard_vm_data_share
  ]
}


resource "azurerm_role_assignment" "cloudguard_vm_data_share_assignment_sub" {
  count           = local.scan_mode == local.SCAN_MODE_IN_ACCOUNT_SUB ? 1 : 0
  provider        = azurerm.scanner
  scope           = "/subscriptions/${data.dome9_cloudaccount_azure.azure_ds_sub[count.index].subscription_id}"
  role_definition_name = "${local.AWP_VM_DATA_SHARE_ROLE_NAME_PREFIX} ${data.azurerm_subscription.scanner.subscription_id}"
  principal_id    = local.app_object_id
      depends_on = [
      azurerm_role_definition.cloudguard_vm_data_share
  ]
}

resource "azurerm_role_assignment" "cloudguard_vm_scan_operator_assignment" {
  count           = local.scan_mode == local.SCAN_MODE_IN_ACCOUNT || local.scan_mode == local.SCAN_MODE_IN_ACCOUNT_HUB ? 1 : 0
  provider = azurerm.scanner
  scope           = "/subscriptions/${data.azurerm_subscription.scanner.subscription_id}"
  role_definition_name = azurerm_role_definition.cloudguard_vm_scan_operator[count.index].name
  principal_id    = local.app_object_id
      depends_on = [
      azurerm_role_definition.cloudguard_vm_scan_operator
  ]
}


resource "azurerm_role_assignment" "cloudguard_function_apps_scanner_assignment" {
  count           = (local.scan_mode == local.SCAN_MODE_IN_ACCOUNT || local.scan_mode == local.SCAN_MODE_IN_ACCOUNT_HUB) && !local.awp_skip_function_app_scan ? 1 : 0
  provider        = azurerm.scanner
  scope           = "/subscriptions/${data.azurerm_subscription.scanner.subscription_id}"
  role_definition_name = azurerm_role_definition.cloudguard_function_apps_scanner[count.index].name
  principal_id     = azurerm_user_assigned_identity.cloudguard_identity[count.index].principal_id
      depends_on = [
      azurerm_role_definition.cloudguard_function_apps_scanner
  ]
}

resource "azurerm_role_assignment" "cloudguard_function_apps_scanner_assignment_sub" {
  count           = local.scan_mode == local.SCAN_MODE_IN_ACCOUNT_SUB  && !local.awp_skip_function_app_scan ? 1 : 0
  provider        = azurerm.scanner
  scope           = "/subscriptions/${data.dome9_cloudaccount_azure.azure_ds_sub[count.index].subscription_id}"
  role_definition_name = "${local.AWP_FA_SCANNER_ROLE_NAME_PREFIX} ${data.azurerm_subscription.scanner.subscription_id}"
  principal_id     = data.azurerm_user_assigned_identity.cloudguard_identity_data[count.index].principal_id
      depends_on = [
      azurerm_role_definition.cloudguard_function_apps_scanner
  ]
}

resource "azurerm_role_assignment" "cloudguard_function_apps_scan_operator_assignment" {
  count           = (local.scan_mode == local.SCAN_MODE_IN_ACCOUNT || local.scan_mode == local.SCAN_MODE_IN_ACCOUNT_HUB) && !local.awp_skip_function_app_scan ? 1 : 0
  provider = azurerm.scanner
  scope           = "/subscriptions/${data.azurerm_subscription.scanner.subscription_id}"
  role_definition_name = azurerm_role_definition.cloudguard_function_apps_scan_operator[count.index].name
  principal_id    = local.app_object_id
      depends_on = [
        azurerm_role_definition.cloudguard_function_apps_scan_operator
    ]
}
# END Assign custom roles based on scan mode
