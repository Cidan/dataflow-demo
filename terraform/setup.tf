resource "google_compute_subnetwork" "df-demo" {
  name          = "df-demo"
  network       = "default"
  project       = "jinked-home"
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
} // Create our Pub/Sub topics

resource "google_pubsub_topic" "pd-demo" {
  name = "pd-demo"
}

resource "google_pubsub_subscription" "pd-demo" {
  name  = "pd-demo"
  topic = "${google_pubsub_topic.pd-demo.name}"

  ack_deadline_seconds = 120
}

// Create a k8s cluster
resource "google_container_cluster" "df-demo" {
  name               = "df-demo"
  zone               = "us-central1-a"
  enable_legacy_abac = true

  /*
                      master_auth {
                        username = "KDJSH8shdshd"
                        password = "asjdhsdhcx7xhcasa11z"
                      }
                    */
  subnetwork = "${google_compute_subnetwork.df-demo.name}"

  #subnetwork = "default"


  #additional_zones = [
  #  "us-central1-b",
  #  "us-central1-c",
  #]

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

    autoscaling = {
      min_node_count = 9
      max_node_count = 24
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

resource "google_bigtable_instance" "df-demo" {
  name         = "df-demo"
  cluster_id   = "df-demo"
  zone         = "us-central1-b"
  num_nodes    = 3
  storage_type = "SSD"
}

resource "google_bigtable_table" "df-demo" {
  name          = "df-demo"
  instance_name = "${google_bigtable_instance.df-demo.name}"
}

resource "google_bigtable_table" "df-demo-tsdb" {
  name          = "tsdb"
  instance_name = "${google_bigtable_instance.df-demo.name}"
}

resource "google_bigtable_table" "df-demo-tsdb-uid" {
  name          = "tsdb-uid"
  instance_name = "${google_bigtable_instance.df-demo.name}"
}

resource "google_bigtable_table" "df-demo-tsdb-tree" {
  name          = "tsdb-tree"
  instance_name = "${google_bigtable_instance.df-demo.name}"
}

resource "google_bigtable_table" "df-demo-tsdb-meta" {
  name          = "tsdb-meta"
  instance_name = "${google_bigtable_instance.df-demo.name}"
}
