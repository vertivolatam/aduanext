# AduaNext — Developer Makefile.
#
# Single entry point for local development. Targets grouped by area so
# `make help` stays scannable. New targets MUST be documented in the `##`
# comment on the same line — `make help` auto-generates from these.

SHELL := /bin/bash
.DEFAULT_GOAL := help

# Load .env if it exists (silently — devs without .env can still run some targets)
ifneq (,$(wildcard ./.env))
    include .env
    export
endif

COMPOSE ?= docker compose
PSQL_DEV_PORT ?= 8190
PSQL_TEST_PORT ?= 9190
PG_USER ?= $(POSTGRES_USER)
PG_USER := $(if $(PG_USER),$(PG_USER),postgres)
PG_DB ?= $(POSTGRES_DB)
PG_DB := $(if $(PG_DB),$(PG_DB),aduanext)
PG_TEST_DB ?= $(POSTGRES_TEST_DB)
PG_TEST_DB := $(if $(PG_TEST_DB),$(PG_TEST_DB),aduanext_test)

# ── Database ─────────────────────────────────────────────────────────
.PHONY: db-up
db-up: ## Start postgres + redis (dev + test) via docker compose
	$(COMPOSE) up -d postgres redis postgres_test redis_test
	@echo ""
	@echo "Waiting for services to be healthy..."
	@for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do \
		if $(COMPOSE) ps --format json | grep -q '"Health":"healthy"' && \
		   [ "$$($(COMPOSE) ps --format '{{.Health}}' | grep -c healthy)" -ge 4 ]; then \
			echo "All 4 services healthy."; break; \
		fi; sleep 2; \
	done
	@$(COMPOSE) ps

.PHONY: db-down
db-down: ## Stop all docker compose services (preserves volumes)
	$(COMPOSE) down

.PHONY: db-reset
db-reset: ## DESTRUCTIVE: stop + drop volumes + recreate
	$(COMPOSE) down -v
	$(COMPOSE) up -d postgres redis postgres_test redis_test

.PHONY: db-psql
db-psql: ## Open psql shell to dev database
	@PGPASSWORD="$(POSTGRES_PASSWORD)" psql -h localhost -p $(PSQL_DEV_PORT) -U $(PG_USER) -d $(PG_DB)

.PHONY: db-psql-test
db-psql-test: ## Open psql shell to test database
	@PGPASSWORD="$(POSTGRES_TEST_PASSWORD)" psql -h localhost -p $(PSQL_TEST_PORT) -U $(PG_USER) -d $(PG_TEST_DB)

.PHONY: db-verify-pgvector
db-verify-pgvector: ## Verify pgvector extension is available in dev DB
	@PGPASSWORD="$(POSTGRES_PASSWORD)" psql -h localhost -p $(PSQL_DEV_PORT) -U $(PG_USER) -d $(PG_DB) \
		-c "SELECT name, default_version FROM pg_available_extensions WHERE name='vector';"

# ── Tests ────────────────────────────────────────────────────────────
.PHONY: test-dart
test-dart: ## Run dart test on libs/domain and libs/adapters
	cd libs/domain && dart pub get && dart test
	cd libs/adapters && dart pub get && dart test

.PHONY: test-dart-domain
test-dart-domain: ## Run dart test on libs/domain only
	cd libs/domain && dart pub get && dart test

.PHONY: test-dart-adapters
test-dart-adapters: ## Run dart test on libs/adapters only (requires `make db-up`)
	cd libs/adapters && dart pub get && dart test

# ── Minikube + Helm ──────────────────────────────────────────────────
HELM_CHART_DIR ?= infrastructure/helm-charts/aduanext
HELM_RELEASE   ?= aduanext
K8S_NAMESPACE  ?= aduanext
MINIKUBE_PROFILE ?= aduanext
MINIKUBE_DRIVER  ?= docker
MINIKUBE_CPUS    ?= 4
MINIKUBE_MEMORY  ?= 6144

.PHONY: images-pull
images-pull: ## Pull all third-party container images required by docker-compose (run after `podman system prune`)
	podman pull docker.io/pgvector/pgvector:pg16
	podman pull quay.io/keycloak/keycloak:24.0
	podman pull docker.io/library/redis:6.2

