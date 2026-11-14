# sdv-ota-fleet-readiness

# Key points



## Design

### Considerations

- Autonomous network
- Edge computing
https://eclipse.dev/velocitas/docs/concepts/development_model/

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

#### Local vehicle setup

1. Create VM

```shell
# Deploy
sudo vm-init.sh

# Get kubeconfig
IPV4_ADDR=$(sudo virsh domifaddr vehicle | grep ipv4 | cut -f 15 -d ' ')
scp sdv@${IPV4_ADDR%\/*}:/etc/rancher/k3s/k3s.yaml .
sed -i "s|127.0.0.1|${IPV4_ADDR%\/*}|"  k3s.yaml
```

2. Deploy apps
```shell
# Deploy apps
helm install --kubeconfig k3s.yaml vehicle ./charts/
```

### Update

```shell
# Deploy apps
helm upgrade --kubeconfig k3s.yaml vehicle ./charts/
```

### Teardown

```shell
sudo vm-teardown.sh
```