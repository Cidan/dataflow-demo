// Setup 4 different subnetworks for k8s in 4 different regions
resource "google_compute_subnetwork" "df-demo-central" {
  name          = "df-demo-central"
  network       = "default"
  project       = "${var.project}"
  region        = "us-central1"
  ip_cidr_range = "10.1.0.0/20"

  secondary_ip_range = {
    range_name    = "df-demo-pods"
    ip_cidr_range = "10.1.16.0/20"
  }

  secondary_ip_range = {
    range_name    = "df-demo-services"
    ip_cidr_range = "10.1.32.0/20"
  }
}

resource "google_compute_subnetwork" "df-demo-east" {
  name          = "df-demo-east"
  network       = "default"
  project       = "${var.project}"
  region        = "us-east1"
  ip_cidr_range = "10.2.0.0/20"

  secondary_ip_range = {
    range_name    = "df-demo-pods"
    ip_cidr_range = "10.2.16.0/20"
  }

  secondary_ip_range = {
    range_name    = "df-demo-services"
    ip_cidr_range = "10.2.32.0/20"
  }
}

resource "google_compute_subnetwork" "df-demo-west" {
  name          = "df-demo-west"
  network       = "default"
  project       = "${var.project}"
  region        = "us-west1"
  ip_cidr_range = "10.3.0.0/20"

  secondary_ip_range = {
    range_name    = "df-demo-pods"
    ip_cidr_range = "10.3.16.0/20"
  }

  secondary_ip_range = {
    range_name    = "df-demo-services"
    ip_cidr_range = "10.3.32.0/20"
  }
}

resource "google_compute_subnetwork" "df-demo-eu-west" {
  name          = "df-demo-eu-west"
  network       = "default"
  project       = "${var.project}"
  region        = "europe-west1"
  ip_cidr_range = "10.4.0.0/20"

  secondary_ip_range = {
    range_name    = "df-demo-pods"
    ip_cidr_range = "10.4.16.0/20"
  }

  secondary_ip_range = {
    range_name    = "df-demo-services"
    ip_cidr_range = "10.4.32.0/20"
  }
}