SHELL := /bin/bash

TF ?= terraform
WORKSPACE ?= dev
AWS_PROFILE ?= rentdirect

WORKSPACE_VARS := -var-file=envs/$(WORKSPACE).tfvars
DECRYPTED_ENV_FILE := envs/secrets/.env.$(WORKSPACE)
LOCK_FILE := s3://rentdirect-terraform-statefile/envs/$(WORKSPACE)/rentdirect.tfstate.tflock
LOAD_ENV := set -a && . "$(DECRYPTED_ENV_FILE)" && set +a

.PHONY: setup decrypt encrypt encrypt-all load-env fmt init reconfig guard-workspace workspace validate lint plan plan-nolock apply apply-plan show-egress-ip refresh destroy console list unlock


# Secrets
decrypt:
	@bash ../scripts/secrets/decrypt.sh $(WORKSPACE)

load-env: decrypt
	@if [ ! -f "$(DECRYPTED_ENV_FILE)" ]; then \
		echo "Error: $(DECRYPTED_ENV_FILE) not found. Run 'make decrypt' or create it from the matching .example file."; \
		exit 1; \
	fi

setup:
	@bash ../scripts/secrets/setup.sh

encrypt:
	@bash ../scripts/secrets/encrypt.sh $(WORKSPACE)

encrypt-all:
	@bash ../scripts/secrets/encrypt.sh dev
	@bash ../scripts/secrets/encrypt.sh prod

# Terraform
fmt:
	@$(TF) fmt -recursive

init: fmt
	@$(TF) init -input=false -upgrade

migrate-state: fmt
	@$(TF) init -migrate-state
	
reconfig: fmt
	@$(TF) init -input=false -reconfigure

guard-workspace:
	@case "$(WORKSPACE)" in \
		dev|prod) ;; \
		*) echo "Error: WORKSPACE must be 'dev' or 'prod', got '$(WORKSPACE)'." >&2; exit 1 ;; \
	esac
	@grep -Eq '^[[:space:]]*environment[[:space:]]*=[[:space:]]*"$(WORKSPACE)"' "envs/$(WORKSPACE).tfvars" || { \
		echo "Error: envs/$(WORKSPACE).tfvars does not declare environment = \"$(WORKSPACE)\"." >&2; \
		exit 1; \
	}

workspace: guard-workspace init
	@$(TF) workspace select $(WORKSPACE) >/dev/null 2>&1 || $(TF) workspace new $(WORKSPACE)
	@current_workspace="$$( $(TF) workspace show )"; \
	if [ "$$current_workspace" != "$(WORKSPACE)" ]; then \
		echo "Error: Terraform workspace is '$$current_workspace', expected '$(WORKSPACE)'." >&2; \
		exit 1; \
	fi

validate: load-env workspace
	@$(LOAD_ENV) && $(TF) validate

lint: validate
	@$(TF) fmt -diff -check -recursive

plan-nolock: validate
	@$(LOAD_ENV) && $(TF) plan $(WORKSPACE_VARS) -lock=false

plan: lint
	@$(LOAD_ENV) && $(TF) plan $(WORKSPACE_VARS) -out=tfplan

apply: plan
	@$(LOAD_ENV) && $(TF) apply tfplan
	@$(MAKE) show-egress-ip

show-ip:
	@egress_ip="$$( $(TF) output -raw static_egress_ip 2>/dev/null || true )"; \
	if [ -n "$$egress_ip" ]; then \
		echo "static_egress_ip = $$egress_ip"; \
	fi

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
