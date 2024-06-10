# 1. Provider Configuration

# The CloudGuard Dome9 provider is used to interact with the resources supported by Dome9.
# https://registry.terraform.io/providers/dome9/dome9/latest/docs#authentication
provider "dome9" {
  dome9_access_id  = "DOME9_ACCESS_ID"
  dome9_secret_key = "DOME9_SECRET_KEY"
  base_url         = "https://api.dome9.com/v2/"
}


# 2. Pre-requisite: Onborded Azure Account to CloudGuard Dome9
# [!NOTE] If the Azure account is already onboarded, you can skip this step.

# https://registry.terraform.io/providers/dome9/dome9/latest/docs/resources/cloudaccount_azure
 
 resource "dome9_cloudaccount_azure" "my_azure_cloud_account" {
   client_id       = "<AZURE_APP_CLIENT_ID>"
   client_password = "<AZURE_APP_PASSWORD>"
   name            = "My Azure account"
   operation_mode  = "Read"
   subscription_id = "<AZURE_SUBSCRIPTION_ID>"
   tenant_id       = "<AZURE_TENANT_ID>"
 }


/* ----- Module Usage ----- */

# 3. AWP Onboarding using the Dome9 AWP Azure module

module "terraform-dome9-awp-azure" {
  source               = "dome9/awp-azure/dome9"
  awp_cloud_account_id = dome9_cloudaccount_azure.my_azure_cloud_account.id # [<CLOUDGUARD_ACCOUNT_ID | <AZURE_SUBSCRIPTION_ID>]  
  awp_scan_mode        = "inAccount"                              # [inAccount | saas |inAccountHub | inAccountSub ]  
  awp_centralized_cloud_account_id = "CENTRALIZED_CLOUAD_ACCOUNT_ID OR AZURE_SUBSCRIPTION_ID" # relevat only for inAccountSub mode

  # Optional customizations:
  management_group_id       = "management group id" # relevat only for inAccountHub mode

  # Optional account Settings (supported only for inAccount and saas scan mode)
  # e.g:  
  awp_account_settings_azure = {
    scan_machine_interval_in_hours  = 24
    skip_function_apps_scan         = false
    disabled_regions                = [] # e.g ["eastus", "westus"]
    max_concurrent_scans_per_region = 20
    custom_tags = {
      tag1 = "value1"
      tag2 = "value2"
      tag3 = "value3"
    }
  }
}