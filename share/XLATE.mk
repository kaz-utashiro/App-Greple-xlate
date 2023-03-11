#
# Requires GNU make which can handle "file" function.
# /usr/bin/make in macOS Monterey is 3.81 but it does not work.
#

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
XLATE_FORMAT ?= xtxt cm ifdef

ifeq ($(strip $(XLATE_FILES)),)
override XLATE_FILES := \
	$(filter-out README.%.md,\
	$(wildcard *.docx *.pptx *.txt *.md *.pm))
else
override XLATE_FILES := $(subst |||, ,$(XLATE_FILES))
endif

define FOREACH
$(foreach file,$(subst ",,$(XLATE_FILES)),
$(foreach lang,$(or $(file < $(file).LANG),$(XLATE_LANG)),
$(foreach form,$(or $(file < $(file).FORMAT),$(XLATE_FORMAT)),
$(call $1,$(lang),$(form),$(file))
)))
endef

define ADD_TARGET
  TARGET += $$(addsuffix .$1.$2,$$(basename $3))
endef
$(eval $(call FOREACH,ADD_TARGET))

ALL := $(TARGET)

ALL: $(ALL)

define DEFINE_RULE
$(basename $3).$1.$2: $3
	$$(XLATE) -t $1 -x $2 $$< > $$@
endef
$(eval $(call FOREACH,DEFINE_RULE))

XLATE = xlate \
	$(if $(XLATE_DEBUG),-d) \
	$(if $(XLATE_MAXLEN),-m$(XLATE_MAXLEN)) \
	$(if $(XLATE_USEAPI),-a)

.PHONY: clean
clean:
	rm -fr $(ALL)

.PHONY: shell
shell:
	MAKELEVEL= /bin/bash
