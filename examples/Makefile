.PHONY: all clean

ifdef LOCAL
    XLATE=env PERL5LIB=../lib:$(PERL5LIB) ../script/xlate
else
    XLATE=xlate
endif

XLATE_OPT?=\
	$(if $(DOCKER),-D) \
	$(if $(MAXLEN),-m$(MAXLEN)) \
	$(if $(USEAPI),-a)

all:
	$(XLATE) $(XLATE_OPT) -M

clean:
	$(XLATE) $(XLATE_OPT) -M clean
