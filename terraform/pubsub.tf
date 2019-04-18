// Create our Pub/Sub topics for our dataflow job
resource "google_pubsub_topic" "pd-demo" {
  name = "pd-demo"
}

resource "google_pubsub_subscription" "pd-demo" {
  name  = "pd-demo"
  topic = "${google_pubsub_topic.pd-demo.name}"

  ack_deadline_seconds = 120
}