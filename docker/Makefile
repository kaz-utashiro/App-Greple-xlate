##
## Docker image build for tecolicom/xlate
##
## Usage:
##   make build          Build image with current origin/HEAD
##   make build CACHE=no Build without cache
##   make run            Run container in examples directory
##   make clean          Remove dangling images
##
## Build arguments:
##   COMMIT  Commit hash for local development builds (used by make build)
##   TAG     Version tag for release builds (used by GitHub Actions workflow)
##

IMAGE:=tecolicom/xlate
VERSION:=$(shell git describe --tags --abbrev=0)
TARGET:=$(IMAGE):$(VERSION)

.PHONY: build run clean

build:
	docker build \
		$(if $(findstring $(CACHE),no),--no-cache) \
		--build-arg COMMIT=$$(git rev-parse origin/HEAD) \
		-t $(TARGET) \
		-t $(IMAGE):latest .

## Run container using dozo in examples directory
run:
	cd ../examples && dozo

## Remove dangling (untagged) images
clean:
	@none="$$(docker image ls | awk '$$1~/<none>/||$$2~/<none>/{print $$3}')" ; \
	[ "$$none" != "" ] && docker image rm $$none || :
