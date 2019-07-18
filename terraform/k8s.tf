// Create a k8s cluster
resource "google_container_cluster" "df-demo" {
  name               = "df-demo"
  location               = "us-central1-a"
  enable_legacy_abac = true

  subnetwork = "${google_compute_subnetwork.df-demo.name}"

  // Main pool for the cluster
  node_pool {
    name       = "default"
    node_count = 3

    node_config {
      oauth_scopes = [
        "https://www.googleapis.com/auth/pubsub",
        "https://www.googleapis.com/auth/devstorage.read_only",
        "https://www.googleapis.com/auth/logging.write",
        "https://www.googleapis.com/auth/monitoring"
      ]

      disk_size_gb = 30
      machine_type = "n1-standard-8"
    }
  }
}