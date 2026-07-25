SHELL := /bin/bash

AWS_PROFILE ?= root
WORKSPACE ?= dev

INFRA_MAKE := $(MAKE) -C terraform WORKSPACE=$(WORKSPACE) AWS_PROFILE=$(AWS_PROFILE)
COMPOSE := docker compose -f docker-compose.yml

.PHONY: setup decrypt encrypt encrypt-all fmt init reconfig workspace validate lint plan plan-nolock apply apply-plan refresh destroy console list unlock down build up migrate seed shell test admin prune

# Secrets
setup decrypt encrypt encrypt-all:
	@$(INFRA_MAKE) $@

# Terraform
fmt init reconfig workspace validate lint plan plan-nolock apply apply-plan refresh destroy console list unlock:
	@$(INFRA_MAKE) $@

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
	$(COMPOSE) up --build
	$(COMPOSE) run --rm api python3 manage.py makemigrations
	$(COMPOSE) run --rm api python3 manage.py migrate

up:
	$(COMPOSE) up
	$(COMPOSE) run --rm api python3 manage.py makemigrations
	$(COMPOSE) run --rm api python3 manage.py migrate

migrate:
	$(COMPOSE) run --rm api python3 manage.py makemigrations
	$(COMPOSE) run --rm api python3 manage.py migrate

seed:
	$(COMPOSE) exec api python3 manage.py seed_demo_data

shell:
	$(COMPOSE) run --rm api python3 manage.py shell

test:
	$(COMPOSE) run --rm api python3 manage.py test

admin:
	$(COMPOSE) exec \
		-e DJANGO_SUPERUSER_EMAIL=admin@rentdirect.local \
		-e DJANGO_SUPERUSER_PASSWORD=ifG0dbi4mi \
		-e DJANGO_SUPERUSER_NAME=Admin \
		api python3 manage.py ensure_superuser

tunnel:
	$(COMPOSE) exec cloudflared cat /data/cloudflared/tunnel-url

prune:
	@docker system df
	@docker system prune -f
	@docker volume prune -f
