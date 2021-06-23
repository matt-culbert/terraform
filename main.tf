// Configure the Google Cloud provider
provider "google" {
 credentials = file("CREDENTIALS_FILE.json")
 project     = "PROJECT"
 region      = "us-west1"
}

// Terraform plugin for creating random ids
resource "random_id" "instance_id" {
 byte_length = 8
}

// A single Compute Engine instance
resource "google_compute_instance" "default" {
 name         = "terraform-${random_id.instance_id.hex}"
 machine_type = "f1-micro"
 zone         = "us-west1-a"

 boot_disk {
   initialize_params {
     image = "debian-cloud/debian-9"
   }
 }



// Make sure flask is installed on all new instances for later steps
 metadata_startup_script = "sudo apt-get update; sudo apt-get install ufw && sudo ufw allow 80,22/tcp && sudo ufw enable; sudo apt-get install git; git clone -–recurse-submodules https://github.com/cobbr/Covenant /; wget -q https://packages.microsoft.com/config/ubuntu/19.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb;sudo dpkg -i packages-microsoft-prod.deb;sudo apt-get update;sudo apt-get install apt-transport-https;sudo apt-get update;sudo apt-get install dotnet-sdk-2.2;cd Covenant/Covenant;dotnet build;dotnet run; "

 network_interface {
    network = "default"

    access_config {
      // Include this section to give the VM an external ip address
    }
  }

  // Apply the firewall rule to allow external IPs to access this instance
  tags = ["http-server"]
}

resource "google_compute_firewall" "http-server" {
  name    = "default-allows-http"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  // Allow traffic from everywhere to instances with an http-server tag
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server"]
}

output "ip" {
  value = "${google_compute_instance.default.network_interface.0.access_config.0.nat_ip}"
}
