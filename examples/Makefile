XLATE_TO     ?= EN-US FR
XLATE_FORMAT ?= xtxt cm ifdef
XLATE_FILES  ?= $(wildcard *.docx *.pptx *.txt *.md *.pm)

define FOREACH
$(foreach lang,$(XLATE_TO),
$(foreach form,$(XLATE_FORMAT),
$(foreach file,$(XLATE_FILES),
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
	$$(XLATE) --xlate-to $1 --xlate-format=$2 $$< > $$@
endef
$(eval $(call FOREACH,DEFINE_RULE))

XLATE = greple -Mmsdoc -Mxlate::deepl --xlate-labor --all

# pattern
XLATE += \
	$(if $(findstring $(suffix $<), .pod .pm .pl ),\
		--re '^(\w.+\n)+',\
	--re '^.+\n'\
	)

# area
XLATE += \
	$(if $(findstring $(suffix $<), .docx .pptx ),\
		--exclude '^\[.*\b(docx|pptx)\b.*\]\n',\
	$(if $(findstring $(suffix $<), .pod .pm .pl ),\
		--include '^=\w(?s:.*?)(^=cut|\z)' \
		--exclude '^=head\d +(VERSION|AUTHOR|LICENSE).*\n(?s:.*?)(?=^=|\z)',\
	))

.PHONY: clean
clean:
	rm -fr $(ALL)
