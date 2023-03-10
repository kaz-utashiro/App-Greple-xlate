#
# Requires GNU make which can handle "file" function.
# /usr/bin/make in macOS Monterey is 3.81 but it does not work.
#

#
# ENVIRONMENTS
#
# DEBUG:  Enable debug output
# MAXLEN: Set maximum length for API call
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
XLATE_FILES  ?= $(filter-out README.%.md,\
		$(wildcard *.docx *.pptx *.txt *.md *.pm))

define FOREACH
$(foreach file,$(XLATE_FILES),
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
$(basename $3).$1.$2: $3 Makefile
	$$(XLATE) -t $1 -x $2 $$< > $$@
endef
$(eval $(call FOREACH,DEFINE_RULE))

XLATE = ./xlabor \
	$(if $(DEBUG),-d) \
	$(if $(MAXLEN),-m$(MAXLEN)) \
	$(if $(USEAPI),-a)

.PHONY: clean
clean:
	rm -fr $(ALL)
