#!/bin/bash

AWP_SUBSCRIPTION_ID=$1
AWP_OBSOLETE_OWNER_TAG_KEY=$2
AWP_OWNER_TAG_KEY=$3
AWP_OWNER_TAG_VALUE=$4

delete_awp_keys_from_all_awp_vaults(){
  AzOutput=$(az keyvault list --subscription "$AWP_SUBSCRIPTION_ID" --query "[?tags.$AWP_OBSOLETE_OWNER_TAG_KEY == '$AWP_OWNER_TAG_VALUE' || tags.$AWP_OWNER_TAG_KEY == '$AWP_OWNER_TAG_VALUE'].name" -o tsv)
  AzRetVal=$?
  if [ $AzRetVal -eq 0 ] && [ -n "$AzOutput" ]; then
    for keyvault in $AzOutput; do
      delete_awp_keys_from_vault "$keyvault"
    done
  fi
}

delete_awp_keys_from_vault() {
  _vault_name="$1"
  _awp_obsolete_owner_key_lower=$(echo "$AWP_OBSOLETE_OWNER_TAG_KEY" | tr '[:upper:]' '[:lower:]')
  _awp_owner_key_lower=$(echo "$AWP_OWNER_TAG_KEY" | tr '[:upper:]' '[:lower:]')
  AzOutput=$(az keyvault key list --subscription "$AWP_SUBSCRIPTION_ID" --vault-name "$_vault_name" --query "[?tags.$_awp_obsolete_owner_key_lower == '$AWP_OWNER_TAG_VALUE' || tags.$_awp_owner_key_lower == '$AWP_OWNER_TAG_VALUE'].name" -o tsv)
  AzRetVal=$?
  if [ $AzRetVal -eq 0 ] && [ -n "$AzOutput" ]; then
    for key in $AzOutput; do
      az keyvault key delete --vault-name "$_vault_name" --name "$key"
    done
  fi
}

delete_awp_keys_from_all_awp_vaults
