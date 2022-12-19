#!/usr/bin/env bash
set -e

source vars.sh

# Start from a clean slate
rm -rf .terraform

saml2aws exec 'terraform init \
    -backend=true \
    -backend-config key="${TF_STATE_OBJECT_KEY}" \
    -backend-config bucket="${TF_STATE_BUCKET}" \
    -backend-config dynamodb_table="${TF_LOCK_DB}" '

saml2aws exec 'terraform plan \
    -lock=false \
    -input=false \
    -out=tf.plan '


# saml2aws exec 'terraform apply \
#     -input=false \
#     -auto-approve=true \
#     -lock=false \
#     tf.plan '

 terraform apply -destroy \
    -input=false \
    -auto-approve=true \
    -lock=false
    
