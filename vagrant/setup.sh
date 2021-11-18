#!/bin/bash

set -eo pipefail

GITPOD_VERSION="main.1838"
# Install k3s
export INSTALL_K3S_SKIP_DOWNLOAD=true
export NODE_IP="$(hostname -I | cut -d ' ' -f2)"

cd /root

# Install smallstep to manage a self signed certificate authority
wget https://dl.step.sm/gh-release/cli/docs-ca-install/v0.17.5/step-cli_0.17.5_amd64.deb -P /tmp
sudo dpkg -i /tmp/step-cli_0.17.5_amd64.deb

wget https://dl.step.sm/gh-release/certificates/docs-ca-install/v0.17.4/step-ca_0.17.4_amd64.deb -P /tmp
sudo dpkg -i /tmp/step-ca_0.17.4_amd64.deb

rm -f /tmp/step-*deb



# shellcheck disable=SC2154
/usr/local/bin/install-k3s.sh \
    --container-runtime-endpoint=/var/run/containerd/containerd.sock \
    --write-kubeconfig-mode 400 \
    --token "${TOKEN}" \
    --node-ip "${NODE_IP}" \
    --node-label "gitpod.io/workload_headless=true" \
    --node-label "gitpod.io/workload_services=true" \
    --node-label "gitpod.io/workload_monitoring=true" \
    --node-label "gitpod.io/workload_workspace=true" \
    --disable servicelb \
    --disable traefik \
    --disable kube-proxy \
    --disable local-storage \
    --flannel-backend=none \
    --disable-cloud-controller \
    --disable-network-policy \
    --kubelet-arg config=/etc/kubernetes/kubelet-config.json \
    --cluster-init

# Life is too short to not have tab completion
sudo apt install bash-completion

cat <<EOF >> /root/.bashrc
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
source <(kubectl completion bash)
alias k=kubectl
complete -F __start_kubectl k
source <(helm completion bash)
source <(cilium completion bash)
EOF

mkdir -p /home/vagrant/.k3s
chmod 700 /home/vagrant/.k3s
chown vagrant:vagrant /home/vagrant/.k3s
cp /etc/rancher/k3s/k3s.yaml /home/vagrant/.k3s/k3s.yaml
chmod 400 /home/vagrant/.k3s/k3s.yaml
chown vagrant:vagrant /home/vagrant/.k3s/k3s.yaml

cat <<EOF >> /home/vagrant/.bashrc
export KUBECONFIG=~/.k3s/k3s.yaml
source <(kubectl completion bash)
alias k=kubectl
complete -F __start_kubectl k
source <(helm completion bash)
source <(cilium completion bash)
EOF

chown vagrant:vagrant /home/vagrant/.bashrc

# setup k8s access
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

# install Cilium as CNI provider
helm repo add cilium https://helm.cilium.io/
helm upgrade --install cilium cilium/cilium \
    --version 1.10.5 \
    --namespace kube-system \
    -f <(cat << EOF
k8sServiceHost: ${NODE_IP}
k8sServicePort: 6443
ipam:
  # Configure IP Address Management mode.
  # ref: https://docs.cilium.io/en/stable/concepts/networking/ipam/
  mode: kubernetes
nativeRoutingCIDR: 10.42.0.0/16
loadBalancer:
  mode: hybrid
containerRuntime:
  integration: containerd
k8s:
  requireIPv4PodCIDR: true
cni:
  chainingMode: portmap
hostPort:
  enabled: true
hostServices:
  enabled: true
nodePort:
  enabled: true
# Configure the kube-proxy replacement in Cilium BPF datapath
# ref: https://docs.cilium.io/en/stable/gettingstarted/kubeproxy-free/
#kubeProxyReplacement: probe
#kubeProxyReplacementHealthzBindAddr: 0.0.0.0:10276
#tunnel: disabled
l7Proxy: false
localRedirectPolicy: true
rollOutCiliumPods: true
operator:
  replicas: 1
bpf:
  clockProbe: true
  preallocateMaps: true
hubble:
  enabled: false
  relay:
    enabled: false
  ui:
    enabled: false
EOF
)

kubectl scale -n kube-system --replicas=1 deployment cilium-operator
sleep 20
kubectl get pods --all-namespaces -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,HOSTNETWORK:.spec.hostNetwork --no-headers=true | grep '<none>' | awk '{print "-n "$1" "$2}' | xargs -L 1 -r kubectl delete pod

# Test CNI:
# cilium status
# cilium connectivity test

# install cert-manager
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm upgrade --install cert-manager jetstack/cert-manager \
    --version v1.6.0 \
    --namespace kube-system \
    --wait \
    --set installCRDs=true

nerdctl run --rm -v /usr/local/bin:/tmp/copy \
  --entrypoint /bin/sh eu.gcr.io/gitpod-core-dev/build/installer:$GITPOD_VERSION \
  -c "cp /app/installer /tmp/copy/gitpod-installer"

wget https://github.com/coredns/coredns/releases/download/v1.8.6/coredns_1.8.6_linux_amd64.tgz
wget https://github.com/coredns/coredns/releases/download/v1.8.6/coredns_1.8.6_linux_amd64.tgz.sha256

if cat coredns_1.8.6_linux_amd64.tgz.sha256  | sha256sum --check; then
  tar zxvf coredns_1.8.6_linux_amd64.tgz -C /usr/bin/
  chmod +x /usr/bin/coredns
  rm -f coredns_1.8.6_linux_amd64.tgz*
else
  exit 1
fi

useradd -d /var/lib/coredns -m coredns

# Setup the resolver
apt install resolvconf
echo "dns=default" | sudo tee /etc/NetworkManager/NetworkManager.conf
echo "nameserver 127.0.0.1" /etc/resolvconf/resolv.conf.d/head

wget https://raw.githubusercontent.com/coredns/deployment/master/systemd/coredns-tmpfiles.conf -O  /usr/lib/tmpfiles.d/coredns-tmpfiles.conf
wget https://raw.githubusercontent.com/coredns/deployment/master/systemd/coredns-sysusers.conf -O  /usr/lib/sysusers.d/coredns-sysusers.conf
wget https://raw.githubusercontent.com/coredns/deployment/master/systemd/coredns.service -O /etc/systemd/system/coredns.service

mkdir -p /etc/coredns

cat << EOF > /etc/coredns/Corefile
. {
    forward . 127.0.0.1:5301 127.0.0.1:5302
}

.:5301 {
    forward . tls://9.9.9.9 tls://149.112.112.112 {
        tls_servername dns.quad9.net
        health_check 5s
    }
    cache
    errors
}

.:5302 {
    forward . tls://1.1.1.1 tls://1.0.0.1 {
       tls_servername cloudflare-dns.com
       health_check 5s
    }
    cache
    errors
}

home.vm {
    file /etc/coredns/db.home.vm
    errors
    log
}
EOF

cat << EOF > /etc/coredns/db.home.vm
\$ORIGIN home.vm.
\$TTL 86400
home.vm. IN SOA ns.home.vm. mail.home.vm. (
  2021071402; serial
  43200
  180
  1209600
  10800
)
home.vm.	NS	ns.home.vm.
ns.home.vm.	A	${NODE_IP}
*	3600	A	${NODE_IP}
EOF

chown coredns:coredns /etc/coredns/*

# Get rid of the old DNS
systemctl stop systemd-resolved && sudo systemctl disable systemd-resolved

# New DNS with *.home.vm.
systemctl enable coredns && systemctl start coredns
