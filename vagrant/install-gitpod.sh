#!/bin/bash

NODE_IP="$(hostname -I | cut -d ' ' -f2)"

if [ -f ${HOME}/secrets/https-certificates/root_ca.crt ]; then
    step certificate install secrets/https-certificates/root_ca.crt
fi

kubectl create secret generic https-certificates --from-file=secrets/https-certificates

kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml
kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

gitpod-installer render -c config.yaml | kubectl apply -f -
kubectl wait --for=condition=Ready service/proxy
kubectl patch service proxy -p "{\"spec\":{\"externalIPs\":[\"${NODE_IP}\"]}}"
