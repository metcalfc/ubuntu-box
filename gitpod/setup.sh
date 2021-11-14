#!/bin/bash

set -e
set -x
export DEBIAN_FRONTEND=noninteractive

# Copy files
cp /tmp/limits.conf                 /etc/security/limits.conf
cp /tmp/11-network-security.conf    /etc/sysctl.d/
cp /tmp/89-gce.conf                 /etc/sysctl.d/
cp /tmp/99-defaults.conf            /etc/sysctl.d/

mkdir -p /etc/kubernetes/
cp /tmp/kubelet-config.json         /etc/kubernetes/kubelet-config.json

# Enable stargz-snapshotter plugin
mkdir -p /etc/containerd/
cp /tmp/containerd.toml             /etc/containerd/config.toml

# Update OS
apt update && apt dist-upgrade -y

# Install required packages
apt --no-install-recommends install -y \
  apt-transport-https ca-certificates curl gnupg2 software-properties-common \
  iptables libseccomp2 socat conntrack ipset \
  fuse \
  jq \
  iproute2 \
  auditd \
  ethtool \
  net-tools

# Enable modules
cat <<EOF > /etc/modules-load.d/k8s.conf
br_netfilter
overlay
fuse
shiftfs
EOF

# Disable modules
cat <<EOF > /etc/modprobe.d/kubernetes-blacklist.conf
blacklist dccp
blacklist sctp
EOF

# Enable cgroups2
sed -i 's/GRUB_CMDLINE_LINUX="\(.*\)"/GRUB_CMDLINE_LINUX="systemd.unified_cgroup_hierarchy=1 \1"/g' /etc/default/grub

apt install dkms -y

# https://github.com/containerd/stargz-snapshotter/issues/520
# Install linux kernel 5.14
add-apt-repository -y ppa:tuxinvader/lts-mainline
apt-get update
apt-get install -y linux-generic-5.14

# Install containerd
curl -sSL https://github.com/containerd/nerdctl/releases/download/v0.13.0/nerdctl-full-0.13.0-linux-amd64.tar.gz -o - | tar -xz -C /usr/local

# copy the portmap plugin to support hostport
mkdir -p /opt/cni/bin
ln -s /usr/local/libexec/cni/portmap /opt/cni/bin

mkdir -p /etc/containerd /etc/containerd/certs.d

cp /usr/local/lib/systemd/system/* /lib/systemd/system/
sed -i 's/--log-level=debug//g' /lib/systemd/system/stargz-snapshotter.service

cp /usr/local/lib/systemd/system/* /lib/systemd/system/

# configure stargz-snapshotter plugin
mkdir -p /etc/containerd-stargz-grpc
touch /etc/containerd-stargz-grpc/config.toml

# Disable software irqbalance service
systemctl stop irqbalance.service     || true
systemctl disable irqbalance.service  || true

# Reload systemd
systemctl daemon-reload

# Start containerd and stargz
systemctl enable containerd
systemctl enable stargz-snapshotter

# Download k3s tar file to improve initial start time and remove dependency of Internet connection
mkdir -p /var/lib/rancher/k3s/agent/images/
curl -sSL "https://github.com/k3s-io/k3s/releases/download/v1.22.3%2Bk3s1/k3s-airgap-images-amd64.tar" \
  -o /var/lib/rancher/k3s/agent/images/k3s-airgap-images-amd64.tar

# Download k3s binary
curl -sSL "https://github.com/k3s-io/k3s/releases/download/v1.22.3%2Bk3s1/k3s" -o /usr/local/bin/k3s
chmod +x /usr/local/bin/k3s

# Download k3s install script
curl -sSL https://get.k3s.io/ -o /usr/local/bin/install-k3s.sh
chmod +x /usr/local/bin/install-k3s.sh

# Install helm
curl -fsSL https://get.helm.sh/helm-v3.7.0-linux-amd64.tar.gz -o - | tar -xzvC /tmp/ --strip-components=1
cp /tmp/helm /usr/local/bin/helm

curl -sSL --remote-name-all https://github.com/cilium/cilium-cli/releases/latest/download/cilium-linux-amd64.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-amd64.tar.gz.sha256sum
tar xzvfC cilium-linux-amd64.tar.gz /usr/local/bin
rm cilium-linux-amd64.tar.gz{,.sha256sum}

rm /etc/resolv.conf
echo "nameserver 8.8.8.8" > /etc/resolv.conf

exit 0
