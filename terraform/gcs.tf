resource "google_storage_bucket" "batch-data" {
  name     = "iot-batch-data-upload"
  location = "US"
}
resource "google_storage_notification" "notification" {
    bucket            = "${google_storage_bucket.batch-data.name}"
    payload_format    = "JSON_API_V1"
    topic             = "${google_pubsub_topic.iot-batch.id}"
    event_types       = ["OBJECT_FINALIZE"]
    depends_on        = ["google_pubsub_topic_iam_binding.binding"]
}

data "google_storage_project_service_account" "gcs_account" {}

resource "google_pubsub_topic_iam_binding" "binding" {
    topic       = "${google_pubsub_topic.iot-batch.name}"
    role        = "roles/pubsub.publisher"
    members     = ["serviceAccount:${data.google_storage_project_service_account.gcs_account.email_address}"]
}
