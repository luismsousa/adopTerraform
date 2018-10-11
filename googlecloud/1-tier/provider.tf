# Configure the Google Provider
provider "google" {
  credentials = "${var.credentials}"
  project = "${var.project_id}"
  region  = "europe-west2"
  zone    = "europe-west2-a"
}