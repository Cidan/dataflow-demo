variable "project" {}
variable "bucket" {}
// Configure the Google Cloud provider
provider "google" {
	version = "1.19"
  project     = "${var.project}"
  region      = "us-central1"
}
