#!/bin/bash
PROJECT=$1
BUCKET=$2

if [[ $PROJECT == "" || $BUCKET == "" ]]; then
	echo "Usage: run.sh <project-id> <staging-bucket>"
	exit 1
fi

function build {
	go build ./...
	go install ./...
}

function create-container {
	echo "Creating container image..."
	gcloud builds submit --config=cloudbuild.yaml --project=$PROJECT
}

function create-terraform {
	cd terraform
	terraform init
	terraform apply -auto-approve -var "project=$PROJECT" -var "bucket=$BUCKET"
	cd ..
}

function start-generator {
	gcloud container clusters get-credentials df-demo --zone us-central1-a --project $PROJECT
	sed "s/{{PROJECT}}/$PROJECT/" k8s/deployment.yml | kubectl apply -f -
}

create-container
create-terraform
start-generator