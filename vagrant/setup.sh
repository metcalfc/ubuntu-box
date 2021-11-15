#!/bin/bash

set -eo pipefail

cd /root

# Install smallstep to manage a self signed certificate authority
wget https://dl.step.sm/gh-release/cli/docs-ca-install/v0.17.5/step-cli_0.17.5_amd64.deb -P /tmp
sudo dpkg -i /tmp/step-cli_0.17.5_amd64.deb

wget https://dl.step.sm/gh-release/certificates/docs-ca-install/v0.17.4/step-ca_0.17.4_amd64.deb -P /tmp
sudo dpkg -i /tmp/step-ca_0.17.4_amd64.deb

rm -f /tmp/step-*deb

# Install k3s
export INSTALL_K3S_SKIP_DOWNLOAD=true
export NODE_IP="$(hostname -I | cut -d ' ' -f1)"

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
