
# The data source retrieves the onboarding data of an Azure account in Dome9 AWP.
data "dome9_awp_azure_onboarding_data" "dome9_awp_azure_onboarding_data_source" {
  cloud_account_id             = var.awp_cloud_account_id
  centralized_cloud_account_id = local.is_in_account_sub_scan_mode ? var.awp_centralized_cloud_account_id : null
}

data "azuread_service_principal" "my_service_principal" {
  client_id  = data.dome9_awp_azure_onboarding_data.dome9_awp_azure_onboarding_data_source.app_client_id
  
  depends_on = [
    data.dome9_awp_azure_onboarding_data.dome9_awp_azure_onboarding_data_source
  ]
}

# locals
locals {
  awp_module_version               = "3"
  scan_mode                        = var.awp_scan_mode
  awp_cloud_account_id             = data.dome9_awp_azure_onboarding_data.dome9_awp_azure_onboarding_data_source.awp_cloud_account_id
  app_object_id                    = data.azuread_service_principal.my_service_principal.id
  awp_centralized_cloud_account_id = local.is_in_account_sub_scan_mode ? data.dome9_awp_azure_onboarding_data.dome9_awp_azure_onboarding_data_source.awp_centralized_cloud_account_id : null
  awp_is_scanned_hub               = local.is_in_account_hub_scan_mode ? var.awp_is_scanned_hub : false # the default for hub subscription is not scanned
  awp_skip_function_app_scan       = local.is_in_account_hub_scan_mode ? false  : (local.is_saas_scan_mode ? true : (var.awp_account_settings_azure.skip_function_apps_scan != null && var.awp_account_settings_azure.skip_function_apps_scan != "" ? var.awp_account_settings_azure.skip_function_apps_scan : false))
  sse_cmk_scanning                 = local.is_in_account_hub_scan_mode && var.awp_account_settings_azure.sse_cmk_encrypted_disks_scan == true
  location                         = data.dome9_awp_azure_onboarding_data.dome9_awp_azure_onboarding_data_source.region # "westus"
  group_name                       = var.management_group_id != null ? var.management_group_id : data.dome9_cloudaccount_azure.azure_data_source.tenant_id

  is_saas_scan_mode               = local.scan_mode == "saas"
  is_in_account_scan_mode         = local.scan_mode == "inAccount"
  is_in_account_hub_scan_mode     = local.scan_mode == "inAccountHub"
  is_in_account_sub_scan_mode     = local.scan_mode == "inAccountSub"
  is_not_in_account_sub_scan_mode = local.scan_mode != "inAccountSub"

  is_in_account_or_hub_scan_mode_condition                            = local.is_in_account_scan_mode || local.is_in_account_hub_scan_mode
  is_in_account_or_hub_scan_mode_and_not_skipp_function_app_condition = (local.is_in_account_or_hub_scan_mode_condition) && !local.awp_skip_function_app_scan
  is_sub_or_scanned_hub_sacn_mode_condition                           = local.is_in_account_sub_scan_mode || (local.is_in_account_hub_scan_mode && local.awp_is_scanned_hub)
  
  awp_resource_group_name_prefix = "cloudguard-AWP"

  AWP_OWNER_TAG_KEY          = "CG_AWP_OWNER"
  AWP_OBSOLETE_OWNER_TAG_KEY = "Owner"
  AWP_OWNER_TAG_VALUE        = "CG.AWP"

  common_tags = merge({
    "Owner"              = "${local.AWP_OWNER_TAG_VALUE}"
    "CG_AWP_OWNER"       = "${local.AWP_OWNER_TAG_VALUE}"
    "CloudGuard.AWP.Version"  = local.awp_module_version
}, var.awp_additional_tags != null ? var.awp_additional_tags : {})

}

data "dome9_cloudaccount_azure" "azure_data_source" {
  id = local.is_in_account_sub_scan_mode ? local.awp_centralized_cloud_account_id : local.awp_cloud_account_id
}

data "dome9_cloudaccount_azure" "azure_data_source_sub" {
  count = local.is_in_account_sub_scan_mode ? 1 : 0
  id    = local.awp_cloud_account_id
}

# Provider block for the azure account
provider "azurerm" {
  skip_provider_registration = true
  alias                      = "azure_resource_manager"
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  subscription_id            = data.dome9_cloudaccount_azure.azure_data_source.subscription_id
}

