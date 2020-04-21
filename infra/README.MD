# IaC using Terraform

## Bootstrap Terraform remote state storage

Before you can create other resources to a new subscription for the
first time, you need to create remote state storage for Terraform. This is done
using a Bash script, as it is needlessly complex to manage remote state storage
using Terraform itself.

Before running the commands below, make sure you know values for:

- The id of the subscription
- Tags to apply

Tags are given in the form accepted by Azure's "az" CLI tool, e.g. "key1=value1
key2=value".

Here is an example of the commands to run (replace option values as necessary):

**Note: The state storage bootstrap script needs to run only once per
subscription!**

```shell
az account list -o table
az account set -s "<name of the subscription>"
cd terraform/common/bin

./state_store_bootstrap.sh \
  -l westeurope \
  -g azure-spa-tf-state-we-rg \
  -t "environment=demo application=SPA" \
  -a azurespatfstatewestor
```

Once the script is finished, it will print out a snippet to be placed in
`main.tf` for storing remote state.

## Provision demo environment

```bash
terraform init
terraform apply -auto-approve
```
**Manual step: enable HTTPS for CDN endpoint's custom domain**

- Navigate to CDN endpoint: `spa-demo-fe-we-cdn-ep`
- Custom domains blade > `playground.dev.msdevopsdude.com`
- Configure
  - Custom domain HTTPS > *On*
  - Certificate management type > *CDN managed*
- Click *Save* and wait for the process to finish (~5-10 mins)
