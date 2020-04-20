#!/bin/bash

set -e

RESOURCE_GROUP_NAME=$1
WEBAPP_NAME=$2
WEBAPP_CUSTOM_HOSTNAME=$3

source "$(pwd)/bin/azlogin.sh"

az extension add --name webapp
az webapp config hostname add --resource-group $RESOURCE_GROUP_NAME --webapp-name $WEBAPP_NAME --hostname $WEBAPP_CUSTOM_HOSTNAME
az webapp config ssl create --resource-group $RESOURCE_GROUP_NAME --name $WEBAPP_NAME --hostname $WEBAPP_CUSTOM_HOSTNAME
cert_thumbprint=$(az webapp config ssl list -g $RESOURCE_GROUP_NAME --query [0].thumbprint -o tsv)
az webapp config ssl bind --certificate-thumbprint $cert_thumbprint --name $WEBAPP_NAME --resource-group $RESOURCE_GROUP_NAME --ssl-type SNI
