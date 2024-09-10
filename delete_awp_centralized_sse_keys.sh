#!/bin/bash

AWP_SUBSCRIPTION_ID=$1

delete_awp_keys_from_all_awp_vaults(){
  AzOutput=$(az keyvault list --subscription "$AWP_SUBSCRIPTION_ID" --query "[?tags.CG_AWP_OWNER == 'CG.AWP'].name" -o tsv)
  AzRetVal=$?
  if [ $AzRetVal -eq 0 ] && [ -n "$AzOutput" ]; then
    for keyvault in $AzOutput; do
      delete_awp_keys_from_vault "$keyvault"
    done
  fi
}

delete_awp_keys_from_vault() {
  _vault_name="$1"
  _awp_owner_key_lower="cg_awp_owner"
  AzOutput=$(az keyvault key list --subscription "$AWP_SUBSCRIPTION_ID" --vault-name "$_vault_name" --query "[?tags.$_awp_owner_key_lower == 'CG.AWP'].name" -o tsv)
  AzRetVal=$?
  if [ $AzRetVal -eq 0 ] && [ -n "$AzOutput" ]; then
    for key in $AzOutput; do
      az keyvault key delete --vault-name "$_vault_name" --name "$key"
    done
  fi
}

delete_awp_keys_from_all_awp_vaults