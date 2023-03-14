##
## CACHE=no	do not use cache
##

TARGET:=tecolicom/xlate:$(shell git describe --tags --abbrev=0)

.PHONY: build run clean

build:
	docker build \
		$(if $(findstring $(CACHE),no),--no-cache) \
		--build-arg DEV=$$(git rev-parse origin/HEAD) \
		-t $(TARGET) .

run:
	ip=`ifconfig en0 | awk '$$1=="inet"{print $$2}'` ; \
	docker run --rm -it \
		--hostname xlate \
		-e DISPLAY=$$ip:0 \
		-e DEEPL_AUTH_KEY=$$DEEPL_AUTH_KEY \
		-v $$(pwd)/../examples:/work \
		$(TARGET) \
		bash

clean:
	@none="$$(docker image ls | awk '$$1~/<none>/||$$2~/<none>/{print $$3}')" ; \
	[ "$$none" != "" ] && docker image rm $$none || :