.PHONY: minikube-up
minikube-up: ## Start minikube (profile: aduanext) with ingress + metrics
	# Some devs (incl. the founder) have `rootless: true` in their global
	# minikube config from previous projects. Force --rootless=false here
	# because Docker Desktop / standard docker.sock is not rootless.
	# Override with MINIKUBE_ROOTLESS=true if you actually run rootless docker.
	minikube start --profile=$(MINIKUBE_PROFILE) --driver=$(MINIKUBE_DRIVER) \
		--cpus=$(MINIKUBE_CPUS) --memory=$(MINIKUBE_MEMORY) \
		--rootless=$${MINIKUBE_ROOTLESS:-false} \
		--addons=ingress,metrics-server,dashboard
	@echo ""
	@echo "Cluster ready. Switch kubectl context with:"
	@echo "  kubectl config use-context $(MINIKUBE_PROFILE)"

.PHONY: minikube-down
minikube-down: ## Stop minikube (preserves disk)
	minikube stop --profile=$(MINIKUBE_PROFILE)

.PHONY: minikube-delete
minikube-delete: ## DESTRUCTIVE: delete the minikube profile (frees disk)
	minikube delete --profile=$(MINIKUBE_PROFILE)

.PHONY: minikube-status
minikube-status: ## Show minikube status + pods across all namespaces
	minikube status --profile=$(MINIKUBE_PROFILE)
	kubectl get pods -A

.PHONY: helm-deps
helm-deps: ## helm dependency update for the umbrella chart
	helm dependency update $(HELM_CHART_DIR)

.PHONY: helm-lint
helm-lint: ## helm lint the umbrella chart
	helm lint $(HELM_CHART_DIR)

.PHONY: helm-template
helm-template: ## helm template (dry render — no cluster needed)
	helm template $(HELM_RELEASE) $(HELM_CHART_DIR) --namespace $(K8S_NAMESPACE)

.PHONY: helm-install
helm-install: ## helm upgrade --install (requires running cluster)
	kubectl create namespace $(K8S_NAMESPACE) --dry-run=client -o yaml | kubectl apply -f -
	helm upgrade --install $(HELM_RELEASE) $(HELM_CHART_DIR) \
		--namespace $(K8S_NAMESPACE) \
		--wait --timeout 5m

.PHONY: helm-uninstall
helm-uninstall: ## helm uninstall the release (preserves the namespace)
	helm uninstall $(HELM_RELEASE) --namespace $(K8S_NAMESPACE)

.PHONY: k8s-logs
k8s-logs: ## Tail logs from all aduanext-labeled pods
	kubectl logs -n $(K8S_NAMESPACE) -l app.kubernetes.io/name=aduanext --all-containers --tail=100 -f

# ── ArgoCD (GitOps) ──────────────────────────────────────────────────
ARGOCD_DIR       ?= infrastructure/argocd
ARGOCD_NAMESPACE ?= argocd

.PHONY: argocd-install
argocd-install: ## Install ArgoCD (pinned v2.13.3) into the argocd namespace
	kubectl apply -f $(ARGOCD_DIR)/install.yaml
	kubectl apply -k $(ARGOCD_DIR)/
	@echo ""
	@echo "Waiting for argocd-server to become Ready (up to 5 min)..."
	kubectl wait --namespace $(ARGOCD_NAMESPACE) \
		--for=condition=available deployment/argocd-server \
		--timeout=5m
	@echo ""
	@echo "ArgoCD is up. Next steps:"
	@echo "  make argocd-admin-password   # get initial admin credentials"
	@echo "  make argocd-port-forward     # open UI at https://localhost:8081"
	@echo "  make argocd-app-create       # bootstrap the aduanext Application"

.PHONY: argocd-uninstall
argocd-uninstall: ## Uninstall ArgoCD (preserves argocd namespace)
	kubectl delete -k $(ARGOCD_DIR)/ --ignore-not-found
	@echo "To remove the namespace too: kubectl delete namespace $(ARGOCD_NAMESPACE)"

