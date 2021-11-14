# This file was autogenerated by the 'packer hcl2_upgrade' command. We
# recommend double checking that everything is correct before going forward. We
# also recommend treating this file as disposable. The HCL2 blocks in this
# file can be moved to other files. For example, the variable blocks could be
# moved to their own 'variables.pkr.hcl' file, etc. Those files need to be
# suffixed with '.pkr.hcl' to be visible to Packer. To use multiple files at
# once they also need to be in the same folder. 'packer inspect folder/'
# will describe to you what is in that folder.

# Avoid mixing go templating calls ( for example ```{{ upper(`string`) }}``` )
# and HCL2 calls (for example '${ var.string_value_example }' ). They won't be
# executed together and the outcome will be unknown.

# All generated input variables will be of 'string' type as this is how Packer JSON
# views them; you can change their type later on. Read the variables type
# constraints documentation
# https://www.packer.io/docs/templates/hcl_templates/variables#type-constraints for more info.
variable "box_basename" {
  type    = string
  default = "ubuntu-20.04"
}

variable "build_directory" {
  type    = string
  default = "./builds"
}

variable "cpus" {
  type    = string
  default = "4"
}

variable "disk_size" {
  type    = string
  default = "65536"
}

variable "git_revision" {
  type    = string
  default = "__unknown_git_revision__"
}

variable "guest_additions_url" {
  type    = string
  default = ""
}

variable "headless" {
  type    = string
  default = "true"
}

variable "http_proxy" {
  type    = string
  default = "${env("http_proxy")}"
}

variable "https_proxy" {
  type    = string
  default = "${env("https_proxy")}"
}

variable "hyperv_switch" {
  type    = string
  default = "Default"
}

variable "iso_checksum" {
  type    = string
  default = "f8e3086f3cea0fb3fefb29937ab5ed9d19e767079633960ccb50e76153effc98"
}

variable "iso_name" {
  type    = string
  default = "ubuntu-20.04.3-live-server-amd64.iso"
}

variable "memory" {
  type    = string
  default = "16384"
}

variable "mirror" {
  type    = string
  default = "http://releases.ubuntu.com"
}

variable "mirror_directory" {
  type    = string
  default = "focal"
}

variable "name" {
  type    = string
  default = "ubuntu-20.04"
}

variable "no_proxy" {
  type    = string
  default = "${env("no_proxy")}"
}

variable "preseed_path" {
  type    = string
  default = "preseed.cfg"
}

variable "qemu_display" {
  type    = string
  default = "none"
}

variable "template" {
  type    = string
  default = "ubuntu-20.04-amd64"
}



locals {
  version        = timestamp()
  http_directory = "${path.root}/http"
}
# source blocks are generated from your builders; a source can be referenced in
# build blocks. A build block runs provisioner and post-processors on a
# source. Read the documentation for source blocks here:
# https://www.packer.io/docs/templates/hcl_templates/blocks/source
source "hyperv-iso" "hyperv" {
  boot_command       = [" <wait>", " <wait>", " <wait>", " <wait>", " <wait>", "<esc><wait>", "<f6><wait>", "<esc><wait>", "<bs><bs><bs><bs><wait>", " autoinstall<wait5>", " ds=nocloud-net<wait5>", ";s=http://<wait5>{{ .HTTPIP }}<wait5>:{{ .HTTPPort }}/<wait5>", " ---<wait5>", "<enter><wait5>"]
  boot_wait          = "5s"
  communicator       = "ssh"
  cpus               = "${var.cpus}"
  disk_size          = "${var.disk_size}"
  enable_secure_boot = false
  enable_virtualization_extensions = true
  # These next two are required for nested virtualization
  enable_dynamic_memory = false
  enable_mac_spoofing = true
  generation         = 2
  http_directory     = "${local.http_directory}"
  iso_checksum       = "${var.iso_checksum}"
  iso_url            = "${var.mirror}/${var.mirror_directory}/${var.iso_name}"
  memory             = "${var.memory}"
  output_directory   = "${var.build_directory}/packer-${var.template}-hyperv"
  shutdown_command   = "echo 'vagrant' | sudo -S shutdown -P now"
  ssh_password       = "vagrant"
  ssh_port           = 22
  ssh_timeout        = "10000s"
  ssh_username       = "vagrant"
  switch_name        = "${var.hyperv_switch}"
  vm_name            = "${var.template}"
}

