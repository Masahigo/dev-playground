#!/bin/sh

set -e

export VARIABLES=$INPUT_VARIABLES
export INPUT_PATH=$INPUT_PATH

cd /github/workspace/$INPUT_PATH

var_args=""
VARIABLES=$(echo "$VARIABLES" | tr "," "\n")
for var in $VARIABLES; do
  var_args="$var_args -var $var"
done

echo "terraform apply -no-color -input=false -auto-approve $var_args"
terraform apply -no-color -input=false -auto-approve $var_args
