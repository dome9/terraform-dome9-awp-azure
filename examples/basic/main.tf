
# This module block is used to configure the Terraform Dome9 AWP AZURE module.
module "terraform-dome9-awp-azure" {
    source = "dome9/awp-azure/dome9"

    # The ID of the Dome9 AZURE Cloud Account to associate with the AWP.
    # This can be either the ID of the Dome9 Cloud Account resource or the AZURE Subscription Number.
    awp_cloud_account_id = "12345678-1234-abcd-1234-123456789012" 

    # The scan mode for the AWP. Valid values are "inAccount", "saas", "inAccountHub" or inAccountSub.
    awp_scan_mode = "inAccount"
}
