#!/bin/bash

set -e

CDN_ENDPOINT_NAME=$1
CDN_PROFILE_NAME=$2
RESOURCE_GROUP_NAME=$3
CDN_CUSTOM_DOMAIN_NAME=$4
CDN_CUSTOM_DOMAIN_HOSTNAME=$5

source "$(pwd)/bin/azlogin.sh"

# Check the mapping
CUSTOM_DOMAIN_VALIDATED=$(az cdn endpoint validate-custom-domain --host-name $CDN_CUSTOM_DOMAIN_HOSTNAME -n $CDN_ENDPOINT_NAME --profile-name $CDN_PROFILE_NAME -g $RESOURCE_GROUP_NAME --query customDomainValidated -o tsv)

# Create the custom domain on the endpoint
if [ $CUSTOM_DOMAIN_VALIDATED ]; then
    az cdn custom-domain create \
    --endpoint-name $CDN_ENDPOINT_NAME \
    --hostname $CDN_CUSTOM_DOMAIN_HOSTNAME \
    -n $CDN_CUSTOM_DOMAIN_NAME \
    --profile-name $CDN_PROFILE_NAME \
    -g $RESOURCE_GROUP_NAME
fi

# Enable custom domain HTTPS
# ERROR: InvalidResource - The resource format is invalid.
# Issue created: https://github.com/Azure/azure-cli/issues/12273
# PR open to fix this: https://github.com/Azure/azure-cli/pull/12648
#az cdn custom-domain enable-https \
#    --endpoint-name $CDN_ENDPOINT_NAME \
#    -n $CDN_CUSTOM_DOMAIN_NAME \
#    --profile-name $CDN_PROFILE_NAME \
#    -g $RESOURCE_GROUP_NAME
