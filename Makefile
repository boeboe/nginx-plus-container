# General release info
DOCKER_ACCOUNT := boeboe
IMAGE_NAME 	   := nginx-plus
IMAGE_TAG      := nginx-js-lua-opentracing-r25

JAEGER_LIB_VERSION := v0.8.0
ZIPKIN_LIB_VERSION := v0.5.2

BUILD_ARGS		 := --build-arg JAEGER_LIB_VERSION=${JAEGER_LIB_VERSION} --build-arg ZIPKIN_LIB_VERSION=${ZIPKIN_LIB_VERSION}

# HELP
# This will output the help for each task
# thanks to https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
.PHONY: help

help: ## This help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z0-9_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' ${MAKEFILE_LIST}

.DEFAULT_GOAL := help

build: ## Build the container
	docker build ${BUILD_ARGS} --no-cache -t ${DOCKER_ACCOUNT}/${IMAGE_NAME} .

publish: ## Tag and publish container
	docker tag ${DOCKER_ACCOUNT}/${IMAGE_NAME} ${DOCKER_ACCOUNT}/${IMAGE_NAME}:${IMAGE_TAG}
	docker push ${DOCKER_ACCOUNT}/${IMAGE_NAME}:${IMAGE_TAG}

release: build publish ## Make a full release
