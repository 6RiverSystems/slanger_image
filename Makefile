# Docker Image Name
NAME = slanger
# Image Version
VERSION = 0.0.1

# GCE Project ID
PROJECT_ID = plasma-column-128721

# Google Conttainer Registry
GCR_NAME = gcr.io/$(PROJECT_ID)/$(NAME):$(VERSION)

# Application environment
APP_KEY = cf256b0f27ce65f518c1
APP_SECRET = 49c7e5564de31d764400

.PHONY: all check run run_bash tag clean build_image build push

all: build

# Perform a check if Docker image exists
check:
	@if ! docker images $(NAME) | awk '{ print $$2 }' | grep -q -F $(VERSION); then echo "$(NAME) version $(VERSION) is not yet built. Please run 'make build'"; false; fi

# Run slanger
run: check
	docker run --rm -it \
		-e APP_KEY=$(APP_KEY) -e APP_SECRET=$(APP_SECRET) \
		-p 8080:8080 -p 4567:4567 \
		$(NAME):$(VERSION)

# Used for quality diagnostics
# Opens bash session
run_bash: check
	docker run --rm -it --entrypoint=/bin/bash $(NAME):$(VERSION)

# Tag current version as latest
tag:
	docker tag $(NAME):$(VERSION) $(GCR_NAME)

# Remove Docker image
clean: check
	docker rmi $(NAME):$(VERSION)
	docker rmi $(GCR_NAME)

# Build Docker image
build_image:
	docker build -t $(NAME):$(VERSION) .

build: build_image tag

# Publish image
push: check tag
	gcloud docker push $(GCR_NAME)

