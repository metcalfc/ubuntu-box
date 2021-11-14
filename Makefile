# Needed SHELL since I'm using zsh
SHELL := /bin/bash
.PHONY: help vmware virtualbox hyperv parallels qemu

help:
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make <target> \033[36m\033[0m\n"} /^[$$()% a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

vmware: ##
	packer build -only=vmware-iso.vmware ./ubuntu-20.04-amd64.pkr.hcl

virtualbox: ##
	packer build -only=virtualbox-iso.virtualbox ./ubuntu-20.04-amd64.pkr.hcl

hyperv: ##
	packer build -only=hyperv-iso.hyperv ./ubuntu-20.04-amd64.pkr.hcl

parallels: ##
	packer build -only=parallels-iso.parallels ./ubuntu-20.04-amd64.pkr.hcl

qemu: ##
	packer build -only=qemu.qemu ./ubuntu-20.04-amd64.pkr.hcl

clean:
	@rm -rf ./builds

all: help
