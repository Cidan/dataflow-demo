# Dataflow demo

This is a Dataflow demo, broken into a few parts.

## Generate
Generate is a fake message generator, writte in go. This will insert fake messages into a Pub/Sub stream.

TODO: Insert into Kafka as an option

TODO: very low rate random write junk to illustrate failure

## Dockerfile
New generate builds are triggered in GCP when anything in this repo is pushed with a tag of `build-.*`. The resulting tag can then be used in a k8s deployment.

## k8s
k8s deployment file for Generate

## Beam
Dataflow beam workflow, written in Java. This will take string data off of Pub/Sub and transform it into TableRow format.

TODO: Write to BigQuery

TODO: Split tag output based on failure to decode or not

TODO: Detect EventLog type for user create vs event, split tables

TODO: Read from Kafka as an option

## Terraform
Creates a GKE cluster and creates topics and subscriptions for Pub/Sub.
