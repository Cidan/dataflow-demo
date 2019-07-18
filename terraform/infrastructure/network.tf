
resource "google_compute_subnetwork" "df-demo" {
  name          = "df-demo"
  network       = "default"
  project       = "${var.project}"
  region        = "us-central1"
  ip_cidr_range = "10.1.0.0/20"
}
