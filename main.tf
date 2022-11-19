terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }


  required_version = ">= 0.13"
}  

data "yandex_vpc_subnet" "test_subnet" {
  name = "test_subnet"
}

data "yandex_compute_instance" "test" {
  name = "test"
}


data "yandex_compute_instance" "test-monitoring" {
  name = "test-monitoring"
}


resource "local_file" "inventory" {
   filename = "./inventory.txt"
   content = <<EOF
   [webserver]
   web1 ansible_host=${data.yandex_compute_instance.test.network_interface.0.nat_ip_address} ansible_user = ubuntu
   [monitoring]
   monitoring1 ansible_host=${data.yandex_compute_instance.test-monitoring.network_interface.0.nat_ip_address} ansible_user = ubuntu
   EOF
}


resource "yandex_compute_instance" "runner" {
  name        = "runner"
  platform_id = "standard-v1"
  zone        = "ru-central1-a"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd8qps171vp141hl7g9l"
    }
  }
  

  network_interface {
    subnet_id = data.yandex_vpc_subnet.test_subnet.id
    nat = true
  }

  metadata = {
    foo      = "bar"
    ssh-keys = "ubuntu:${file("./id_rsa.pub")}"
  }
  
  
  connection {
    type = "ssh"
    user = "ubuntu"
    private_key = "${file("./id_rsa")}"
    host = self.network_interface[0].nat_ip_address
  }
  
  
  provisioner "file" {
  source      = "script.sh"
  destination = "/tmp/script.sh"
  }

  provisioner "remote-exec" {
  inline = [
      "chmod +x /tmp/script.sh",
      "/tmp/script.sh",
    ]
  }
  

}
