####
# Dataflow demo Makefile script
# Run "make start" to start the demo, "make stop" to stop it
####

# Set the two following variabels to a project and a bucket
# you have access to.
export PROJECT = jinked-home
export BUCKET = jinked-stage

# Build our generate program
build:
	go build ./...
	go install ./...

generate:
	../../../../bin/generate

dataflow-local:
	cd beam/first-dataflow && \
	mvn compile exec:java \
    -Dexec.mainClass=com.google.Demo

dataflow:
	cd beam/first-dataflow && \
	mvn compile exec:java \
    -Dexec.mainClass=com.google.Demo \
    -Dexec.args="--project=$(PROJECT) \
	--jobName=EventLog \
	--stagingLocation=gs://$(BUCKET)/pd-demo \
	--runner=DataflowRunner \
	--numWorkers=10 \
	--diskSizeGb=30 \
	--streaming"

# Start up everything and kick off work
start:
	cd terraform && terraform init && terraform apply -auto-approve -var "project=$(PROJECT)" -var "bucket=$(BUCKET)"
	gcloud container clusters get-credentials df-demo --zone us-central1-a --project $(PROJECT)
	kubectl apply -f k8s/deployment.yml
	make dataflow

# Stop everything except dataflow
stop:
	cd terraform && terraform destroy -var "project=$(PROJECT)" -var "bucket=$(BUCKET)"

.PHONY: generate
