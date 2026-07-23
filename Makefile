SHELL := /bin/bash

TF ?= terraform
WORKSPACE ?= dev
AWS_PROFILE ?= root

ENVIRONMENT ?= $(WORKSPACE)
WORKSPACE_VARS := -var-file=terraform/envs/$(ENVIRONMENT).tfvars

AWS_DEFAULT_PROFILE ?= $(AWS_PROFILE)
AWS_WORKLOAD_PROFILE ?= $(WORKSPACE)-rentdirect
AWS_SDK_LOAD_CONFIG ?= 1

BASH_CMD := bash
TF_DIR := -chdir=terraform
ENV_FILE := terraform/envs/secrets/.env.$(ENVIRONMENT)
LOAD_ENV := set -a && . $(ENV_FILE) && set +a
LOCK_FILE := s3://rentdirect-statefile/envs/$(WORKSPACE)/rentdirect.tfstate.tflock
STATE_FILE := s3://rentdirect-statefile/envs/$(WORKSPACE)/rentdirect.tfstate


export WORKSPACE
export ENVIRONMENT
export AWS_PROFILE
export AWS_DEFAULT_PROFILE
export AWS_WORKLOAD_PROFILE
export AWS_SDK_LOAD_CONFIG

.PHONY:  load-env setup encrypt decrypt fmt init reconfig workspace lint plan apply destroy state-list console unlock backend frontend migrate admin help


# Cryptography
load-env: decrypt
	@if [ ! -f "$(ENV_FILE)" ]; then \
		echo "Missing $(ENV_FILE). Copy the matching .example file first."; \
		exit 1; \
	fi

setup:
	@$(BASH_CMD) scripts/secrets/setup.sh

encrypt:
	@$(BASH_CMD) scripts/secrets/encrypt.sh $(WORKSPACE)

decrypt:
	@$(BASH_CMD) scripts/secrets/decrypt.sh $(WORKSPACE)



# Terraform
fmt:
	@$(TF) $(TF_DIR) fmt -recursive

init: fmt
	@$(LOAD_ENV) && $(TF) $(TF_DIR) init -input=false -upgrade

reconfig: load-env fmt
	@$(LOAD_ENV) && $(TF) $(TF_DIR) init -input=false -reconfigure

workspace: init
	@$(LOAD_ENV) && $(TF) $(TF_DIR) workspace select $(WORKSPACE) >/dev/null 2>&1 || $(TF) $(TF_DIR) workspace new $(WORKSPACE)

lint: load-env workspace
	@$(LOAD_ENV) && $(TF) $(TF_DIR) fmt -diff -check -recursive
	@$(LOAD_ENV) && $(TF) $(TF_DIR) validate

refresh: lint
	@$(LOAD_ENV) && $(TF) $(TF_DIR) refresh $(WORKSPACE_VARS)

plan: lint
	@$(LOAD_ENV) && $(TF) $(TF_DIR) plan $(WORKSPACE_VARS) -out=tfplan

apply: plan
	@$(LOAD_ENV) && $(TF) $(TF_DIR) apply tfplan

destroy: lint
	@$(LOAD_ENV) && $(TF) $(TF_DIR) destroy $(WORKSPACE_VARS)

state-list: lint
	@$(LOAD_ENV) && $(TF) $(TF_DIR) state list

console: lint
	@$(LOAD_ENV) && $(TF) $(TF_DIR) console $(WORKSPACE_VARS)

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


# Docker
down:
	@if [ -n "$$(docker ps -aq)" ]; then \
		echo "Deleting Docker containers, images, volumes, and networks..."; \
		docker container stop $$(docker ps -aq) > /dev/null; \
		docker compose down --rmi local --volumes --remove-orphans; \
	else \
		echo "No Docker containers to delete."; \
	fi

up:
	@docker compose up
	@docker compose run --rm api python3 manage.py makemigrations
	@docker compose run --rm api python3 manage.py migrate

build:
	@docker compose up --build

migrate:
	@docker compose run --rm api python3 manage.py makemigrations
	@docker compose run --rm api python3 manage.py migrate

admin:
	@docker compose exec \
	  -e DJANGO_SUPERUSER_EMAIL=admin@rentdirect.local \
	  -e DJANGO_SUPERUSER_PASSWORD=ifG0dbi4mi \
	  api python3 manage.py createsuperuser \
	    --noinput \
		--role "admin" \
		--name "Admin"

seed:
	@docker compose exec api python3 manage.py seed_demo_data

shell:
	@docker compose run --rm api python3 manage.py shell

test:
	@docker compose run --rm api python3 manage.py test

web:
	@npm -w apps/web run build

api:
	@docker build -t rentdirect-api:local ./apps/api

docker-tunnel:
	@docker compose exec cloudflared cat /data/cloudflared/tunnel-url