source "parallels-iso" "parallels" {
  boot_command           = [" <wait>", " <wait>", " <wait>", " <wait>", " <wait>", "<esc><wait>", "<f6><wait>", "<esc><wait>", "<bs><bs><bs><bs><wait>", " autoinstall<wait5>", " ds=nocloud-net<wait5>", ";s=http://<wait5>{{ .HTTPIP }}<wait5>:{{ .HTTPPort }}/<wait5>", " ---<wait5>", "<enter><wait5>"]
  boot_wait              = "5s"
  cpus                   = "${var.cpus}"
  disk_size              = "${var.disk_size}"
  guest_os_type          = "ubuntu"
  http_directory         = "${local.http_directory}"
  iso_checksum           = "${var.iso_checksum}"
  iso_url                = "${var.mirror}/${var.mirror_directory}/${var.iso_name}"
  memory                 = "${var.memory}"
  output_directory       = "${var.build_directory}/packer-${var.template}-parallels"
  parallels_tools_flavor = "lin"
  prlctl_version_file    = ".prlctl_version"
  shutdown_command       = "echo 'vagrant' | sudo -S shutdown -P now"
  ssh_password           = "vagrant"
  ssh_port               = 22
  ssh_timeout            = "10000s"
  ssh_username           = "vagrant"
  vm_name                = "${var.template}"
}

source "qemu" "qemu" {
  boot_command     = [" <wait>", " <wait>", " <wait>", " <wait>", " <wait>", "<esc><wait>", "<f6><wait>", "<esc><wait>", "<bs><bs><bs><bs><wait>", " autoinstall<wait5>", " ds=nocloud-net<wait5>", ";s=http://<wait5>{{ .HTTPIP }}<wait5>:{{ .HTTPPort }}/<wait5>", " ---<wait5>", "<enter><wait5>"]
  boot_wait        = "5s"
  cpus             = "${var.cpus}"
  disk_size        = "${var.disk_size}"
  headless         = "${var.headless}"
  http_directory   = "${local.http_directory}"
  iso_checksum     = "${var.iso_checksum}"
  iso_url          = "${var.mirror}/${var.mirror_directory}/${var.iso_name}"
  memory           = "${var.memory}"
  output_directory = "${var.build_directory}/packer-${var.template}-qemu"
  qemuargs         = [["-m", "${var.memory}"], ["-display", "${var.qemu_display}"]]
  shutdown_command = "echo 'vagrant' | sudo -S shutdown -P now"
  ssh_password     = "vagrant"
  ssh_port         = 22
  ssh_timeout      = "10000s"
  ssh_username     = "vagrant"
  vm_name          = "${var.template}"
}

source "virtualbox-iso" "virtualbox" {
  boot_command            = [" <wait>", " <wait>", " <wait>", " <wait>", " <wait>", "<esc><wait>", "<f6><wait>", "<esc><wait>", "<bs><bs><bs><bs><wait>", " autoinstall<wait5>", " ds=nocloud-net<wait5>", ";s=http://<wait5>{{ .HTTPIP }}<wait5>:{{ .HTTPPort }}/<wait5>", " ---<wait5>", "<enter><wait5>"]
  boot_wait               = "5s"
  cpus                    = "${var.cpus}"
  disk_size               = "${var.disk_size}"
  guest_additions_path    = "VBoxGuestAdditions_{{ .Version }}.iso"
  guest_additions_url     = "${var.guest_additions_url}"
  guest_os_type           = "Ubuntu_64"
  hard_drive_interface    = "sata"
  headless                = "${var.headless}"
  http_directory          = "${local.http_directory}"
  iso_checksum            = "${var.iso_checksum}"
  iso_url                 = "${var.mirror}/${var.mirror_directory}/${var.iso_name}"
  memory                  = "${var.memory}"
  nested_virt             = "true"
  output_directory        = "${var.build_directory}/packer-${var.template}-virtualbox"
  shutdown_command        = "echo 'vagrant' | sudo -S shutdown -P now"
  ssh_password            = "vagrant"
  ssh_port                = 22
  ssh_timeout             = "10000s"
  ssh_username            = "vagrant"
  virtualbox_version_file = ".vbox_version"
  vm_name                 = "${var.template}"
}

