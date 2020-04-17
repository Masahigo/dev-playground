#!/bin/bash

set -e

CDN_ENDPOINT_NAME=$1
CDN_PROFILE_NAME=$2
RESOURCE_GROUP_NAME=$3
STORAGE_ACCOUNT_NAME=$4

CDN_ORIGIN_PATH=spa

echo "Get account key for storage account"
STORAGE_ACCOUNT_KEY=$(az storage account keys list \
 -g $RESOURCE_GROUP_NAME \
 --account-name $STORAGE_ACCOUNT_NAME \
  --query "[0].value" \
  --output tsv)

# add coreutils package to support -d options
apk add --update coreutils && rm -rf /var/cache/apk/*

echo "Create SAS token.."
EXPIRE=$(date -u -d "3 months" '+%Y-%m-%dT%H:%M:%SZ')
START=$(date -u -d "-1 day" '+%Y-%m-%dT%H:%M:%SZ')

# Only working solution found so far for creating SAS that works with AzCopy
AZURE_STORAGE_SAS_TOKEN=$(az storage account generate-sas \
 --account-name $STORAGE_ACCOUNT_NAME \
 --account-key $STORAGE_ACCOUNT_KEY \
 --start $START \
 --expiry $EXPIRE \
 --https-only \
 --resource-types sco \
 --services b \
 --permissions dlrw -o tsv | sed 's/%3A/:/g;s/\"//g')

# https://docs.microsoft.com/en-us/azure/storage/common/storage-use-azcopy-v10#use-azcopy-in-a-script
echo "Setup AzCopy.."
mkdir -p tmp
cd tmp
wget -O azcopy_v10.tar.gz https://aka.ms/downloadazcopy-v10-linux && tar -xf azcopy_v10.tar.gz --strip-components=1
cp ./azcopy /usr/bin/
cd ..

az_copy_to_blob_storage(){
  echo "Source path: ${1}"
   if [ `az storage blob list -c $CDN_ORIGIN_PATH --account-name $STORAGE_ACCOUNT_NAME --sas-token $AZURE_STORAGE_SAS_TOKEN --query "length([])"` == 0 ]; then
        echo "Destination is empty. Skip removal.."
  else
    echo "Remove current files from blob storage.."
    azcopy rm "https://$STORAGE_ACCOUNT_NAME.blob.core.windows.net/$CDN_ORIGIN_PATH?$AZURE_STORAGE_SAS_TOKEN" --recursive=true
  fi
  echo "Copy new files from source path to blob storage.."
  azcopy cp "${1}/*" "https://$STORAGE_ACCOUNT_NAME.blob.core.windows.net/$CDN_ORIGIN_PATH?$AZURE_STORAGE_SAS_TOKEN" --recursive
}

# Copy files to storage account using AzCopy
echo "Copy build folder contents to blob storage using AzCopy.."
SOURCE_PATH="$(pwd)/build"

az_copy_to_blob_storage $SOURCE_PATH

DELIVERY_POLICY=$(az cdn endpoint rule show -n $CDN_ENDPOINT_NAME -g $RESOURCE_GROUP_NAME --profile-name $CDN_PROFILE_NAME --query "deliveryPolicy.rules[].name" -o tsv)
GLOBAL_RULE_NAME=Global
HTTP_TO_HTTPS_RULE_NAME=RedirectToHTTPS
DEFAULT_URL_REWRITE_RULE_NAME=DefaultUrlRewrite

echo "Apply Global caching rule.."

if [[ $DELIVERY_POLICY != *$GLOBAL_RULE_NAME* ]]; then
  az cdn endpoint rule add -g $RESOURCE_GROUP_NAME -n $CDN_ENDPOINT_NAME --profile-name $CDN_PROFILE_NAME \
    --order 0 --rule-name $GLOBAL_RULE_NAME --action-name CacheExpiration \
    --cache-behavior SetIfMissing --cache-duration "7.00:00:00" --output none
fi

echo "Apply URL redirect rule for HTTP to HTTPS.."

# Force HTTP to HTTPS redirect
# Note: action-name param needs to be fixed to 'UrlRedirect'
if [[ $DELIVERY_POLICY != *$HTTP_TO_HTTPS_RULE_NAME* ]]; then
  az cdn endpoint rule add -g $RESOURCE_GROUP_NAME --profile-name $CDN_PROFILE_NAME -n $CDN_ENDPOINT_NAME \
    --order 1 --rule-name $HTTP_TO_HTTPS_RULE_NAME --match-variable RequestScheme \
    --operator Equal --match-values HTTP --action-name UrlRedirect \
    --redirect-protocol Https --redirect-type PermanentRedirect --output none
fi

echo "Apply Default URL rewrite rule.."

# Default URL Rewrite to index.html
# https://stackoverflow.com/questions/58914446/azure-cdn-microsoft-standard-rewrite-url-angular
if [[ $DELIVERY_POLICY != *$DEFAULT_URL_REWRITE_RULE_NAME* ]]; then
  az cdn endpoint rule add -g $RESOURCE_GROUP_NAME --profile-name $CDN_PROFILE_NAME -n $CDN_ENDPOINT_NAME \
    --order 2 --rule-name $DEFAULT_URL_REWRITE_RULE_NAME --match-variable UrlFileExtension \
    --operator GreaterThan --negate-condition true --match-values 0 --action-name UrlRewrite --source-pattern "/" \
    --destination "/index.html" --preserve-unmatched-path false --output none
fi

echo "Purge CDN endpoint.."

# Purge CDN
az cdn endpoint purge \
-g $RESOURCE_GROUP_NAME \
-n $CDN_ENDPOINT_NAME \
--profile-name $CDN_PROFILE_NAME \
--content-paths '/*'
