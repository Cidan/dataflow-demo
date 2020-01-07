// Create our Pub/Sub topics for our dataflow job
resource "google_pubsub_topic" "dataflow-stream-demo" {
  project = "${var.project}"
  name = "dataflow-stream-demo"
}

resource "google_pubsub_subscription" "dataflow-stream-demo" {
  project = "${var.project}"
  name  = "dataflow-stream-demo"
  topic = "${google_pubsub_topic.dataflow-stream-demo.name}"

  ack_deadline_seconds = 120
}

resource "google_pubsub_topic" "dataflow-stream-gcs-demo" {
  project = "${var.project}"
  name = "dataflow-stream-gcs-demo"
}

resource "google_pubsub_subscription" "dataflow-stream-gcs-demo" {
  project = "${var.project}"
  name  = "dataflow-stream-gcs-demo"
  topic = "${google_pubsub_topic.dataflow-stream-gcs-demo.name}"

  ack_deadline_seconds = 120
}
