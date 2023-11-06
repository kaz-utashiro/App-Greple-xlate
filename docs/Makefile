LANGS    := DE EL ES ET FR ID JA KO NL RO RU TR UK ZH
RM_LANGS := DE EL ES ET FR ID JA KO NL RO RU TR UK ZH
IGNORE   := VERSION AUTHOR LICENSE
ENGINES  := deepl gpt3

MOD_NAME := $(shell perl -MJSON -0777nE 'say decode_json($$_)->{name}' ../META.json)
MOD_PATH := ../lib/$(subst -,/,$(MOD_NAME)).pm
MOD_FILE := $(notdir $(MOD_PATH))
MOD_DIR  := $(dir $(MOD_PATH))
MOD_NAME := $(MOD_FILE:.pm=)
SRC_DIR  := src

ORIGIN   := $(wildcard $(MOD_DIR)[a-z]*.pm)
PM       := $(notdir $(ORIGIN))
SRC      := $(PM:%=$(if $(SRC_DIR),$(SRC_DIR)/,)%)
PMS      := $(foreach engin,$(ENGINES),$(foreach lang,$(LANGS),$(SRC:.pm=.$(engin)-$(lang).pm)))
MDS      := $(foreach engin,$(ENGINES),$(foreach lang,$(LANGS),$(PM:.pm=.$(engin)-$(lang).md)))
READMES  := $(foreach engin,$(ENGINES),$(RM_LANGS:%=../README.$(engin)-%.md))
ALL      := $(PMS) $(MDS) README.md $(READMES)

all: $(ALL)

ifdef SRC_DIR
  $(SRC_DIR):
	mkdir -p $(SRC_DIR)
endif
SRCPATH := $(if $(SRC_DIR),$(SRC_DIR)/,)

GREPLE := perl -I../lib -S greple

PODIFY := $(GREPLE) -Mperl --nocolor --le :pod
$(foreach mod,$(ORIGIN),$(eval \
  $(SRCPATH)$(notdir $(mod)): $(mod) $(SRC_DIR) Makefile; $(PODIFY) $$< > $$@ \
))

XLATE := $(GREPLE) -Mxlate
XLATE += $(if $(XLATE_LABOR),--xlate-labor,--xlate)
XLATE += --xlate-cache=$(if $(XLATE_INIT),clear,yes)
XLATE += --match-podtext --xlate-format=none --all --need=0

ifdef IGNORE
$(foreach ignore,$(IGNORE),$(eval \
  XLATE += --exclude '^=head\d[ ]+(?i:$(ignore))\b(?s:.*?)(?=^=|\z)'\
))
endif

deepl_JA_FORM   ?= desumasu
deepl_JA_DICT   := $(wildcard *.dict)
deepl_JA_FILTER := $(GREPLE) -Mperl -Msubst::desumasu \
	$(if $(findstring $(deepl_JA_FORM).dict,$(deepl_JA_DICT)),--dict $(deepl_JA_FORM).dict) \
	--pod --subst --all --no-color --need=0 \
	--$(deepl_JA_FORM) 

define LANG_PM
  $(SRCPATH)%.$2-$1.pm: $(SRCPATH)%.pm Makefile
  ifdef $2_$1_FILTER
	$$(XLATE) --xlate-engine=$2 --xlate-to $1 $$< | $$($2_$1_FILTER) > $$@
  else
	$$(XLATE) --xlate-engine=$2 --xlate-to $1 $$< > $$@
  endif
endef

$(foreach engin,$(ENGINES),$(foreach lang,$(LANGS),$(eval $(call LANG_PM,$(lang),$(engin)))))

%.md: $(SRCPATH)%.pm
	pod2markdown $< > $@

define LANG_README
  ../README.$2-$1.md: $(MOD_NAME).$2-$1.md
	cp $$< $$@
endef

$(foreach engin,$(ENGINES),$(foreach lang,$(RM_LANGS),$(eval $(call LANG_README,$(lang),$(engin)))))

README.md: Makefile
	exec > $@ && \
	printf '## Languages\n\n' && \
	for md in $(MDS) ; \
	do \
	    echo "- [$$md]($$md)" ; \
	done

clean:
	rm -f $(SRC) $(ALL)
