.PHONY: all clean

XLATE_OPT?=\
	$(if $(DOCKER),-D) \
	$(if $(MAXLEN),-m$(MAXLEN)) \
	$(if $(USEAPI),-a)

all:
	xlate $(XLATE_OPT) -M

clean:
	xlate $(XLATE_OPT) -M clean
