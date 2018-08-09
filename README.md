# Dataflow demo

This is a Dataflow demo, broken into a few parts.

## Generate
Generate is a fake message generator, writte in go. This will insert fake messages into a Pub/Sub stream.

## Dockerfile
Dockerfile for building a deployment of the generate application. This must be pushed to a docker registry, such as the GCP hosted one, that GKE can reach.

## k8s
k8s deployment file for Generate, you must change this so the deployment uses your docker image location.

## Beam
Dataflow beam workflow, written in Java. This will take string data off of Pub/Sub and transform it into TableRow format.

## Terraform
Creates a GKE cluster and creates topics and subscriptions for Pub/Sub.

## Usage
After creating the docker image artifact and uploading it, edit `k8s/deployment.yml` so the location of this image is what is deployed.

You must also edit the first two uncommented lines in the `Makefile` in the root folder as documented.

Once the above two things are done, run `make start` in the root checkout folder and the entire stack will deploy to the GCP project in your `Makefile`