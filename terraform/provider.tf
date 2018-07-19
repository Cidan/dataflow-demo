variable "project" {}
variable "bucket" {}
// Configure the Google Cloud provider
provider "google" {
  project     = "${var.project}"
  region      = "us-central1"
}
