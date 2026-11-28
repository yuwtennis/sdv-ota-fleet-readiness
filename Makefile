PROJECT := $$(gcloud config get project)
EXTERNAL_IP := $$(gcloud compute addresses list --regions asia-northeast1 --filter='name=data-broker-listener-sdv-yulab-com' | grep EXTERNAL | cut -f 3 -d ' ')
NAT_IP := $$(curl -s ifconfig.me)/32
VEHICLE_CSR_PATH := ./vehicle.csr
VEHICLE_KUBE_CONFIG := k3s.yaml
CLOUD_KUBE_CONFIG := /home/ywatanabe/.kube/config

test:
	uv run ruff check \
		--config .ruff.toml \
		scripts/*.py \
		sdvotafleetreadiness/

build:
	docker build -t telemetry:latest .

push: build
	docker tag telemetry:latest asia-northeast1-docker.pkg.dev/$(PROJECT)/sdv-ota-fleet-readiness/telemetry:latest
	docker push asia-northeast1-docker.pkg.dev/$(PROJECT)/sdv-ota-fleet-readiness/telemetry:latest

deploy-cloud: push
	helm repo add emqx https://repos.emqx.io/charts
	helm install emqx-operator emqx/emqx-operator \
	  --kubeconfig=$(CLOUD_KUBE_CONFIG) \
	  --version 3.0.0 \
	  --namespace emqx-operator-system \
	  --create-namespace
	helm install cert-manager oci://quay.io/jetstack/charts/cert-manager \
	  --kubeconfig=$(CLOUD_KUBE_CONFIG) \
	  --version v1.21.3 \
	  --namespace cert-manager \
	  --create-namespace \
	  --set crds.enabled=true \
	  --set serviceAccount.annotations."iam\.gke\.io/gcp-service-account"="dns01-solver@$(PROJECT).iam.gserviceaccount.com"
	helm install pki charts/pki \
	  --kubeconfig=$(CLOUD_KUBE_CONFIG) \
	  --namespace data-plane \
	  --set google.project=$(PROJECT) \
	  --create-namespace
	helm install data-plane charts/data_plane \
	  --kubeconfig=$(CLOUD_KUBE_CONFIG) \
	  --namespace data-plane \
	  --set emqxListener.loadBalancerIP=$(EXTERNAL_IP) \
	  --set emqxListener.loadBalancerSourceRanges={$(NAT_IP)}

enroll-cred:
	# Elude the complicity of variable expansion order
	KUBECONFIG=$(CLOUD_KUBE_CONFIG) bash scripts/enroll-cred.sh

deploy-vehicle:
	helm install vehicle ./charts/vehicle \
		--kubeconfig=$(VEHICLE_KUBE_CONFIG) \
		--namespace vehicle \
		--create-namespace \
		--set vehicle.tls.crt=$$(base64 -w0 < vehicle.crt) \
		--set vehicle.tls.key=$$(base64 -w0 < vehicle.key)

clean-vehicle:
	helm uninstall vehicle -n vehicle --kubeconfig=$(VEHICLE_KUBE_CONFIG) ; \
	bash vm-teardown.sh ; \
	rm -f vehicle.*

clean-cloud:
	helm uninstall data-plane pki -n data-plane --kubeconfig=$(CLOUD_KUBE_CONFIG) ; \
	helm uninstall emqx-operator -n emqx-operator-system --kubeconfig=$(CLOUD_KUBE_CONFIG) ; \
	helm uninstall cert-manager -n cert-manager --kubeconfig=$(CLOUD_KUBE_CONFIG)

clean-infra:
	terraform -chdir=terraform/ destroy -auto-approve

clean-all: clean-vehicle clean-cloud clean-infra
	echo "Clean all"