source "vmware-iso" "vmware" {
  boot_command        = [" <wait>", " <wait>", " <wait>", " <wait>", " <wait>", "<esc><wait>", "<f6><wait>", "<esc><wait>", "<bs><bs><bs><bs><wait>", " autoinstall<wait5>", " ds=nocloud-net<wait5>", ";s=http://<wait5>{{ .HTTPIP }}<wait5>:{{ .HTTPPort }}/<wait5>", " ---<wait5>", "<enter><wait5>"]
  boot_wait           = "5s"
  cpus                = "${var.cpus}"
  disk_size           = "${var.disk_size}"
  guest_os_type       = "ubuntu-64"
  headless            = "${var.headless}"
  http_directory      = "${local.http_directory}"
  iso_checksum        = "${var.iso_checksum}"
  iso_url             = "${var.mirror}/${var.mirror_directory}/${var.iso_name}"
  memory              = "${var.memory}"
  output_directory    = "${var.build_directory}/packer-${var.template}-vmware"
  shutdown_command    = "echo 'vagrant' | sudo -S shutdown -P now"
  ssh_password        = "vagrant"
  ssh_port            = 22
  ssh_timeout         = "10000s"
  ssh_username        = "vagrant"
  tools_upload_flavor = "linux"
  vm_name             = "${var.template}"
  vmx_data = {
    "cpuid.coresPerSocket"    = "1"
    "ethernet0.pciSlotNumber" = "32"
    "featMask.vm.hv.capable"  = "Min:1"
    "vhv.enable"              = "true"
  }
  vmx_remove_ethernet_interfaces = true
}

build {
  sources = ["source.hyperv-iso.hyperv", "source.parallels-iso.parallels", "source.qemu.qemu", "source.virtualbox-iso.virtualbox", "source.vmware-iso.vmware"]

  provisioner "shell" {
    environment_vars  = ["HOME_DIR=/home/vagrant", "http_proxy=${var.http_proxy}", "https_proxy=${var.https_proxy}", "no_proxy=${var.no_proxy}"]
    execute_command   = "echo 'vagrant' | {{ .Vars }} sudo -S -E sh -eux '{{ .Path }}'"
    expect_disconnect = true
    scripts = ["${path.root}/scripts/update.sh",
      "${path.root}/scripts/motd.sh",
      "${path.root}/scripts/sshd.sh",
      "${path.root}/scripts/networking.sh",
      "${path.root}/scripts/sudoers.sh",
      "${path.root}/scripts/vagrant.sh",
      "${path.root}/scripts/virtualbox.sh",
      "${path.root}/scripts/vmware.sh",
      "${path.root}/scripts/parallels.sh",
      "${path.root}/scripts/hyperv.sh",
      "${path.root}/scripts/cleanup.sh",
      "${path.root}/scripts/minimize.sh"]
  }

  provisioner "file" {
    source      = "${path.root}/gitpod/limits.conf"
    destination = "/tmp/limits.conf"
  }

  provisioner "file" {
    source      = "${path.root}/gitpod/containerd.toml"
    destination = "/tmp/containerd.toml"
  }

  provisioner "file" {
    source      = "${path.root}/gitpod/setup.sh"
    destination = "/tmp/setup.sh"
  }

  provisioner "file" {
    source      = "${path.root}/gitpod/kubelet-config.json"
    destination = "/tmp/kubelet-config.json"
  }

  provisioner "file" {
    source      = "${path.root}/gitpod/sysctl/11-network-security.conf"
    destination = "/tmp/11-network-security.conf"
  }

  provisioner "file" {
    source      = "${path.root}/gitpod/sysctl/89-gce.conf"
    destination = "/tmp/89-gce.conf"
  }

  provisioner "file" {
    source      = "${path.root}/gitpod/sysctl/99-defaults.conf"
    destination = "/tmp/99-defaults.conf"
  }

  provisioner "shell" {
    inline = [
      "chmod +x /tmp/setup.sh",
      "sudo bash -c /tmp/setup.sh",
      "sleep 10",
      "sudo reboot"
    ]
    expect_disconnect = true
  }

  # Compile shiftfs after rebooting the VM with the new kernel
  provisioner "shell" {
    inline = [
      "git clone -b k5.13 https://github.com/toby63/shiftfs-dkms.git /tmp/shiftfs-k513",
      "cd /tmp/shiftfs-k513; sudo make -f Makefile.dkms",
      "sudo modinfo shiftfs"
    ]
  }

  provisioner "shell" {
    environment_vars  = ["HOME_DIR=/home/vagrant", "http_proxy=${var.http_proxy}", "https_proxy=${var.https_proxy}", "no_proxy=${var.no_proxy}"]
    execute_command   = "echo 'vagrant' | {{ .Vars }} sudo -S -E sh -eux '{{ .Path }}'"
    expect_disconnect = true
    scripts = ["${path.root}/scripts/virtualbox.sh",
      "${path.root}/scripts/vmware.sh",
      "${path.root}/scripts/parallels.sh",
      "${path.root}/scripts/hyperv.sh",
     "${path.root}/scripts/cleanup.sh",
     "${path.root}/scripts/minimize.sh"]
  }

  post-processor "vagrant" {
    output = "${var.build_directory}/${var.box_basename}.${local.version}.box"
  }
}
