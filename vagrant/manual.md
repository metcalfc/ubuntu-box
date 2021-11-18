step ca bootstrap --ca-url https://gitpod.you.ca.smallstep.com --fingerprint XYZ

step certificate install /home/vagrant/.step/certs/root_ca.crt

mkdir -p ~/secrets/https-certificates/

openssl dhparam -out ~/secrets/https-certificates/dhparams.pem 2048

kubectl create secret generic https-certificates --from-file=secrets/https-certificates
