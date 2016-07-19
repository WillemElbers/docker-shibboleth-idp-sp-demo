
IMAGE_NAME=shibboleth/sp-idp-demo
IMAGE_VERSION=1.0.0

build:
	@echo "Building docker image: ${IMAGE_NAME}:${IMAGE_VERSION}"
	@docker build -t ${IMAGE_NAME}:${IMAGE_VERSION} .
