# sdv-ota-fleet-readiness

# Key points



## Design

### Considerations

#### Data plane

##### How might we split the responsibility of orchestration? 

Autonomous networking.

##### How might we realize a edge computing model that is cost effective but still flexible?
https://eclipse.dev/velocitas/docs/concepts/development_model/

##### How might we prove the authenticity of the data broker? 
The level of identity to prove will be at broker level for this purpose.  
The authenticity of each DATA BROKER is proved by possessing the certificate signed by a trusted CA.
The subject name of the Edge broker certificate will use base64 encoded string to represent a unique identifier of the Edge broker.

| Type  | Issuer type(Who am I) | Issuer (Trusted authority) | Subject                                                       |
|-------|-----------------------|----------------------------|---------------------------------------------------------------|
| Cloud | public                | LetsEncrypt                | CN=cloud.sdv.yuwlab.com                                       |
| Edge  | public                | LetsEncrypt                | CN=U2F0IE5vdiAyMSAxMDowMTo1MSBBTSBKU1QgMjAyNgo=.sdv.yulab.com |

#### How might we manage the lifecycle of the certificate?

| Vehicle Lifecycle | Certificate Lifecycle | User experience                                               |
|-------------------|-----------------------|---------------------------------------------------------------|
| acquisition       | issued                | Certificate will be deployed into the car at the time of sale |
| commissioning     | -                     | -                                                             |
| operation         | renew                 | Certficate will be updated at the time of inspection          |
| disposal          | revoke                | Certificate will be revoked when the user releases the car    |

#### How might we proxy the message to the cloud data broker?

Use MQTT over TLS using bridging.

#### How might we decouple the privilege of the certificate chain?

RFC7030

```markdown
Vehicle ---> Enrollment Service ---> Cloud Data Broker
```

### Tech stack

#### Cloud

| Category                    | Purpose                 | Component            |
|-----------------------------|-------------------------|----------------------|
| REST API                    | Gateway                 | Cloud API Gateway    |
| REST API                    | Service                 | Cloud Run Service    |
| Revisioned Persistent Store | Manifest Management     | Cloud Object Storage |
| Artifact                    | Container Repository    | Artifact Repository  |
| DWH                         | Vehicle state analytics | Bigquery             |
| Control Plane               | Release Pipeline        | n/z                  |
| Management Plane            | Campaign UI             | Streamlit            |
| Data Plane                  | Data broker             | EMQX on GKE          |
| Planes                      | Data                    | PubSub               |

#### Vehicle

| Layer    | Technology                              |
|----------|-----------------------------------------|
| OS       | debian13 on KVM                         |
| Platform | Container orchestrator <br> MQTT broker |
| Apps     | Container                               |

### Architecture

xxx

## Deployment lifecycle

### Init
#### Cloud setup

```shell
cd terraform
terraform init
terraform plan
terraform apply
```

#### EMQX setup

```shell
gcloud container clusters get-credentials data-plane-cluster --zone asia-northeast1-a
export KUBECONFIG=~/.kube/config

# Operator
helm repo add emqx https://repos.emqx.io/charts
helm install emqx-operator emqx/emqx-operator \
  --version 3.0.0 \
  --namespace emqx-operator-system \
  --create-namespace

# Cert manager
helm install \
  cert-manager oci://quay.io/jetstack/charts/cert-manager \
  --version v1.21.3 \
  --namespace cert-manager \
  --create-namespace \
  --set crds.enabled=true \
  --set serviceAccount.annotations."iam\.gke\.io/gcp-service-account"=dns01-solver@$(gcloud config get project).iam.gserviceaccount.com

# pki
helm install pki charts/pki \
  --namespace data-plane \
  --set google.project=$(gcloud config get project) \
  -f charts/pki/values_cloud.yaml

# Broker
helm install data-plane charts/data_plane \
  --namespace data-plane \
  --set emqxListener.loadBalancerIP=35.243.85.63 \
  --set emqxListener.loadBalancerSourceRanges={153.199.94.138/32}
```

#### Generate and sign certificate

Since there is no enrollment service, I will mimic the process.
EMQX requires the subjectAltName to be set to the UUID of the device
https://docs.emqx.com/en/emqx/latest/guides/access-control/authn/x509.html#initialize-client-attributes-from-certificate-subject-alternative-names
Use urn to identify the device.
# https://developer.mozilla.org/ja/docs/Web/URI/Reference/Schemes/urn

```shell
# Generate
openssl ecparam -out vehicle.key -name prime256v1 -genkey
export ID="ebd0f954-082a-438d-beea-0850826d5908"
openssl req -new -key vehicle.key \
    -subj "/CN=vehicle-$ID" \
    -addext "subjectAltName=URI:urn:uuid:$ID" \
    -out vehicle.csr

# Sign 
cat <<EOF | kubectl apply -n data-plane -f -
apiVersion: cert-manager.io/v1
kind: CertificateRequest
metadata: { name: vehicle-$ID, namespace: data-plane }
spec:
  request: $(base64 -w0 < vehicle.csr)
  isCA: false
  usages: [digital signature, client auth]
  duration: 8760h
  issuerRef: { name: vehicle-ca, kind: Issuer, group: cert-manager.io }
EOF

# Retrieve
kubectl get certificaterequest vehicle-$ID -n data-plane \
  -o jsonpath='{.status.certificate}' | base64 -d > vehicle.crt
```

#### Local vehicle setup

1. Create VM

```shell
# Deploy
sudo sh vm-init.sh

# Get kubeconfig
IPV4_ADDR=$(sudo virsh domifaddr vehicle | grep ipv4 | cut -f 15 -d ' ')
scp sdv@${IPV4_ADDR%\/*}:/etc/rancher/k3s/k3s.yaml .
sed -i "s|127.0.0.1|${IPV4_ADDR%\/*}|"  k3s.yaml
```

2.Deploy apps
```shell
export KUBECONFIG=k3s.yaml
# Deploy apps
helm install vehicle ./charts/vehicle \
  --namespace vehicle \
  --create-namespace \
  --set vehicle.tls.crt=$(base64 -w0 < vehicle.crt) \
  --set vehicle.tls.key=$(base64 -w0 < vehicle.key)
```

### Teardown

#### Cloud
```shell
cd terraform
terraform destroy
```

#### Local
```shell
sudo sh vm-teardown.sh
```