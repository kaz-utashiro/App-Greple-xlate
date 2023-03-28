#
# ENVIRONMENTS
#
# XLATE_DEBUG:  Enable debug output
# XLATE_MAXLEN: Set maximum length for API call
# XLATE_USEAPI: Use API
#

#
# PARAMETER FILES
#   If the source file is acompanied with parameter files with 
#   following extension, they are used to override default parameters.
#
# .LANG:   Languages translated to
# .FORMAT: Format of output files
#

XLATE_LANG   ?= JA
XLATE_FORMAT ?= xtxt cm

ifeq ($(strip $(XLATE_FILES)),)
override XLATE_FILES := \
	$(filter-out README.%.md,\
	$(wildcard *.docx *.pptx *.txt *.md *.pm))
else
override XLATE_FILES := $(subst |||, ,$(XLATE_FILES))
endif

# GNU Make treat strings containing double quotes differently on versions
define REMOVE_QUOTE
  override $1 := $$(subst ",,$$($1))
endef
$(foreach name,XLATE_LANG XLATE_FORMAT XLATE_FILES,\
	$(eval $(call REMOVE_QUOTE,$(name))))

define FOREACH
$(foreach file,$(XLATE_FILES),
$(foreach lang,$(or $(shell cat $(file).LANG 2> /dev/null),$(XLATE_LANG)),
$(foreach form,$(or $(shell cat $(file).FORMAT 2> /dev/null),$(XLATE_FORMAT)),
$(call $1,$(lang),$(form),$(file))
)))
endef

define ADD_TARGET
  TARGET += $$(addsuffix .$1.$2,$$(basename $3))
endef
$(eval $(call FOREACH,ADD_TARGET))

ALL := $(TARGET)

ALL: $(ALL)

MSDOC := docx doc pptx xlsx
define MSTXT
  $(patsubst %.doc,%.dtxt,
  $(patsubst %.docx,%.dtxt,
  $(patsubst %.pptx,%.ptxt,
  $(patsubst %.xlsx,%.etxt,$1))))
endef

MSFILES   := $(filter $(MSDOC:%=\%.%),$(XLATE_FILES))
TEMPFILES += $(foreach file,$(MSFILES),$(call MSTXT,$(file)))

define DEFINE_RULE
$(basename $3).$1.$2: $(call MSTXT,$3)
	$$(XLATE) -t $1 -o $2 $$< > $$@
endef
$(eval $(call FOREACH,DEFINE_RULE))

XLATE = xlate \
	$(if $(XLATE_DEBUG),-d) \
	$(if $(XLATE_MAXLEN),-m$(XLATE_MAXLEN)) \
	$(if $(XLATE_USEAPI),-a)

TEXTCONV := optex -Mtc cat

define MAKE_OTXT
%.otxt: %.$1
	$(TEXTCONV) $$< > $$@
endef
$(foreach suffix,$(MSDOC),$(eval $(call MAKE_OTXT,$(suffix))))

%.dtxt: %.docx ; $(TEXTCONV) $< > $@
%.dtxt: %.doc  ; $(TEXTCONV) $< > $@
%.ptxt: %.pptx ; $(TEXTCONV) $< > $@
%.etxt: %.elsx ; $(TEXTCONV) $< > $@

.PHONY: clean
clean:
	rm -fr $(ALL) $(TEMPFILES)

.PHONY: shell
shell:
	MAKELEVEL= /bin/bash
