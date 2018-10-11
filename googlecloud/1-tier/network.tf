resource "google_compute_network" "vpc_network" {
  name                    = "sandboxnetwork"
  project =  "${var.project_id}"
  auto_create_subnetworks = "true"
}


resource "google_compute_address" "adopeip" {
  name = "adopeip"
}