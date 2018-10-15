resource "google_compute_network" "vpc_network" {
  name                    = "sandboxnetwork"
  project =  "${var.project_id}"
  auto_create_subnetworks = "true"
}


resource "google_compute_address" "adopeip" {
  name = "adopeip"
}


resource "google_compute_firewall" "default" {
  name    = "adop-firewall"
  network = "${google_compute_network.vpc_network.name}"


  allow {
    protocol = "tcp"
    ports    = ["22", "80", "44", "2376"]
  }
  allow {
    protocol = "udp"
    ports = ["25826"]
  }
  source_ranges = ["0.0.0.0/0"]
}
