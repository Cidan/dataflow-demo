resource "google_bigtable_instance" "df-demo" {
  provider = "google-beta"
  name         = "df-demo"

  cluster {
    cluster_id   = "df-demo-central"
    zone         = "us-central1-b"
    num_nodes    = 3
    storage_type = "HDD"
  }

  cluster {
    cluster_id   = "df-demo-eu-west"
    zone         = "europe-west1-b"
    num_nodes    = 3
    storage_type = "HDD"
  }
}