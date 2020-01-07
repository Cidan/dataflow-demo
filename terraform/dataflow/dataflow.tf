resource "google_dataflow_job" "dataflow-demo" {
    name = "dataflow-demo"
    template_gcs_path = "gs://${var.bucket-prefix}-staging/dataflow-template/streaming-insert"
    temp_gcs_location = "gs://${var.bucket-prefix}-staging/dataflow-tmp"
    zone = "us-central1-a"
}