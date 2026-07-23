SHELL := /bin/bash

TF ?= terraform
WORKSPACE ?= dev
AWS_PROFILE ?= root

WORKSPACE_VARS := -var-file=envs/$(WORKSPACE).tfvars
DECRYPTED_ENV_FILE := envs/secrets/.env.$(WORKSPACE)
LOCK_FILE := s3://rentdirect-statefile/envs/$(WORKSPACE)/rentdirect.tfstate.tflock
LOAD_ENV := set -a && . "$(DECRYPTED_ENV_FILE)" && set +a

.PHONY: setup decrypt encrypt encrypt-all load-env fmt init reconfig workspace validate lint plan plan-nolock apply apply-plan refresh destroy console list unlock

# Secrets
setup:
	@bash ../scripts/secrets/setup.sh

decrypt:
	@bash ../scripts/secrets/decrypt.sh $(WORKSPACE)

encrypt:
	@bash ../scripts/secrets/encrypt.sh $(WORKSPACE)

encrypt-all:
	@bash ../scripts/secrets/encrypt.sh dev
	@bash ../scripts/secrets/encrypt.sh prod

load-env:
	@if [ ! -f "$(DECRYPTED_ENV_FILE)" ]; then \
		echo "Error: $(DECRYPTED_ENV_FILE) not found. Run 'make decrypt' or create it from the matching .example file."; \
		exit 1; \
	fi

# Terraform
fmt:
	@$(TF) fmt -recursive

init: fmt
	@$(TF) init -input=false -upgrade

reconfig: fmt
	@$(TF) init -input=false -reconfigure

workspace: init
	@$(TF) workspace select $(WORKSPACE) >/dev/null 2>&1 || $(TF) workspace new $(WORKSPACE)

validate: load-env workspace
	@$(TF) fmt -diff -check -recursive
	@$(LOAD_ENV) && $(TF) validate

lint: validate

plan: validate
	@$(LOAD_ENV) && $(TF) plan $(WORKSPACE_VARS) -out=tfplan

plan-nolock: validate
	@$(LOAD_ENV) && $(TF) plan $(WORKSPACE_VARS) -lock=false

apply: plan
	@$(LOAD_ENV) && $(TF) apply tfplan

apply-plan: load-env workspace
	@if [ ! -f tfplan ]; then \
		echo "Error: tfplan not found. Run 'make plan' first."; \
		exit 1; \
	fi
	@$(LOAD_ENV) && $(TF) apply tfplan

refresh: validate
	@$(LOAD_ENV) && $(TF) refresh $(WORKSPACE_VARS)

destroy: validate
	@$(LOAD_ENV) && $(TF) destroy $(WORKSPACE_VARS)

console: validate
	@$(LOAD_ENV) && $(TF) console $(WORKSPACE_VARS)

list: workspace
	@$(TF) state list

unlock:
	@if pgrep -x terraform-ls >/dev/null; then \
		pkill -x terraform-ls; \
		sleep 2; \
	fi
	@if aws s3 ls $(LOCK_FILE) --profile $(AWS_PROFILE) >/dev/null 2>&1; then \
		echo "Lock file found, removing..."; \
		aws s3 rm $(LOCK_FILE) --profile $(AWS_PROFILE); \
	else \
		echo "No lock file found"; \
	fi