# Define the resource group where CloudGuard resources will be deployed
resource "azurerm_resource_group" "cloudguard" {
  count     = local.is_in_account_or_hub_scan_mode_condition ? 1 : 0
  provider  = azurerm.azure_resource_manager
  name      = local.awp_resource_group_name_prefix
  location  = local.location
  tags = local.common_tags
}

# Define the resource group where CloudGuard resources will be deployed for sub account or scanned hub
resource "azurerm_resource_group" "cloudguard_sub" {
  count     = local.is_sub_or_scanned_hub_sacn_mode_condition ? 1 : 0                           
  provider  = azurerm.azure_resource_manager
  name      = "${local.awp_resource_group_name_prefix}_${local.is_in_account_sub_scan_mode ? data.dome9_cloudaccount_azure.azure_data_source_sub[count.index].subscription_id : data.dome9_cloudaccount_azure.azure_data_source.subscription_id}"
  location  = local.location
  tags = local.common_tags
}

# Define custom roles based on scan mode
resource "azurerm_role_definition" "cloudguard_vm_data_share" {
  count         = local.is_not_in_account_sub_scan_mode ? 1 : 0
  provider      = azurerm.azure_resource_manager
  name          = "CloudGuard AWP VM Data Share ${data.dome9_cloudaccount_azure.azure_data_source.subscription_id}"
  description   = "Grants needed permissions for CloudGuard app registration to read VMs data (version: ${local.awp_module_version})"
  scope         = local.is_in_account_scan_mode || local.is_saas_scan_mode ? "/subscriptions/${data.dome9_cloudaccount_azure.azure_data_source.subscription_id}" : "/providers/Microsoft.Management/managementGroups/${local.group_name}"
  permissions {
    actions     = [
    "Microsoft.Compute/disks/beginGetAccess/action",
    "Microsoft.Compute/virtualMachines/read"
  ]
    not_actions = []
  }
}

resource "time_sleep" "wait_for_vm_data_share_role_creation" {
  count           = local.is_not_in_account_sub_scan_mode ? 1 : 0
  depends_on      = [azurerm_role_definition.cloudguard_vm_data_share]
  create_duration = "30s"
}


resource "azurerm_role_definition" "cloudguard_vm_scan_operator" {
  count         = local.is_in_account_or_hub_scan_mode_condition ? 1 : 0
  provider      = azurerm.azure_resource_manager
  name          = "CloudGuard AWP VM Scan Operator ${data.dome9_cloudaccount_azure.azure_data_source.subscription_id}"
  scope         = "/subscriptions/${data.dome9_cloudaccount_azure.azure_data_source.subscription_id}"
  description   = "Grants all needed permissions for CloudGuard app registration to scan VMs (version: ${local.awp_module_version})"

  permissions {
    actions     = [
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
      "Microsoft.Network/networkInterfaces/delete",
      "Microsoft.Compute/virtualMachines/write",
      "Microsoft.Compute/virtualMachines/delete",
      "Microsoft.Network/networkSecurityGroups/write",
      "Microsoft.Network/networkSecurityGroups/join/action",
      "Microsoft.Network/virtualNetworks/write",
      "Microsoft.Network/virtualNetworks/delete",
      "Microsoft.Network/virtualNetworks/subnets/delete",
      "Microsoft.Network/virtualNetworks/subnets/join/action",
      "Microsoft.Resources/subscriptions/resourceGroups/read",
      "Microsoft.Resources/subscriptions/resourceGroups/write",
      "Microsoft.Network/networkSecurityGroups/delete"
    ]
    not_actions = []
  }
}

resource "azurerm_role_definition" "cloudguard_crypto_creator" {
  count         = local.sse_cmk_scanning ? 1 : 0
  provider      = azurerm.azure_resource_manager
  name          = "CloudGuard AWP Crypto Resources Creator ${data.dome9_cloudaccount_azure.azure_data_source.subscription_id}"
  scope         = "/subscriptions/${data.dome9_cloudaccount_azure.azure_data_source.subscription_id}"
  description   = "Grants all needed permissions for CloudGuard app registration to create crypto resources required for disk encryption with CMK (version: ${local.awp_module_version})"

  permissions {
    actions     = [
      "Microsoft.KeyVault/*",
      "Microsoft.Compute/diskEncryptionSets/write",
      "Microsoft.Compute/diskEncryptionSets/delete",
      "Microsoft.Authorization/roleAssignments/write"
    ]
    not_actions = []
    data_actions = [
      "Microsoft.KeyVault/vaults/keys/delete"
    ]
    not_data_actions = []
  }
}

