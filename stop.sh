#!/bin/bash
PROJECT=$1
BUCKET=$2

cd terraform
terraform destroy -var "project=$PROJECT" -var "bucket=$BUCKET"