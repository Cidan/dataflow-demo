resource "google_container_cluster" "df-demo-eu-west" {
  name               = "df-demo"
  zone               = "europe-west1-b"
  enable_legacy_abac = true

  subnetwork = "${google_compute_subnetwork.df-demo-eu-west.name}"

  ip_allocation_policy = {
    services_secondary_range_name = "df-demo-services"
    cluster_secondary_range_name  = "df-demo-pods"
  }
  // Main pool for the cluster
  node_pool {
    name       = "default"
    node_count = 3

    management = {
      auto_repair  = true
      auto_upgrade = true
    }

    node_config {
      oauth_scopes = [
        "https://www.googleapis.com/auth/cloud-platform",
      ]

      disk_size_gb = 30
      machine_type = "n1-standard-8"
    }
  }
}
resource "google_container_cluster" "df-demo-east" {
  name               = "df-demo"
  zone               = "us-east1-b"
  enable_legacy_abac = true

  subnetwork = "${google_compute_subnetwork.df-demo-east.name}"

  ip_allocation_policy = {
    services_secondary_range_name = "df-demo-services"
    cluster_secondary_range_name  = "df-demo-pods"
  }
  // Main pool for the cluster
  node_pool {
    name       = "default"
    node_count = 3

    management = {
      auto_repair  = true
      auto_upgrade = true
    }

    node_config {
      oauth_scopes = [
        "https://www.googleapis.com/auth/cloud-platform",
      ]

      disk_size_gb = 30
      machine_type = "n1-standard-8"
    }
  }
}
resource "google_container_cluster" "df-demo-west" {
  name               = "df-demo"
  zone               = "us-west1-a"
  enable_legacy_abac = true

  subnetwork = "${google_compute_subnetwork.df-demo-west.name}"

  ip_allocation_policy = {
    services_secondary_range_name = "df-demo-services"
    cluster_secondary_range_name  = "df-demo-pods"
  }
  // Main pool for the cluster
  node_pool {
    name       = "default"
    node_count = 3

    management = {
      auto_repair  = true
      auto_upgrade = true
    }

    node_config {
      oauth_scopes = [
        "https://www.googleapis.com/auth/cloud-platform",
      ]

      disk_size_gb = 30
      machine_type = "n1-standard-8"
    }
  }
}
// Create a k8s cluster
resource "google_container_cluster" "df-demo-central" {
  name               = "df-demo"
  zone               = "us-central1-a"
  enable_legacy_abac = true

  subnetwork = "${google_compute_subnetwork.df-demo-central.name}"

  ip_allocation_policy = {
    services_secondary_range_name = "df-demo-services"
    cluster_secondary_range_name  = "df-demo-pods"
  }
  // Main pool for the cluster
  node_pool {
    name       = "default"
    node_count = 3

    management = {
      auto_repair  = true
      auto_upgrade = true
    }

    node_config {
      oauth_scopes = [
        "https://www.googleapis.com/auth/cloud-platform",
      ]

      disk_size_gb = 30
      machine_type = "n1-standard-8"
    }
  }
}