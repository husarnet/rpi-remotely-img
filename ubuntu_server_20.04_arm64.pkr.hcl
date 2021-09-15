locals {
  my_timestamp = regex_replace(timestamp(), "[- TZ:]","")
  image_name = "rpi-ubuntu-20.04-server"
  output_path = "./output"
}

variable "husarnet_hostname" {
  type = string
  default = "packer-test"
}

variable "husarnet_joincode" {
  type = string
  default = "fc94:b01d:1803:8dd8:b293:5c7d:7639:932a/xxxxxxxxxxxxxxxxxxxxxx"
}

variable "wifi_ssid" {
  type = string
  default = "some-wifi-ssid"
}

variable "wifi_pass" {
  type = string
  default = "some-wifi-pass"
}

source "arm" "ubuntu" {
  file_urls             = ["http://cdimage.ubuntu.com/releases/20.04/release/ubuntu-20.04.3-preinstalled-server-arm64+raspi.img.xz"]
  file_checksum_url     = "http://cdimage.ubuntu.com/releases/20.04/release/SHA256SUMS"
  file_checksum_type    = "sha256"
  file_target_extension = "xz"
  file_unarchive_cmd    = ["xz", "--decompress", "$ARCHIVE_PATH"]
  image_build_method    = "reuse"
  image_path            = "${local.output_path}/${local.image_name}-${local.my_timestamp}.img"
  image_size            = "3.1G"
  image_type            = "dos"
  image_partitions {
    name         = "boot"
    type         = "c"
    start_sector = "2048"
    filesystem   = "fat"
    size         = "256M"
    mountpoint   = "/boot/firmware"
  }
  image_partitions {
    name         = "root"
    type         = "83"
    start_sector = "526336"
    filesystem   = "ext4"
    size         = "2.8G"
    mountpoint   = "/"
  }
  image_chroot_env             = ["PATH=/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin"]
  qemu_binary_source_path      = "/usr/bin/qemu-aarch64-static"
  qemu_binary_destination_path = "/usr/bin/qemu-aarch64-static"
}

build {
  sources = ["source.arm.ubuntu"]

  provisioner "file" {
    source = "./img_files/install_docker.sh"
    destination = "/usr/local/bin/install_docker.sh"
  }

  provisioner "file" {
    source = "./img_files/join_husarnet.sh"
    destination = "/usr/local/bin/join_husarnet.sh"
  }

  provisioner "file" {
    source = "./img_files/join-husarnet.service"
    destination = "/etc/systemd/system/join-husarnet.service"
  }

  provisioner "file" {
    source = "./img_files/99-disable-network-config.cfg"
    destination = "/etc/netplan/99-disable-network-config.cfg"
  }

  provisioner "file" {
    source = "./img_files/01-netcfg.yaml"
    destination = "/etc/netplan/01-netcfg.yaml"
  }

  provisioner "shell" {
    inline = [
      "mv /etc/resolv.conf /etc/resolv.conf.bk",
      "echo 'nameserver 8.8.8.8' > /etc/resolv.conf",
      "echo '127.0.0.1 ubuntu' >> /etc/hosts",
      "echo 127.0.0.1 $(hostname) >> /etc/hosts",

      "apt-get update",

      # Install yq (YAML editing from bash)
      "sudo wget https://github.com/mikefarah/yq/releases/download/v4.12.2/yq_linux_amd64 -O /usr/bin/yq",
      "sudo chmod +x /usr/bin/yq",

      # Installing Husarnet
      "curl https://install.husarnet.com/install.sh | sudo bash",

      # Join Husarnet network with a Join Code on system boot
      "sudo touch /etc/husarnet-credentials",
      "echo 'HUSARNET_HOSTNAME=${var.husarnet_hostname}' >> /etc/husarnet-credentials",
      "echo 'HUSARNET_JOINCODE=${var.husarnet_joincode}' >> /etc/husarnet-credentials",
      "chmod +xr /usr/local/bin/join_husarnet.sh",
      "sudo systemctl enable join-husarnet.service",

      # Installing docker
      "chmod +x /usr/local/bin/install_docker.sh",
      "bash /usr/local/bin/install_docker.sh",
      "rm /usr/local/bin/install_docker.sh",

      # Enable network using netplan
      "sudo yq e -i '.network.wifis.wlan0.access-points = { \"${var.wifi_ssid}\" : { \"password\":\"${var.wifi_pass}\"}} | ... style=\"double\" | .. style=\"\"' /etc/netplan/01-netcfg.yaml",
      "sudo yq e -i '.network.wifis.wlan0.access-points.${var.wifi_ssid}.password style=\"double\"' /etc/netplan/01-netcfg.yaml",
      "netplan apply",
    ]
  }

  post-processor "compress" { 
    output = "${local.output_path}/${local.image_name}-${local.my_timestamp}.img.tar.gz" 
  }

  post-processor "manifest" {}

  post-processor "checksum" {
    checksum_types = ["sha256"]
    output = "${local.output_path}/${local.image_name}-${local.my_timestamp}-{{.ChecksumType}}.checksum"
  }

}
