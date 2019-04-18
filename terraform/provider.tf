variable "project" {}
// Configure the Google Cloud provider
provider "google" {
	version = "1.19"
  project     = "${var.project}"
  region      = "us-central1"
}

provider "google-beta" {
  region = "us-central1"
  project = "${var.project}"
}