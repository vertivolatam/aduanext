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
