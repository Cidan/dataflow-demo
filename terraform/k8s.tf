// Create a k8s cluster
resource "google_container_cluster" "df-demo" {
  name               = "df-demo"
  zone               = "us-central1-a"
  enable_legacy_abac = true

  subnetwork = "${google_compute_subnetwork.df-demo.name}"
  // Main pool for the cluster
  node_pool {
    name       = "default"
    node_count = 3

    node_config {
      oauth_scopes = [
        "https://www.googleapis.com/auth/pubsub",
        "https://www.googleapis.com/auth/storage.read_only"
      ]

      disk_size_gb = 30
      machine_type = "n1-standard-8"
    }
  }
}