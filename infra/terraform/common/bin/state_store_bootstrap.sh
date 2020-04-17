#!/usr/bin/env bash
#
# This script creates a place for Terraform to store remote state in Azure blob
# storage and prints out state configuration.

set -euo pipefail

function print_usage_and_exit {
  me=$(basename "$0")
  echo "Usage: $me [-n] [-l <resource group location>] [-g <resource group name>] [-t <tags>] -a <storage account name>"
  echo
  echo "Options:"
  echo "  -l           Azure location to use (defaults to westeurope)"
  echo "  -g           Resource group name to use (defaults to azure-spa-tf-state-rg)"
  echo "  -a           Storage account name (mandatory, no default)"
  echo "  -t           Tags to use for resources, e.g.: \"key1=value1 key2=value2\" (defaults to \"AppGroup=Platform Type=Dev Team=PolarSquad Customer=RELEX\")"
  echo "  -n           Non-interactive mode: don't prompt for confirmation (defaults to false)"
  echo
  exit 1
}

function create_resources {
  echo "Tags to apply for resources:"
  echo ""
  echo "$opt_tags"
  echo
  echo "Current subscription:"
  echo
  az account show -o table
  echo

  if [ $opt_noninteractive != "true" ]; then
    echo "Does the above look correct? Answer 'yes' to continue."
    read confirmation

    if [ $confirmation != "yes" ]; then
      echo "Exiting..."
      exit 1
    fi
  fi

  echo
  echo "Creating resource group..."
  az group create \
    --tags $opt_tags \
    -l $opt_resource_group_location \
    -n $opt_resource_group_name \
    -o table
  echo
  echo "Creating storage account..."
  az storage account create \
    --sku "Standard_LRS" \
    --encryption-services blob \
    --kind StorageV2 \
    --tags $opt_tags \
    -n $opt_storage_account_name \
    -g $opt_resource_group_name \
    -o table
  echo
  storage_account_key=$(az storage account keys list --resource-group $opt_resource_group_name --account-name $opt_storage_account_name --query [0].value -o tsv)
  echo "Creating storage container..."
  az storage container create \
    --fail-on-exist \
    --metadata $opt_tags \
    --public-access off \
    --account-name $opt_storage_account_name \
    --account-key $storage_account_key \
    -n terraform \
    -o table
  echo
}

function print_terraform_remotestate_config {
  echo "Here's a snippet that configures state storage in terraform:"
  echo
  echo "terraform {"
  echo "  ..."
  echo "  backend \"azurerm\" {"
  echo "    resource_group_name  = \"$opt_resource_group_name\""
  echo "    storage_account_name = \"$opt_storage_account_name\""
  echo "    container_name       = \"terraform\""
  echo "    key                  = \"azurespa.demo.tfstate\""
  echo "  }"
  echo "}"
}

opt_resource_group_location="westeurope"
opt_resource_group_name="azure-spa-tf-state-rg"
opt_storage_account_name=""
opt_tags="environment=demo application=SPA"
opt_noninteractive="false"

while getopts "l:g:a:t:n" opt; do
  case $opt in
    l)
      opt_resource_group_location="${OPTARG}"
      ;;
    g)
      opt_resource_group_name="${OPTARG}"
      ;;
    a)
      opt_storage_account_name="${OPTARG}"
      ;;
    t)
      opt_tags="${OPTARG}"
      ;;
    n)
      opt_noninteractive="true"
      ;;
    *)
      print_usage_and_exit
      ;;
  esac
done

if [[ -z "$opt_resource_group_location" ]]; then
  print_usage_and_exit
fi

if [[ -z "$opt_resource_group_name" ]]; then
  print_usage_and_exit
fi

if [[ -z "$opt_storage_account_name" ]]; then
  print_usage_and_exit
fi

if [[ -z "$opt_tags" ]]; then
  print_usage_and_exit
fi

subscription_id=`az account show | jq -r .id`
resource_group_exists=$(az group exists -n $opt_resource_group_name)

if [ $resource_group_exists == "true" ]; then
  echo "Resource group \"$opt_resource_group_name\" already exists, exiting"
  exit 1
fi

create_resources
print_terraform_remotestate_config
