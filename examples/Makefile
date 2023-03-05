XLATE_TO     ?= EN-US FR
XLATE_FORMAT ?= xtxt cm ifdef
XLATE_FILES  ?= $(wildcard *.docx *.pptx *.txt *.md)

define FOREACH
$(foreach lang,$(XLATE_TO),
$(foreach fmt,$(XLATE_FORMAT),
$(foreach file,$(XLATE_FILES),
$(call $1,$(lang),$(fmt),$(file))
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
	$$(XLATE) --xlate-to $1 --xlate-format=$2 $$< > $$@
endef
$(eval $(call FOREACH,DEFINE_RULE))

XLATE = greple -Mmsdoc -Mxlate::deepl --xlate-labor --all --re '^.+\n'
XLATE += --exclude '^\[.*\b(docx|pptx)\b.*\]\n'

.PHONY: clean
clean:
	rm -fr $(ALL)
