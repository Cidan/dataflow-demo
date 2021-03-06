#!/bin/bash
set -e
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
	cd terraform/infrastructure
	terraform init
	terraform apply -auto-approve -var "project=$PROJECT" -var "bucket-prefix=$BUCKET"
	cd ../..
}

function start-dataflow {
	cd terraform/dataflow
	terraform init
	terraform apply -auto-approve -var "project=$PROJECT" -var "bucket-prefix=$BUCKET"
	cd ../..
}

function create-bigtable-cf {
	cbt -project $PROJECT -instance df-demo createfamily df-demo events
}

function create-dataflow-template {
	cd beam/streaming-insert
	mvn compile exec:java \
	-Dexec.mainClass=com.google.Demo \
	-Dexec.args="--runner=DataflowRunner \
  --project=$PROJECT \
  --stagingLocation=gs://$BUCKET-staging/dataflow-staging \
  --templateLocation=gs://$BUCKET-staging/dataflow-template/streaming-insert"
	cd ../../
}

function start-generator {
	gcloud container clusters get-credentials df-demo --zone us-central1-a --project $PROJECT
	sed "s/{{PROJECT}}/$PROJECT/" k8s/deployment.yml | kubectl apply -f -
}

#create-container
create-terraform
create-bigtable-cf
create-dataflow-template
start-dataflow
start-generator