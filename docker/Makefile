##
## CACHE=no	do not use cache
##

IMAGE:=tecolicom/xlate
VERSION:=$(shell git describe --tags --abbrev=0)
TARGET:=$(IMAGE):$(VERSION)

.PHONY: build run clean

build:
	docker build \
		$(if $(findstring $(CACHE),no),--no-cache) \
		--build-arg DEV=$$(git rev-parse origin/HEAD) \
		-t $(TARGET) \
		-t $(IMAGE):latest .

run:
	cd ../examples && dozo

clean:
	@none="$$(docker image ls | awk '$$1~/<none>/||$$2~/<none>/{print $$3}')" ; \
	[ "$$none" != "" ] && docker image rm $$none || :
