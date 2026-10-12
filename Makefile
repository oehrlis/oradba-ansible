# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: Makefile
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026.10.12
# Revision...: 0.1.0
# Purpose....: Development workflow for the oradba.automation collection:
#              setup, lint, molecule, build and release.
# Notes......: Use 'make help' to show all available targets. Tooling lives in
#              .venv (make setup); the collection is linked into .collections
#              so that playbooks and molecule resolve oradba.automation.*.
# Reference..: https://github.com/oehrlis/oradba-ansible
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

SHELL := /usr/bin/env bash
.DEFAULT_GOAL := help

VERSION := $(shell cat VERSION 2>/dev/null || echo "0.0.0")
DIST ?= dist
VENV ?= .venv
BIN := $(VENV)/bin
COLLECTIONS := .collections
COLL_LINK := $(COLLECTIONS)/ansible_collections/oradba/automation
TARBALL := $(DIST)/oradba-automation-$(VERSION).tar.gz
MARKDOWNLINT := $(shell command -v markdownlint 2>/dev/null || command -v markdownlint-cli 2>/dev/null)
export ANSIBLE_COLLECTIONS_PATH := $(CURDIR)/$(COLLECTIONS):$(HOME)/.ansible/collections

.PHONY: help
help: ## Show this help message
	@echo "oradba.automation $(VERSION)"
	@grep -E '^[a-z0-9-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[32m%-18s\033[0m %s\n", $$1, $$2}'

# ==============================================================================
# Setup
# ==============================================================================

.PHONY: setup
setup: $(BIN)/ansible-lint link ## Create .venv with the dev tooling and link the collection

$(BIN)/ansible-lint: requirements-dev.txt
	uv venv -q -p 3.12 $(VENV)
	uv pip install -q -p $(BIN)/python -r requirements-dev.txt
	@touch $@

.PHONY: deps
deps: link ## Install the molecule-only collections into .collections
	$(BIN)/ansible-galaxy collection install -r extensions/molecule/requirements.yml -p $(COLLECTIONS)

.PHONY: link
link: ## Link this checkout as oradba.automation into .collections
	@mkdir -p $(dir $(COLL_LINK))
	@ln -sfn ../../.. $(COLL_LINK)
	@echo "linked $(COLL_LINK) -> $(CURDIR)"

# ==============================================================================
# Lint
# ==============================================================================

.PHONY: lint
lint: lint-version lint-ignored lint-yaml lint-ansible lint-markdown ## Run all linters

.PHONY: lint-version
lint-version: ## Check VERSION, galaxy.yml and CHANGELOG agree
	@gv=$$(awk '/^version:/ {print $$2}' galaxy.yml); \
	[[ "$$gv" == "$(VERSION)" ]] || { echo "galaxy.yml version $$gv != VERSION $(VERSION)"; exit 1; }; \
	grep -q "^## \[$(VERSION)\]" CHANGELOG.md || { echo "CHANGELOG.md has no section for $(VERSION)"; exit 1; }; \
	echo "version $(VERSION) consistent"

.PHONY: lint-ignored
lint-ignored: ## Fail when .gitignore hides collection content (it would pass locally, break in CI)
	@hidden=$$(git ls-files --others --ignored --exclude-standard -- roles playbooks examples extensions docs meta); \
	[[ -z "$$hidden" ]] || { echo "ignored by .gitignore but part of the collection:"; echo "$$hidden"; exit 1; }; \
	echo "no collection content hidden by .gitignore"

.PHONY: lint-yaml
lint-yaml: ## Run yamllint
	$(BIN)/yamllint -s .

.PHONY: lint-ansible
lint-ansible: link ## Run ansible-lint (profile production)
	$(BIN)/ansible-lint

.PHONY: lint-markdown
lint-markdown: ## Run markdownlint
	@if [[ -z "$(MARKDOWNLINT)" ]]; then echo "markdownlint not found - install markdownlint-cli"; exit 1; fi
	$(MARKDOWNLINT) --ignore .venv --ignore .collections --ignore tasks --ignore dist '**/*.md'

.PHONY: syntax
syntax: link ## Syntax-check the playbooks
	@for p in playbooks/*.yml; do \
		$(BIN)/ansible-playbook -i localhost, --syntax-check "$$p" || exit 1; \
	done

# ==============================================================================
# Test
# ==============================================================================

.PHONY: molecule
molecule: deps ## Run the molecule default scenario (OL8 and OL9)
	cd extensions && PATH="$(CURDIR)/$(BIN):$$PATH" ../$(BIN)/molecule test -s default $(MOLECULE_ARGS)

.PHONY: molecule-converge
molecule-converge: deps ## Converge only, keep containers for debugging
	cd extensions && PATH="$(CURDIR)/$(BIN):$$PATH" ../$(BIN)/molecule converge -s default

.PHONY: molecule-destroy
molecule-destroy: ## Remove the molecule containers
	cd extensions && PATH="$(CURDIR)/$(BIN):$$PATH" ../$(BIN)/molecule destroy -s default

.PHONY: test
test: lint syntax molecule ## Lint, syntax check and molecule

.PHONY: ci
ci: lint syntax ## Checks without containers (the CI lint job)

# ==============================================================================
# Build and release
# ==============================================================================

.PHONY: build
build: lint-version ## Build the collection tarball plus sha256 into dist/
	@mkdir -p $(DIST)
	$(BIN)/ansible-galaxy collection build --force --output-path $(DIST) .
	@cd $(DIST) && shasum -a 256 oradba-automation-$(VERSION).tar.gz > oradba-automation-$(VERSION).tar.gz.sha256
	@cat $(TARBALL).sha256

.PHONY: tag
tag: lint-version ## Create tag v$(VERSION) and push branch plus tag
	@[[ -z "$$(git status --porcelain)" ]] || { echo "working tree not clean"; exit 1; }
	git tag -a "v$(VERSION)" -m "oradba.automation $(VERSION)"
	git push origin "$$(git rev-parse --abbrev-ref HEAD)"
	git push origin "v$(VERSION)"
	@git ls-remote --tags origin "v$(VERSION)" | grep -q . && echo "tag v$(VERSION) is on origin"

.PHONY: clean
clean: ## Remove build output
	rm -rf $(DIST)
