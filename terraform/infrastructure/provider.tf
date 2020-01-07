variable "project" {}
variable "bucket-prefix" {}
// Configure the Google Cloud provider
provider "google" {
	version     = "2.11"
  project     = "${var.project}"
  region      = "us-central1"
}

provider "google-beta" {
  version     = "2.11"
  project     = "${var.project}"
  region      = "us-central1"
}