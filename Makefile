PROJECT := $$(gcloud config get project)

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