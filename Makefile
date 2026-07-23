SHELL := /bin/bash

WORKSPACE ?= dev
AWS_USE_PROFILE ?= 1
AWS_PROFILE ?= root

INFRA_MAKE := $(MAKE) -C terraform WORKSPACE=$(WORKSPACE) AWS_USE_PROFILE=$(AWS_USE_PROFILE)
ifneq ($(AWS_USE_PROFILE),0)
INFRA_MAKE += AWS_PROFILE=$(AWS_PROFILE)
endif

COMPOSE := docker compose -f docker-compose.yml

.PHONY: setup load-env decrypt encrypt encrypt-all fmt fmt-check init upgrade reconfig validate workspace lint refresh plan apply apply-plan destroy state-list list console unlock down build up migrate admin seed shell test web api docker-tunnel prune

# Secrets
setup:
	@$(INFRA_MAKE) setup

load-env:
	@$(INFRA_MAKE) load-env

decrypt:
	@$(INFRA_MAKE) decrypt

encrypt:
	@$(INFRA_MAKE) encrypt

encrypt-all:
	@$(INFRA_MAKE) encrypt-all

# Terraform
fmt:
	@$(INFRA_MAKE) fmt

fmt-check:
	@$(INFRA_MAKE) fmt-check

init:
	@$(INFRA_MAKE) init

upgrade:
	@$(INFRA_MAKE) upgrade

reconfig:
	@$(INFRA_MAKE) reconfig

validate:
	@$(INFRA_MAKE) validate

workspace:
	@$(INFRA_MAKE) workspace

lint:
	@$(INFRA_MAKE) lint

refresh:
	@$(INFRA_MAKE) refresh

plan:
	@$(INFRA_MAKE) plan

apply:
	@$(INFRA_MAKE) apply

apply-plan:
	@$(INFRA_MAKE) apply-plan

destroy:
	@$(INFRA_MAKE) destroy

state-list:
	@$(INFRA_MAKE) state-list

list:
	@$(INFRA_MAKE) list

console:
	@$(INFRA_MAKE) console

unlock:
	@$(INFRA_MAKE) unlock

# Docker
down:
	@if [ -n "$$(docker ps -aq)" ]; then \
		echo "Deleting Docker containers, images, volumes, and networks..."; \
		docker container stop $$(docker ps -aq) > /dev/null; \
		$(COMPOSE) down --rmi local --volumes --remove-orphans; \
	else \
		echo "No Docker containers to delete."; \
	fi

build:
	$(COMPOSE) build

up:
	$(COMPOSE) up

migrate:
	$(COMPOSE) run --rm api python manage.py makemigrations
	$(COMPOSE) run --rm api python manage.py migrate

admin:
	$(COMPOSE) exec \
		-e DJANGO_SUPERUSER_EMAIL=admin@rentdirect.local \
		-e DJANGO_SUPERUSER_PASSWORD=ifG0dbi4mi \
		-e DJANGO_SUPERUSER_NAME=Admin \
		api python manage.py ensure_superuser

seed:
	$(COMPOSE) exec api python manage.py seed_demo_data

shell:
	$(COMPOSE) run --rm api python manage.py shell

test:
	$(COMPOSE) run --rm api python manage.py test

web:
	npm --prefix ../apps/web run build

api:
	docker build -t rentdirect-api:local ../apps/api

docker-tunnel:
	$(COMPOSE) exec cloudflared cat /data/cloudflared/tunnel-url

prune:
	@docker system df
	@docker system prune -f
	@docker volume prune -f
