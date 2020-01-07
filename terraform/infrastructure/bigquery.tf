resource "google_bigquery_dataset" "dataflow-demo" {
  project                     = "${var.project}"
  dataset_id                  = "dataflow_demo"
  friendly_name               = "dataflow_demo"
  description                 = "Dataflow demo dataset"
  location                    = "US"
}