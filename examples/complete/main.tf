# 1. Provider Configuration

# The CloudGuard Dome9 provider is used to interact with the resources supported by Dome9.
# https://registry.terraform.io/providers/dome9/dome9/latest/docs#authentication
provider "dome9" {
  dome9_access_id  = "DOME9_ACCESS_ID"
  dome9_secret_key = "DOME9_SECRET_KEY"
  base_url         = "https://api.dome9.com/v2/"
}


# 2. Pre-requisite: Onborded AZURE Account to CloudGuard Dome9
# [!NOTE] If the AZURE account is already onboarded, you can skip this step.

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

# 3. AWP Onboarding using the Dome9 AWP AZURE module

module "terraform-dome9-awp-azure" {
  source               = "dome9/awp-azure/dome9"
  awp_cloud_account_id = dome9_cloudaccount_azure.my_azure_cloud_account.id # [<CLOUDGUARD_ACCOUNT_ID | <AZURE_SUBSCRIPTION>]  
  awp_scan_mode        = "inAccount"                              # [inAccount | saas |inAccountHub | inAccountSub ]  

  # Optional customizations:
  awp_is_scanned_hub        = false
  awp_centralized_cloud_account_id = "CENTRALIZED_CLOUAD_ACCOUNT_ID OR SUBSCRIPTION ID"
  awp_skip_function_app_scan = false

  # Optional account Settings
  # e.g:  
  awp_account_settings_azure = {
    scan_machine_interval_in_hours  = 24
    disabled_regions                = [] # e.g ["East US", "West US"]
    max_concurrent_scans_per_region = 20
    custom_tags = {
      tag1 = "value1"
      tag2 = "value2"
      tag3 = "value3"
    }
  }
}