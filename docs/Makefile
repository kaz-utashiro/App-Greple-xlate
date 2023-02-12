vpath %.pm ../lib/App/Greple

PM = xlate.pm

LANG := DE EL ET FR ID JA KO NL RO RU TR UK ZH

PMS = $(foreach lang,$(LANG),$(patsubst %.pm,%.$(lang).pm,$(PM)))
MDS = $(patsubst %.pm,%.md,$(PMS))

all: $(MDS)

XLATE = greple -Mxlate::deepl --match-podtext --xlate-format=none --xlate --all

$(PMS): $(PM)
	$(XLATE) --xlate-to $(subst .,,$(suffix $(basename $@))) $< > $@

%.md: %.pm
	pod2markdown $< > $@

clean:
	rm -f $(PMS) $(MDS)
