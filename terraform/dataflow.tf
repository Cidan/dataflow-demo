resource "google_dataflow_job" "dataflow-demo" {
    name = "dataflow-demo"
    template_gcs_path = "gs://my-bucket/templates/template_file"
    temp_gcs_location = "gs://my-bucket/tmp_dir"
    parameters = {
        foo = "bar"
        baz = "qux"
    }
}