
IMAGE_NAME=shibboleth/sp-idp-demo
IMAGE_VERSION=1.0.0

all: build

copy-golang:
	wget https://github.com/clarin-eric/clarin-sp-aagregator-golang/releases/download/release-1.0-beta2/sp-aagregator-golang-linux-amd64 sp-aagregator-golang

build: copy-golang
	@echo "Building docker image: ${IMAGE_NAME}:${IMAGE_VERSION}"
	@docker build -t ${IMAGE_NAME}:${IMAGE_VERSION} .
