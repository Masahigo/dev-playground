# Single Page App for Dev Playground

This app was created using [CRA](https://github.com/facebook/create-react-app).

## Testing CI via Docker container

Prerequisites:

- Azure subscription
- Service Principal created with high enough privileges to access the Azure resources (Storage account, CDN)
- Docker installed
- Azure CLI

**Build the app**

```bash
npm install
npm run build
```

**Configure local environment variables for Azure CLI**

```bash
# Login with your user account (which has the needed privileges to create new SPNs)
$ az ad sp create-for-rbac --name ServicePrincipalName
{
  "appId": "xxx",
  "displayName": "ServicePrincipalName",
  "name": "http://ServicePrincipalName",
  "password": "xxx",
  "tenant": "xxx"
}
```

Save these credentials to a local environent file `.env.local`:

```
ARM_CLIENT_ID=<appId>
ARM_CLIENT_SECRET=<password>
ARM_TENANT_ID=<tenant>
ARM_SUBSCRIPTION_ID=<your Azure subscription>

```

**Running the Docker container locally (Windows WSL)**

```bash
$ docker run --env-file ./.env.local -it --rm \
--name client-ci -v `pwd`:`pwd` -w `pwd` mcr.microsoft.com/azure-cli:2.3.1 /bin/bash

bash-5.0# az login --service-principal -t $ARM_TENANT_ID -u $ARM_CLIENT_ID -p $ARM_CLIENT_SECRET
...
bash-5.0# az account set --subscription $ARM_SUBSCRIPTION_ID
bash-5.0# CDN_ENDPOINT_NAME=spa-demo-fe-we-cdn-ep
bash-5.0# CDN_PROFILE_NAME=spa-demo-fe-we-cdn
bash-5.0# RESOURCE_GROUP_NAME=spa-demo-we-rg
bash-5.0# STORAGE_ACCOUNT_NAME=spademofewestor

bash-5.0# ./ci/deploy-azure-cdn.sh $CDN_ENDPOINT_NAME $CDN_PROFILE_NAME $RESOURCE_GROUP_NAME $STORAGE_ACCOUNT_NAME
```