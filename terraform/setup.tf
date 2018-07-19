// Create our Pub/Sub topics
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

/*
  master_auth {
    username = "KDJSH8shdshd"
    password = "asjdhsdhcx7xhcasa11z"
  }
*/

  additional_zones = [
    "us-central1-b",
    "us-central1-c",
  ]

  // Main pool for the cluster
  node_pool {
    name = "default"
    node_count = 3

    management = {
      auto_repair = true
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

