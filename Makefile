# Local helpers for this packaging repo.
# Full Asterisk compiles are slow — prefer `make smoke` against GHCR during day-to-day work.

IMAGE ?= asterisk:dev
PUBLISHED ?= ghcr.io/pmastalerz/asterisk:latest
ASTERISK_VERSION := $(shell tr -d '[:space:]' < VERSION)
ASTERISK_SHA256 := $(shell tr -d '[:space:]' < ASTERISK_SHA256)
BUILD_DATE ?= $(shell date -u +%Y-%m-%dT%H:%M:%SZ)
VERSION ?= dev

.PHONY: help build smoke smoke-published shellcheck

help:
	@echo "Targets:"
	@echo "  make build             Full local image build (compiles Asterisk)"
	@echo "  make smoke             Smoke-test IMAGE ($(IMAGE))"
	@echo "  make smoke-published   Smoke-test $(PUBLISHED)"
	@echo "  make shellcheck        Lint shell scripts"

build:
	docker build \
	  --build-arg ASTERISK_VERSION="$(ASTERISK_VERSION)" \
	  --build-arg ASTERISK_SHA256="$(ASTERISK_SHA256)" \
	  --build-arg VERSION="$(VERSION)" \
	  --build-arg BUILD_DATE="$(BUILD_DATE)" \
	  -t "$(IMAGE)" .

smoke:
	./scripts/smoke-test.sh "$(IMAGE)"

smoke-published:
	docker pull "$(PUBLISHED)"
	./scripts/smoke-test.sh "$(PUBLISHED)"

shellcheck:
	shellcheck -x root/entrypoint.sh root/app/seed-config.sh root/app/seed-varlib.sh root/healthcheck.sh \
	  scripts/smoke-test.sh build/menuselect-config.sh
