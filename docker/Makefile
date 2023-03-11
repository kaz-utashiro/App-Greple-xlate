TARGET:=docker-xlate

.PHONY: build
build:
	cp ../share/XLATE.mk .
	docker build --build-arg CACHEBUST=$$(date +%s) -t $(TARGET) .
	rm -f XLATE.mk

.PHONY: run
run:
	ip=`ifconfig en0 | awk '$$1=="inet"{print $$2}'` ; \
	docker run --rm -it \
		-e DISPLAY=$$ip:0 \
		-e DEEPL_AUTH_KEY=$$DEEPL_AUTH_KEY \
		-v `pwd`/../examples:/app \
		$(TARGET) \
		shell

.PHONY: clean
clean:
	@none="$$(docker image ls | awk '$$1~/<none>/{print $$3}')" ; \
	[ "$$none" != "" ] && docker image rm $$none || :
