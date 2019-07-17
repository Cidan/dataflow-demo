variable "project" {}
variable "bucket" {}
// Configure the Google Cloud provider
provider "google" {
	version     = "2.10"
  project     = "${var.project}"
  region      = "us-central1"
}

provider "google-beta" {
  version     = "2.10"
  region      = "us-central1"
  project     = "${var.project}"
}