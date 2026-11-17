
test:
	uv run ruff check \
		--config .ruff.toml \
		scripts/*.py \
		sdvotafleetreadiness/

build:
	docker build -t app:latest .

chart-cloud:
	gcloud container clusters get-credentials data-plane-cluster --zone asia-northeast1-a
    export KUBECONFIG=~/.kube/config
    helm repo add emqx https://repos.emqx.io/charts
    helm install emqx-operator emqx/emqx-operator \
      --version 3.0.0 \
      --namespace emqx-operator-system \
      --create-namespace
    helm install \
      cert-manager oci://quay.io/jetstack/charts/cert-manager \
      --version v1.21.3 \
      --namespace cert-manager \
      --create-namespace \
      --set crds.enabled=true
    helm install data-plane charts/data_plane \
      --namespace data-plane \
      --create-namespace