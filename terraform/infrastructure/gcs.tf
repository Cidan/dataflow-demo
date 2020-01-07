resource "google_storage_bucket" "staging-bucket" {
  project       = "${var.project}"
  name          = "${var.bucket-prefix}-staging"
  location      = "US"
  force_destroy = true
}

resource "google_storage_bucket" "batch-bucket" {
  project       = "${var.project}"
  name          = "${var.bucket-prefix}-batch"
  location      = "US"
  force_destroy = true
}

resource "google_storage_notification" "notification" {
    bucket            = "${google_storage_bucket.batch-bucket.name}"
    payload_format    = "JSON_API_V1"
    topic             = "${google_pubsub_topic.dataflow-stream-gcs-demo.id}"
    event_types       = ["OBJECT_FINALIZE"]
    depends_on        = ["google_pubsub_topic_iam_binding.binding"]
}

data "google_storage_project_service_account" "gcs_account" {
  project = "${var.project}"
}

resource "google_pubsub_topic_iam_binding" "binding" {
    project     = "${var.project}"
    topic       = "${google_pubsub_topic.dataflow-stream-gcs-demo.name}"
    role        = "roles/pubsub.publisher"
    members     = ["serviceAccount:${data.google_storage_project_service_account.gcs_account.email_address}"]
}
