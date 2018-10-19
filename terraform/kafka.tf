// Setup a Dataproc cluster with Kafka
resource "google_dataproc_cluster" "kafka" {
  name       = "kafka"
  region     = "us-central1"

  cluster_config {
    
    gce_cluster_config {
      subnetwork = "default"
      service_account_scopes = ["cloud-platform"]
    }

    master_config {
      num_instances     = 3
      machine_type      = "n1-standard-2"
      disk_config {
          boot_disk_size_gb = 30
      }
    }

    worker_config {
      num_instances     = 24
      machine_type      = "n1-standard-8"
      disk_config {
        boot_disk_size_gb = 20
        num_local_ssds    = 0
      }
    }

    preemptible_worker_config {
      num_instances     = 0
    }

    initialization_action {
      script      = "gs://jinked-stage/kafka.sh"
      timeout_sec = 999
    }
  }
}