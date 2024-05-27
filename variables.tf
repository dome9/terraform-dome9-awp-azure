variable "awp_cloud_account_id" {
    description = "CLOUDGUARD_ACCOUNT_ID or AZURE_SUBSCRIPTION_ID"
    type        = string
}

variable "awp_scan_mode" {
    description = "AWP scan mode <inAccount|saas|inAccountHub|inAccountSub>" # the valid values are "inAccount" or "saas" or "inAccountHub" or "inAccountSub" when onboarding the Azure account to Dome9 AWP.
    type        = string
    default     = "inAccount"
    
}

variable "awp_is_scanned_hub" {
  description = "AWP is scanned hub" # Is the hub subscription also scanned by AWP, this param is relevant in case scan_mode is inAccountHub
  type        = bool
  default     = false
}

variable "awp_centralized_cloud_account_id" {
    description = "CLOUDGUARD_ACCOUNT_ID or AZURE_SUBSCRIPTION"
    type        = string
    default     = null
}

variable "awp_account_settings_azure" {
    description = "Azure Cloud Account settings"
    type        = object({
        disabled_regions                 = optional(list(string))  # List of regions to disable scanning e.g. ["eastus", "westus"]
        skip_function_apps_scan          = optional(bool)          # Skip Azure Function Apps scan (supported for inAccount and inAccountSub scan modes) 
        scan_machine_interval_in_hours   = optional(number)        # Scan machine interval in hours
        max_concurrent_scans_per_region  = optional(number)        # Maximum concurrence scans per region
        custom_tags                      = optional(map(string))   # Custom tags to be added to AWP resources e.g. {"key1" = "value1", "key2" = "value2"}
    })
    default = null
}