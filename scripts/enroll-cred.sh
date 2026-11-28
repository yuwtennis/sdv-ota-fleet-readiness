#!/usr/bin/env bash -e

ID="ebd0f954-082a-438d-beea-0850826d5908"
SCRIPT_DIR=$(dirname "$0")
CERT_PATH="${SCRIPT_DIR}/.."

function gen_vehicle_key() {
  # Generate
  openssl ecparam -out vehicle.key -name prime256v1 -genkey
  openssl req -new -key ${CERT_PATH}/vehicle.key \
      -subj "/CN=vehicle-$ID" \
      -addext "subjectAltName=URI:urn:uuid:$ID" \
      -out ${CERT_PATH}/vehicle.csr
}

function enroll_vehicle_cred() {
  # Sign
  cat <<EOF | kubectl apply -n data-plane --kubeconfig=$KUBECONFIG -f -
apiVersion: cert-manager.io/v1
kind: CertificateRequest
metadata: { name: vehicle-$ID, namespace: data-plane }
spec:
  request: $(base64 -w0 ${CERT_PATH}/vehicle.csr)
  isCA: false
  usages: [digital signature, client auth]
  duration: 8760h
  issuerRef: { name: vehicle-ca, kind: Issuer, group: cert-manager.io }
EOF

  # Retrieve
  kubectl get certificaterequest vehicle-$ID -n data-plane \
    --kubeconfig=$KUBECONFIG \
    -o jsonpath='{.status.certificate}' | base64 -d > ${CERT_PATH}/vehicle.crt
}

gen_vehicle_key
enroll_vehicle_cred