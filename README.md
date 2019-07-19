# Dataflow demo

A medium-to-large scale dataflow demo for showing off an end-to-end data processing pipeline.

## Usage

Run `start.sh <project-name> <staging-bucket>` where `project-name` is an existing GCP project, and `staging-bucket` is a *GCS bucket name (without the path) that does not exist*.

Example:

`./start.sh my-cool-project some-bucket-name`