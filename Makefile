#!/usr/bin/make -f

BACKEND_VERSION=$(shell cat ./backend/VERSION)
FRONTEND_VERSION=$(shell cat ./frontend/VERSION)
BACKEND_REPO="damlys/phpdock-backend"
FRONTEND_REPO="damlys/phpdock-frontend"
include .env

# $(1) docker-compose service name
# $(2) semver format version
# $(3) remote image name
define pull_image
	docker pull $(3):$(2)
	docker tag $(3):$(2) ${COMPOSE_PROJECT_NAME}/$(1):$(2)
	docker tag ${COMPOSE_PROJECT_NAME}/$(1):$(2) ${COMPOSE_PROJECT_NAME}/$(1):local
endef

# $(1) docker-compose service name
define build_image
	docker-compose build --no-cache $(1)
endef

# $(1) docker-compose service name
# $(2) semver format version
# $(3) remote image name
define release_image
	git tag $(1)-$(2)
	git push origin $(1)-$(2)
	for tag in $(shell ./bin/explode-semver.sh $(2)); do docker tag ${COMPOSE_PROJECT_NAME}/$(1):local $(3):$$tag; done
	for tag in $(shell ./bin/explode-semver.sh $(2)); do docker push $(3):$$tag; done
endef

default: backend.enter-container
backend.enter-container:
	docker-compose exec backend bash
frontend.enter-container:
	docker-compose exec frontend bash
node.enter-container:
	docker-compose exec frontend_node bash

up:
	docker-compose up -d
start:
	docker-compose start
stop:
	docker-compose stop
state:
	@echo "\"docker-compose\" command is using \033[44m${COMPOSE_FILE}\033[0m files"
	docker-compose ps
config:
	@echo "\"docker-compose\" command is using \033[44m${COMPOSE_FILE}\033[0m files"
	docker-compose config
pull-images: backend.pull-image frontend.pull-image
build-assets.dev: backend.build-assets.dev frontend.build-assets.dev
build-assets.prod: backend.build-assets.prod frontend.build-assets.prod
run-tests: backend.run-tests frontend.run-tests
build-images: backend.build-image frontend.build-image
release-images: backend.release-image frontend.release-image

backend.pull-image:
	$(call pull_image,backend,${BACKEND_VERSION},${BACKEND_REPO})
backend.build-assets.dev:
	docker-compose exec backend composer install --ignore-platform-reqs --dev
backend.build-assets.prod:
	docker-compose exec backend composer install --ignore-platform-reqs --prod
backend.run-tests.unit:
	@echo "backend unit tests..."
backend.run-tests.integration:
	@echo "backend integration tests..."
backend.run-tests.functional:
	@echo "backend functional tests..."
backend.run-tests: backend.run-tests.unit backend.run-tests.integration backend.run-tests.functional
backend.build-image:
	$(call build_image,backend)
backend.release-image:
	$(call release_image,backend,${BACKEND_VERSION},${BACKEND_REPO})
backend.install-xdebug:
	-docker-compose exec backend pecl install xdebug
	-docker-compose exec backend docker-php-ext-enable xdebug
	docker-compose restart backend

frontend.pull-image:
	$(call pull_image,frontend,${FRONTEND_VERSION},${FRONTEND_REPO})
frontend.build-assets.dev:
	docker-compose exec frontend_node npm install --ignore-scripts
frontend.build-assets.prod: frontend.build-assets.dev
frontend.run-tests.unit:
	@echo "frontent unit tests..."
frontend.run-tests.integration:
	@echo "frontent integration tests..."
frontend.run-tests.functional:
	@echo "frontent functional tests..."
frontend.run-tests: frontend.run-tests.unit frontend.run-tests.integration frontend.run-tests.functional
frontend.build-image:
	$(call build_image,frontend)
frontend.release-image:
	$(call release_image,frontend,${FRONTEND_VERSION},${FRONTEND_REPO})

mysql.backup:
	./bin/mysql-create-backup.sh

redis.flush:
	docker-compose exec redis redis-cli -a ${REDIS_PASSWORD} flushdb
