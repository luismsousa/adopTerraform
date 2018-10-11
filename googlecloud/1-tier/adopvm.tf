resource "google_compute_instance" "adopvm" {
  name         = "adopvm"
  project = "${var.project_id}"
  machine_type = "n1-standard-4"
  zone         = "europe-west2-a"
  allow_stopping_for_update = true


  boot_disk {
    initialize_params {
      image = "centos-7-v20181011"
      size = "50"
      type = "pd-ssd"
    }
  }

  // Local SSD disk
  scratch_disk {
  }

  network_interface {
      network = "default"
      access_config {
          nat_ip = "${google_compute_address.adopeip.address}"
      }
    }

  metadata_startup_script = "sleep 30 && curl -L https://raw.githubusercontent.com/luismsousa/adopTerraform/master/googlecloud/1-tier/scripts/userData.sh > ~/userData.sh && chmod +x ~/userData.sh && export INITIAL_ADMIN_USER=${var.adop_username} && export INITIAL_ADMIN_PASSWORD_PLAIN=${var.adop_password} && cd ~/ && ./userData.sh"

}
