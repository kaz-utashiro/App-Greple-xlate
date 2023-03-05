FILES := $(wildcard *.docx)

TITLE := $(basename $(FILES))

FORMAT := cm ifdef txt
TO := EN-US

ALL := $(foreach fmt,$(FORMAT),$(TITLE:%=%.$(TO).$(fmt)))

ALL: $(ALL)

XLATE := greple -Mmsdoc -Mxlate::deepl --xlate-labor --all --re '^.+\n'
XLATE += --exclude '^\[.*\b(docx)\b.*\]\n'

define DO_XLATE
%.$1.$2: %.docx Makefile
	$$(XLATE) --xlate-to $1 --xlate-format=$(subst txt,none,$2) $$< > $$@
endef

$(foreach format,$(FORMAT),$(eval $(call DO_XLATE,$(TO),$(format))))

.PHONY: clean
clean:
	rm -fr $(ALL)