resource "time_sleep" "wait_for_crypto_creator_role_creation" {
  count           = local.sse_cmk_scanning ? 1 : 0
  depends_on      = [azurerm_role_definition.cloudguard_crypto_creator]
  create_duration = "30s"
}

resource "azurerm_role_definition" "cloudguard_disk_encryptor" {
  count         = local.sse_cmk_scanning ? 1 : 0
  provider      = azurerm.azure_resource_manager
  name          = "CloudGuard AWP Disk Encryptor ${data.dome9_cloudaccount_azure.azure_data_source.subscription_id}"
  scope         = "/subscriptions/${data.dome9_cloudaccount_azure.azure_data_source.subscription_id}"
  description   = "Grants all needed permissions for CloudGuard AWP's generated DES to access AWP generated key vault (version: ${local.awp_module_version})"

  permissions {
    actions     = [
      "Microsoft.EventGrid/eventSubscriptions/write",
      "Microsoft.EventGrid/eventSubscriptions/read",
      "Microsoft.EventGrid/eventSubscriptions/delete"
    ]
    not_actions = []
    data_actions = [
      "Microsoft.KeyVault/vaults/keys/read",
      "Microsoft.KeyVault/vaults/keys/wrap/action",
      "Microsoft.KeyVault/vaults/keys/unwrap/action"
    ]
    not_data_actions = []
  }
}


resource "time_sleep" "wait_for_vm_scan_operator_role_creation" {
  count           = local.is_in_account_or_hub_scan_mode_condition ? 1 : 0
  depends_on      = [azurerm_role_definition.cloudguard_vm_scan_operator]
  create_duration = "30s"
}

resource "azurerm_role_definition" "cloudguard_function_apps_scanner" {
  count         = local.is_in_account_or_hub_scan_mode_and_not_skipp_function_app_condition ? 1 : 0
  provider      = azurerm.azure_resource_manager
  name          = "CloudGuard AWP Function Apps Scanner ${data.dome9_cloudaccount_azure.azure_data_source.subscription_id}"
  description   = "Grants needed permissions for CloudGuard AWP function-apps scanner (version: ${local.awp_module_version})"
  scope         = local.is_in_account_scan_mode ? "/subscriptions/${data.dome9_cloudaccount_azure.azure_data_source.subscription_id}" : "/providers/Microsoft.Management/managementGroups/${local.group_name}"
  permissions {
    actions     = [
    "Microsoft.Web/sites/publish/Action",
    "Microsoft.Web/sites/config/list/Action",
    "microsoft.web/sites/functions/read"
  ]
    not_actions = []
  }
}

resource "time_sleep" "wait_for_function_apps_scanner_role_creation" {
  count           = local.is_in_account_or_hub_scan_mode_and_not_skipp_function_app_condition ? 1 : 0
  depends_on      = [azurerm_role_definition.cloudguard_function_apps_scanner]
  create_duration = "30s"
}

