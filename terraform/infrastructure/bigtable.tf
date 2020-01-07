resource "google_bigtable_instance" "df-demo" {
  project = "${var.project}"
  provider = "google-beta"
  name         = "df-demo"

  cluster {
    cluster_id   = "df-demo-central"
    zone         = "us-central1-b"
    num_nodes    = 3
    storage_type = "HDD"
  }
}

resource "google_bigtable_table" "df-demo" {
  project = "${var.project}"
  name          = "df-demo"
  instance_name = "${google_bigtable_instance.df-demo.name}"
}