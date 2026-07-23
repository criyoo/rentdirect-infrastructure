SHELL := /bin/bash

TF ?= terraform
WORKSPACE ?= dev
AWS_USE_PROFILE ?= 1
AWS_PROFILE ?= root

THIS_MAKEFILE := $(lastword $(MAKEFILE_LIST))
TERRAFORM_DIR := $(abspath $(dir $(THIS_MAKEFILE)))
INFRA_DIR := $(abspath $(TERRAFORM_DIR)/..)

TF_CMD := $(TF) -chdir=$(TERRAFORM_DIR)
TFVARS_FILE := $(TERRAFORM_DIR)/envs/$(WORKSPACE).tfvars
WORKSPACE_VARS := -var-file=$(TFVARS_FILE)
PLAN_FILE := $(TERRAFORM_DIR)/tfplan

AWS_WORKLOAD_PROFILE ?= $(WORKSPACE)-rentdirect
AWS_SDK_LOAD_CONFIG ?= 1
AWS_PROFILE_FLAG :=
BASH_CMD := bash
ENV_FILE := $(TERRAFORM_DIR)/envs/secrets/.env.$(WORKSPACE)
ENV_EXAMPLE_FILE := $(ENV_FILE).example
LOCK_FILE := s3://rentdirect-statefile/envs/$(WORKSPACE)/rentdirect.tfstate.tflock

ifeq ($(AWS_USE_PROFILE),0)
unexport AWS_PROFILE
unexport AWS_DEFAULT_PROFILE
LOAD_ENV := set -a && . "$(ENV_FILE)" && set +a && unset AWS_PROFILE AWS_DEFAULT_PROFILE
else
AWS_DEFAULT_PROFILE ?= $(AWS_PROFILE)
AWS_PROFILE_FLAG := --profile $(AWS_PROFILE)
export AWS_PROFILE
export AWS_DEFAULT_PROFILE
LOAD_ENV := set -a && . "$(ENV_FILE)" && set +a
endif

export WORKSPACE
export AWS_USE_PROFILE
export AWS_WORKLOAD_PROFILE
export AWS_SDK_LOAD_CONFIG

.PHONY: load-env check-tfvars setup encrypt decrypt encrypt-all fmt fmt-check init upgrade reconfig workspace validate lint refresh plan apply apply-plan destroy state-list list console unlock

# Secrets
load-env: decrypt
	@if [ ! -f "$(ENV_FILE)" ]; then \
		echo "Missing $(ENV_FILE). Copy $(ENV_EXAMPLE_FILE) first."; \
		exit 1; \
	fi

check-tfvars:
	@if [ ! -f "$(TFVARS_FILE)" ]; then \
		echo "Missing $(TFVARS_FILE)."; \
		exit 1; \
	fi

setup:
	@$(BASH_CMD) "$(INFRA_DIR)/scripts/secrets/setup.sh"

encrypt:
	@$(BASH_CMD) "$(INFRA_DIR)/scripts/secrets/encrypt.sh" $(WORKSPACE)

decrypt:
	@$(BASH_CMD) "$(INFRA_DIR)/scripts/secrets/decrypt.sh" $(WORKSPACE)

encrypt-all:
	@$(BASH_CMD) "$(INFRA_DIR)/scripts/secrets/encrypt.sh" dev
	@$(BASH_CMD) "$(INFRA_DIR)/scripts/secrets/encrypt.sh" prod

# Terraform
fmt:
	@$(TF_CMD) fmt -recursive

fmt-check:
	@$(TF_CMD) fmt -diff -check -recursive

init: load-env
	@$(LOAD_ENV) && $(TF_CMD) init -input=false

upgrade: load-env
	@$(LOAD_ENV) && $(TF_CMD) init -input=false -upgrade

reconfig: load-env
	@$(LOAD_ENV) && $(TF_CMD) init -input=false -reconfigure

workspace: init
	@$(LOAD_ENV) && { $(TF_CMD) workspace select $(WORKSPACE) >/dev/null 2>&1 || $(TF_CMD) workspace new $(WORKSPACE); }

validate: init
	@$(LOAD_ENV) && $(TF_CMD) validate

lint: workspace fmt-check
	@$(LOAD_ENV) && $(TF_CMD) validate

refresh: workspace check-tfvars
	@$(LOAD_ENV) && $(TF_CMD) refresh $(WORKSPACE_VARS)

plan: lint check-tfvars
	@$(LOAD_ENV) && $(TF_CMD) plan $(WORKSPACE_VARS) -out=$(PLAN_FILE)

apply: plan
	@$(LOAD_ENV) && $(TF_CMD) apply $(PLAN_FILE)

apply-plan: workspace
	@if [ ! -f "$(PLAN_FILE)" ]; then \
		echo "Missing $(PLAN_FILE). Run make plan first."; \
		exit 1; \
	fi
	@$(LOAD_ENV) && $(TF_CMD) apply $(PLAN_FILE)

destroy: workspace check-tfvars
	@$(LOAD_ENV) && $(TF_CMD) destroy $(WORKSPACE_VARS)

state-list: workspace
	@$(LOAD_ENV) && $(TF_CMD) state list

list: state-list

console: workspace check-tfvars
	@$(LOAD_ENV) && $(TF_CMD) console $(WORKSPACE_VARS)

unlock:
	@if pgrep -x terraform-ls >/dev/null; then \
		pkill -x terraform-ls; \
		sleep 2; \
	fi
	@if aws s3 ls $(LOCK_FILE) $(AWS_PROFILE_FLAG) >/dev/null 2>&1; then \
		echo "Lock file found, removing..."; \
		aws s3 rm $(LOCK_FILE) $(AWS_PROFILE_FLAG); \
	else \
		echo "No lock file found"; \
	fi
