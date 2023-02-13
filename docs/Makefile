vpath %.pm ../lib/App/Greple

PM = xlate.pm

LANG := DE EL ET FR ID JA KO NL RO RU TR UK ZH

PMS = $(foreach lang,$(LANG),$(patsubst %.pm,%.$(lang).pm,$(PM)))
MDS = $(patsubst %.pm,%.md,$(PMS))

ALL = $(PMS) $(MDS) README.md

all: $(ALL)

XLATE = greple -Mxlate::deepl --match-podtext --xlate-format=none --xlate --all

define LANG_PM
%.$(1).pm: %.pm
	$$(XLATE) --xlate-to $(1) $$< > $$@
endef

$(foreach lang,$(LANG),$(eval $(call LANG_PM,$(lang))))

%.md: %.pm
	pod2markdown $< > $@

README.md: Makefile
	( \
	printf '## Languages\n\n'; \
	for lang in $(LANG) ; \
	do \
	    echo "- [xlate.$$lang.md](xlate.$$lang.md)" ; \
	done ; \
	) > $@

clean:
	rm -f $(ALL)
