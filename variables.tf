variable "awp_cloud_account_id" {
    description = "CLOUDGUARD_ACCOUNT_ID or AZURE_SUBSCRIPTION_ID"
    type        = string
}

variable "awp_scan_mode" {
    description = "AWP scan mode, possible values are: <inAccount | saas | inAccountHub | inAccountSub>"
    type        = string
    default     = "inAccount"
    
}

variable "awp_centralized_cloud_account_id" {
    description = "CENTRALIZED_CLOUDGUARD_ACCOUNT_ID or CENTRALIZED_AZURE_SUBSCRIPTION_ID"
    type        = string
    default     = null
}

variable "awp_is_scanned_hub" {
  description = "AWP is scanned hub" # Is the hub (centralized) subscription also scanned by AWP, this param is relevant in case scan_mode is inAccountHub.
  type        = bool
  default     = false
}

variable "management_group_id" {
  description = "Management Group Id" # relevant for "inAccountHub" scan mode.
  type        = string
  default     = null
}

variable "awp_additional_tags" {
  description = "Additional tags to be added to the module resources"
  type        = map(string)
  default     = {}
}

variable "awp_account_settings_azure" {
    description = "Azure Cloud Account settings" # supported only for inAccount, inAccountSub and saas scan mode
    type        = object({
        disabled_regions                 = optional(list(string))  # List of regions to disable scanning e.g. ["eastus", "westus"]
        skip_function_apps_scan          = optional(bool)          # Skip Azure Function Apps scan (supported for inAccount and inAccountSub scan modes) 
        scan_machine_interval_in_hours   = optional(number)        # Scan machine interval in hours
        max_concurrent_scans_per_region  = optional(number)        # Maximum concurrence scans per region
        in_account_scanner_vpc           = optional(string)        # The VPC Mode. Valid values: "ManagedByAWP", "ManagedByCustomer" (supported for inAccount and inAccountHub scan modes)
        custom_tags                      = optional(map(string))   # Custom tags to be added to AWP resources e.g. {"key1" = "value1", "key2" = "value2"}
    })
    default = {}
}