# Docker Image Name (is taken from package.json file)
NAME = slanger

# Image Version (is taken from package.json file)
VERSION = $(shell cd ./slanger; git describe --long --tags --dirty --always)

# GCE Project ID
GCLOUD_PROJECT ?= plasma-column-128721

# Google Conttainer Registry name
GCR_NAME = gcr.io/$(GCLOUD_PROJECT)/$(NAME):$(VERSION)

# Dockerhub Image Name 
DOCKERHUB_NAME = 6river/$(NAME):$(VERSION)

.PHONY: all check_exists check_ssh_key run run_bash gcloud_tag clean build gcloud_push check_gcloud_env gcloud_config gcloud_deploy

all: build

# Perform a check if Docker image exists
check_exists:
	@if ! docker images $(NAME) | awk '{ print $$2 }' | grep -q -F $(VERSION); then echo "$(NAME) version $(VERSION) is not yet built. Please run 'make build'"; false; fi

# Run image
run: check_exists
	
	docker run --rm -it \
		--name $(NAME)-$(shell date +%Y%m%d) \
		$(NAME):$(VERSION)

stop:
	docker stop $(NAME)

# Used for quality diagnostics
# Opens bash session
run_bash: check_exists
	docker run --rm -it --entrypoint=/bin/bash $(NAME):$(VERSION)

# Remove Docker image
clean:
	@if docker images $(GCR_NAME) | awk '{ print $$2 }' | grep -q -F $(VERSION); then docker rmi $(GCR_NAME); fi
	@if docker images $(NAME) | awk '{ print $$2 }' | grep -q -F $(VERSION); then docker rmi $(NAME):$(VERSION); fi

# Build Docker image
build:
	@docker build -t $(NAME):$(VERSION) .

# Tag current version with gcloud name
gcloud_tag:
	docker tag $(NAME):$(VERSION) $(GCR_NAME)

# Publish image to GKE registry
gcloud_push: check_exists gcloud_tag
	gcloud docker push $(GCR_NAME)

check_gcloud_env:
	@if [ -z "$(CLIENT_SECRET)" ]; then echo "CLIENT_SECRET environment variable is not set"; false; fi
	@if [ -z "$(GCLOUD_PROJECT)" ]; then echo "GCLOUD_PROJECT environment variable is not set"; false; fi
	@if [ -z "$(GCLOUD_COMPUTE_ZONE)" ]; then echo "GCLOUD_COMPUTE_ZONE environment variable is not set"; false; fi

gcloud_config: check_gcloud_env
	@echo $(CLIENT_SECRET) | base64 --decode > ${HOME}/client-secret.json
	@sudo /opt/google-cloud-sdk/bin/gcloud --quiet components update
	@sudo chmod 757 /home/ubuntu/.config/gcloud/logs -R
	@gcloud auth activate-service-account --key-file ${HOME}/client-secret.json
	@gcloud config set project $(GCLOUD_PROJECT)
	@gcloud config set compute/zone $(GCLOUD_COMPUTE_ZONE)

gcloud_deploy: gcloud_config gcloud_push

dockerhub_tag:
	@docker tag $(NAME):$(VERSION) $(DOCKERHUB_NAME)

check_dockerhub_env:
	@if [ -z "$(DOCKER_EMAIL)" ]; then echo "DOCKER_EMAIL environment variable is not set"; false; fi
	@if [ -z "$(DOCKER_USER)" ]; then echo "DOCKER_USER environment variable is not set"; false; fi
	@if [ -z "$(DOCKER_PASS)" ]; then echo "DOCKER_PASS environment variable is not set"; false; fi

dockerhub_push: check_exists check_dockerhub_env dockerhub_tag
	@docker login -e $(DOCKER_EMAIL) -u $(DOCKER_USER) -p $(DOCKER_PASS)
	@docker push $(DOCKERHUB_NAME)
