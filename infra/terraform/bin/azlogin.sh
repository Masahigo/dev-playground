# Check whether user/spn is already logged in to Azure
user_logged_in=$(az account list --query [0])
if [ -z "$user_logged_in" ]; then
    echo "Login to Azure using SPN.."
    az login --service-principal -t $ARM_TENANT_ID -u $ARM_CLIENT_ID -p $ARM_CLIENT_SECRET
    az account set --subscription $ARM_SUBSCRIPTION_ID
else
    echo "Already logged in as user - skip login.."
fi