.PHONY: argocd-app-create
argocd-app-create: ## Create the AppProject + Application (hand GitOps the keys)
	kubectl apply -f $(ARGOCD_DIR)/app-project.yaml
	kubectl apply -f $(ARGOCD_DIR)/application.yaml
	@echo ""
	@echo "Application submitted. Watch initial sync with:"
	@echo "  kubectl get application -n $(ARGOCD_NAMESPACE) -w"

.PHONY: argocd-app-delete
argocd-app-delete: ## Delete the Application (children pruned via finalizer)
	kubectl delete -f $(ARGOCD_DIR)/application.yaml --ignore-not-found
	kubectl delete -f $(ARGOCD_DIR)/app-project.yaml --ignore-not-found

.PHONY: argocd-port-forward
argocd-port-forward: ## Port-forward the ArgoCD UI to https://localhost:8081
	@echo "ArgoCD UI: https://localhost:8081 (self-signed cert — ignore browser warning)"
	kubectl port-forward svc/argocd-server -n $(ARGOCD_NAMESPACE) 8081:443

.PHONY: argocd-admin-password
argocd-admin-password: ## Retrieve the auto-generated admin password
	@kubectl -n $(ARGOCD_NAMESPACE) get secret argocd-initial-admin-secret \
		-o jsonpath='{.data.password}' | base64 -d; echo

.PHONY: argocd-sync
argocd-sync: ## Force a sync of the aduanext Application (requires argocd CLI)
	argocd app sync aduanext

# ── Harbor (container registry) ──────────────────────────────────────
HARBOR_NAMESPACE ?= harbor
HARBOR_RELEASE   ?= harbor
HARBOR_PROJECT   ?= aduanext

.PHONY: harbor-install
harbor-install: ## Install Harbor registry into the harbor namespace
	./infrastructure/harbor/install.sh

.PHONY: harbor-uninstall
harbor-uninstall: ## Uninstall Harbor (preserves namespace + PVCs)
	helm uninstall $(HARBOR_RELEASE) --namespace $(HARBOR_NAMESPACE)

.PHONY: harbor-ui
harbor-ui: ## Print the URL for the Harbor web UI (via minikube service)
	minikube -p $(MINIKUBE_PROFILE) service $(HARBOR_RELEASE) --namespace $(HARBOR_NAMESPACE) --url | head -1

.PHONY: harbor-admin-password
harbor-admin-password: ## Print the Harbor admin password (dev: Harbor12345)
	@helm get values $(HARBOR_RELEASE) --namespace $(HARBOR_NAMESPACE) 2>/dev/null \
		| grep -E '^harborAdminPassword:' | awk '{print $$2}' | tr -d '"' || \
		echo "Harbor12345  # default from infrastructure/harbor/values.yaml"

.PHONY: harbor-login
harbor-login: ## docker login against the in-cluster Harbor
	@URL=$$(minikube -p $(MINIKUBE_PROFILE) service $(HARBOR_RELEASE) -n $(HARBOR_NAMESPACE) --url | head -1 | sed 's|http://||'); \
		echo "Logging in to $$URL as admin"; \
		docker login $$URL -u admin

.PHONY: harbor-push-server
harbor-push-server: ## PLACEHOLDER: tag + push the server image to Harbor
	@echo "This target is a placeholder until the Serverpod build pipeline exists."
	@echo "Manual push (example):"
	@echo "  URL=\$$(minikube -p $(MINIKUBE_PROFILE) service harbor -n harbor --url | head -1 | sed 's|http://||')"
	@echo "  docker tag nginx:alpine \$$URL/$(HARBOR_PROJECT)/server:dev"
	@echo "  docker push \$$URL/$(HARBOR_PROJECT)/server:dev"

# ── Help ─────────────────────────────────────────────────────────────
.PHONY: help
help: ## Print this help
	@echo ""
	@echo "AduaNext — Developer Makefile"
	@echo ""
	@echo "Usage: make <target>"
	@echo ""
	@awk 'BEGIN {FS = ":.*?## "} \
		/^[a-zA-Z0-9_-]+:.*?## / { printf "  \033[36m%-22s\033[0m %s\n", $$1, $$2 }' \
		$(MAKEFILE_LIST)
	@echo ""
