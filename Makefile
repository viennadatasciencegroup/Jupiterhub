# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.

include .env

.DEFAULT_GOAL=build

network:
	@docker network inspect $(DOCKER_NETWORK_NAME) >/dev/null 2>&1 || docker network create $(DOCKER_NETWORK_NAME)

volumes:
	@docker volume inspect $(DATA_VOLUME_HOST) >/dev/null 2>&1 || docker volume create --name $(DATA_VOLUME_HOST)
	@docker volume inspect $(DB_VOLUME_HOST) >/dev/null 2>&1 || docker volume create --name $(DB_VOLUME_HOST)

self-signed-cert:
	# make a self-signed cert

secrets/postgres.env:
	@echo "Generating postgres password in $@"
	@echo "POSTGRES_PASSWORD=$(shell openssl rand -hex 32)" > $@

secrets/oauth.env:
	@echo "Need oauth.env file in secrets with GitHub parameters"
	@exit 1

/etc/letsencrypt/live/hub.vdsg.at/cert.pem:
	@echo "Need an SSL certificate in /etc/letsencrypt/live/hub.vdsg.at/cert.pem"
	@exit 1

/etc/letsencrypt/live/hub.vdsg.at/privkey.pem:
	@echo "Need an SSL key in /etc/letsencrypt/live/hub.vdsg.at/privkey.pem"
	@exit 1

userlist:
	@echo "Add usernames, one per line, to ./userlist, such as:"
	@echo "    zoe admin"
	@echo "    wash"
	@exit 1

# Do not require cert/key files if SECRETS_VOLUME defined
secrets_volume = $(shell echo $(SECRETS_VOLUME))
ifeq ($(secrets_volume),)
	cert_files=/etc/letsencrypt/live/hub.vdsg.at/cert.pem /etc/letsencrypt/live/hub.vdsg.at/privkey.pem
else
	cert_files=
endif

check-files: userlist $(cert_files) secrets/oauth.env secrets/postgres.env

pull:
	docker pull $(DOCKER_NOTEBOOK_IMAGE)

notebook_image: pull singleuser/Dockerfile
	docker build -t $(LOCAL_NOTEBOOK_IMAGE) \
		--build-arg JUPYTERHUB_VERSION=$(JUPYTERHUB_VERSION) \
		--build-arg DOCKER_NOTEBOOK_IMAGE=$(DOCKER_NOTEBOOK_IMAGE) \
		singleuser

build: check-files network volumes
	docker-compose build

.PHONY: network volumes check-files pull notebook_image build