resource "azurerm_role_definition" "cloudguard_function_apps_scan_operator" {
  count         = local.is_in_account_or_hub_scan_mode_and_not_skipp_function_app_condition ? 1 : 0
  provider      = azurerm.azure_resource_manager
  name          = "CloudGuard AWP FunctionApp Scan Operator ${data.dome9_cloudaccount_azure.azure_data_source.subscription_id}"
  description   = "Grants all needed permissions for CloudGuard app registration to scan function-apps (version: ${local.awp_module_version})"
  scope         = "/subscriptions/${data.dome9_cloudaccount_azure.azure_data_source.subscription_id}"
  permissions {
    actions     = [
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
    not_actions = []
  }
}

resource "time_sleep" "wait_for_function_apps_scan_operator_role_creation" {
  count           = local.is_in_account_or_hub_scan_mode_and_not_skipp_function_app_condition ? 1 : 0
  depends_on      = [azurerm_role_definition.cloudguard_function_apps_scan_operator]
  create_duration = "30s"
}

# END Define custom roles based on scan mode

# Define the managed identity for CloudGuard AWP
resource "azurerm_user_assigned_identity" "cloudguard_identity" {
  count               = local.is_in_account_or_hub_scan_mode_and_not_skipp_function_app_condition ? 1 : 0
  provider            = azurerm.azure_resource_manager
  name                = "CloudGuardAWPScannerManagedIdentity"
  location            = azurerm_resource_group.cloudguard[count.index].location
  resource_group_name = azurerm_resource_group.cloudguard[count.index].name
  tags                = local.common_tags

  depends_on = [
    azurerm_resource_group.cloudguard
  ]
}

data "azurerm_user_assigned_identity" "cloudguard_identity_data_sub" {
  count               = local.is_in_account_sub_scan_mode ? 1 : 0
  provider            = azurerm.azure_resource_manager
  name                = "CloudGuardAWPScannerManagedIdentity"
  resource_group_name = local.awp_resource_group_name_prefix
}

# Assign custom roles based on scan mode
resource "azurerm_role_assignment" "cloudguard_vm_data_share_assignment" {
  count                = local.is_not_in_account_sub_scan_mode ? 1 : 0
  provider             = azurerm.azure_resource_manager
  scope                = "/subscriptions/${data.dome9_cloudaccount_azure.azure_data_source.subscription_id}"
  role_definition_name = azurerm_role_definition.cloudguard_vm_data_share[count.index].name
  principal_id         = local.app_object_id

  lifecycle {
    create_before_destroy = false
    replace_triggered_by  = [azurerm_role_definition.cloudguard_vm_data_share]
  }

  depends_on = [
    time_sleep.wait_for_vm_data_share_role_creation
  ]
}


resource "azurerm_role_assignment" "cloudguard_vm_data_share_assignment_sub" {
  count                = local.is_in_account_sub_scan_mode ? 1 : 0
  provider             = azurerm.azure_resource_manager
  scope                = "/subscriptions/${data.dome9_cloudaccount_azure.azure_data_source_sub[count.index].subscription_id}"
  role_definition_name = "CloudGuard AWP VM Data Share ${data.dome9_cloudaccount_azure.azure_data_source.subscription_id}"
  principal_id         = local.app_object_id
  depends_on = [
    azurerm_role_definition.cloudguard_vm_data_share
  ]
}

resource "azurerm_role_assignment" "cloudguard_vm_scan_operator_assignment" {
  count                = local.is_in_account_or_hub_scan_mode_condition ? 1 : 0
  provider             = azurerm.azure_resource_manager
  scope                = "/subscriptions/${data.dome9_cloudaccount_azure.azure_data_source.subscription_id}"
  role_definition_name = azurerm_role_definition.cloudguard_vm_scan_operator[count.index].name
  principal_id         = local.app_object_id
 
  depends_on = [
    time_sleep.wait_for_vm_scan_operator_role_creation
  ]
}

resource "azurerm_role_assignment" "cloudguard_crypto_creator_assignment" {
  count                = local.sse_cmk_scanning ? 1 : 0
  provider             = azurerm.azure_resource_manager
  scope                = "/subscriptions/${data.dome9_cloudaccount_azure.azure_data_source.subscription_id}"
  role_definition_name = azurerm_role_definition.cloudguard_crypto_creator[count.index].name
  principal_id         = local.app_object_id

  depends_on = [
    time_sleep.wait_for_crypto_creator_role_creation
  ]
}

resource "azurerm_role_assignment" "cloudguard_function_apps_scanner_assignment" {
  count                = local.is_in_account_or_hub_scan_mode_and_not_skipp_function_app_condition ? 1 : 0
  provider             = azurerm.azure_resource_manager
  scope                = "/subscriptions/${data.dome9_cloudaccount_azure.azure_data_source.subscription_id}"
  role_definition_name = azurerm_role_definition.cloudguard_function_apps_scanner[count.index].name
  principal_id         = azurerm_user_assigned_identity.cloudguard_identity[count.index].principal_id
 
   lifecycle {
    create_before_destroy = false
    replace_triggered_by  = [azurerm_role_definition.cloudguard_function_apps_scanner]
  }

  depends_on = [
    time_sleep.wait_for_function_apps_scanner_role_creation
  ]
}

resource "azurerm_role_assignment" "cloudguard_function_apps_scanner_assignment_sub" {
  count                = local.is_in_account_sub_scan_mode && !local.awp_skip_function_app_scan ? 1 : 0
  provider             = azurerm.azure_resource_manager
  scope                = "/subscriptions/${data.dome9_cloudaccount_azure.azure_data_source_sub[count.index].subscription_id}"
  role_definition_name = "CloudGuard AWP Function Apps Scanner ${data.dome9_cloudaccount_azure.azure_data_source.subscription_id}"
  principal_id         = data.azurerm_user_assigned_identity.cloudguard_identity_data_sub[count.index].principal_id

  depends_on = [
    time_sleep.wait_for_function_apps_scanner_role_creation
  ]
}

resource "azurerm_role_assignment" "cloudguard_function_apps_scan_operator_assignment" {
  count                = local.is_in_account_or_hub_scan_mode_and_not_skipp_function_app_condition ? 1 : 0
  provider             = azurerm.azure_resource_manager
  scope                = "/subscriptions/${data.dome9_cloudaccount_azure.azure_data_source.subscription_id}"
  role_definition_name = azurerm_role_definition.cloudguard_function_apps_scan_operator[count.index].name
  principal_id         = local.app_object_id
 
  depends_on = [
    time_sleep.wait_for_function_apps_scan_operator_role_creation
  ]
}

resource "null_resource" "delete_awp_keys" {
  count = local.is_in_account_hub_scan_mode ? 1 : 0

  triggers = {
    trigger = uuid()
    subscription_id = data.dome9_cloudaccount_azure.azure_data_source.subscription_id
    obsolete_owner_tag_key = local.AWP_OBSOLETE_OWNER_TAG_KEY
    owner_tag_key = local.AWP_OWNER_TAG_KEY
    owner_tag_value = local.AWP_OWNER_TAG_VALUE
  }

  provisioner "local-exec" {
    when    = destroy
    command = "chmod +x ${path.module}/delete_awp_keys.sh; ${path.module}/delete_awp_keys.sh ${self.triggers.subscription_id} ${self.triggers.obsolete_owner_tag_key} ${self.triggers.owner_tag_key} ${self.triggers.owner_tag_value}"
  }
  lifecycle {
    create_before_destroy = false
  }
}
# END Assign custom roles based on scan mode


# ----- Enable CloudGuard AWP Azure Onboarding -----
resource "dome9_awp_azure_onboarding" "awp_azure_onboarding_resource" {
  cloudguard_account_id          = var.awp_cloud_account_id
  scan_mode                      = local.scan_mode
  centralized_cloud_account_id   = local.awp_centralized_cloud_account_id
  management_group_id            = var.management_group_id
  
  dynamic "agentless_account_settings" {
    for_each = var.awp_account_settings_azure != null ? [var.awp_account_settings_azure] : []
    content {
      disabled_regions                 = agentless_account_settings.value.disabled_regions
      scan_machine_interval_in_hours   = agentless_account_settings.value.scan_machine_interval_in_hours
      max_concurrent_scans_per_region  = agentless_account_settings.value.max_concurrent_scans_per_region
      custom_tags                      = agentless_account_settings.value.custom_tags
      in_account_scanner_vpc           = agentless_account_settings.value.in_account_scanner_vpc
      sse_cmk_encrypted_disks_scan     = agentless_account_settings.value.sse_cmk_encrypted_disks_scan
      skip_function_apps_scan          = local.awp_skip_function_app_scan
    }
  }

    depends_on = [
    azurerm_resource_group.cloudguard,
    azurerm_resource_group.cloudguard_sub,  
    azurerm_role_definition.cloudguard_vm_data_share,
    azurerm_role_definition.cloudguard_vm_scan_operator,
    azurerm_role_definition.cloudguard_function_apps_scanner,
    azurerm_role_definition.cloudguard_function_apps_scan_operator,
    azurerm_role_assignment.cloudguard_function_apps_scan_operator_assignment,
    azurerm_role_assignment.cloudguard_function_apps_scanner_assignment,
    azurerm_role_assignment.cloudguard_function_apps_scanner_assignment_sub,
    azurerm_role_assignment.cloudguard_vm_data_share_assignment,
    azurerm_role_assignment.cloudguard_vm_data_share_assignment_sub,
    azurerm_role_assignment.cloudguard_vm_scan_operator_assignment
  ]
}
