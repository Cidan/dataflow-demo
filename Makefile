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

dataflow-flink:
	cd beam/first-dataflow && \
	mvn package -Pflink-runner
	cd beam/first-dataflow && \
	mvn compile exec:java \
    -Dexec.mainClass=com.google.Demo \
		-Pflink-runner \
    -Dexec.args="--project=$(PROJECT) \
	--jobName=EventLog \
	--stagingLocation=gs://$(BUCKET)/pd-demo \
	--runner=FlinkRunner \
	--flinkMaster="[local]" \
	--streaming"

dataflow-local:
	cd beam/first-dataflow && \
	mvn compile exec:java \
    -Dexec.mainClass=com.google.Demo

dataflow: dataflow-central dataflow-west dataflow-east dataflow-europe-west

dataflow-central:
	cd beam/first-dataflow && \
	mvn compile exec:java \
    -Dexec.mainClass=com.google.Demo \
    -Dexec.args="--project=$(PROJECT) \
	--jobName=EventLog-central \
	--stagingLocation=gs://$(BUCKET)/pd-demo \
	--runner=DataflowRunner \
	--numWorkers=10 \
	--diskSizeGb=30 \
	--experiments=shuffle_mode=service \
	--subnetwork="regions/us-central1/subnetworks/default" \
	--streaming"

dataflow-west:
	cd beam/first-dataflow && \
	mvn compile exec:java \
    -Dexec.mainClass=com.google.Demo \
    -Dexec.args="--project=$(PROJECT) \
	--jobName=EventLog-west \
	--stagingLocation=gs://$(BUCKET)/pd-demo \
	--runner=DataflowRunner \
	--numWorkers=10 \
	--diskSizeGb=30 \
	--subnetwork="regions/us-west1/subnetworks/default" \
	--region="us-west1" \
	--streaming"

dataflow-east:
	cd beam/first-dataflow && \
	mvn compile exec:java \
    -Dexec.mainClass=com.google.Demo \
    -Dexec.args="--project=$(PROJECT) \
	--jobName=EventLog-east \
	--stagingLocation=gs://$(BUCKET)/pd-demo \
	--runner=DataflowRunner \
	--numWorkers=10 \
	--diskSizeGb=30 \
	--subnetwork="regions/us-east1/subnetworks/default" \
	--region="us-east1" \
	--streaming"

dataflow-europe-west:
	cd beam/first-dataflow && \
	mvn compile exec:java \
    -Dexec.mainClass=com.google.Demo \
    -Dexec.args="--project=$(PROJECT) \
	--jobName=EventLog-europe-west \
	--stagingLocation=gs://$(BUCKET)/pd-demo \
	--runner=DataflowRunner \
	--numWorkers=10 \
	--diskSizeGb=30 \
	--subnetwork="regions/europe-west1/subnetworks/default" \
	--region="europe-west1" \
	--streaming"
creds:
	gcloud container clusters get-credentials df-demo --zone us-central1-a --project $(PROJECT)

cbt:
	cbt -instance df-demo createfamily df-demo events

# Start up everything and kick off work
start:
	cd terraform && terraform init && terraform apply -auto-approve -var "project=$(PROJECT)"
	gcloud container clusters get-credentials df-demo --zone us-central1-a --project $(PROJECT)
	kubectl apply -f k8s/deployment.yml
	gcloud container clusters get-credentials df-demo --zone us-west1-a --project $(PROJECT)
	kubectl apply -f k8s/deployment.yml
	gcloud container clusters get-credentials df-demo --zone us-east1-b --project $(PROJECT)
	kubectl apply -f k8s/deployment.yml
	gcloud container clusters get-credentials df-demo --zone europe-west1-b --project $(PROJECT)
	kubectl apply -f k8s/deployment.yml
	make cbt
	make dataflow

# Stop everything except dataflow
stop:
	cd terraform && terraform destroy -var "project=$(PROJECT)" -var "bucket=$(BUCKET)"

.PHONY: generate
