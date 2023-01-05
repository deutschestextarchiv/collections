# vim: set noexpandtab
MKFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
MKFILE_DIR  := $(dir $(MKFILE_PATH))

.PHONY: all
all: landing-pages

YAML_DIR   := $(MKFILE_DIR)../dta
YAML_FILES := $(wildcard $(YAML_DIR)/*.yml)
OUTDIR     := $(MKFILE_DIR)web
HTML_TEMPLATE := $(MKFILE_DIR)template.html

.PHONY: landing-pages
landing-pages: $(subst $(YAML_DIR),$(OUTDIR),$(YAML_FILES:.yml=.html)) $(HTML_TEMPLATE)

$(YAML_FILES): | $(OUTDIR)

$(OUTDIR):
	mkdir -p $(OUTDIR)

$(OUTDIR)/%.html: $(YAML_DIR)/%.yml $(HTML_TEMPLATE)
	$(MKFILE_DIR)../schemata/compile-catalog.pl $< | perl -pE 'BEGIN { $$j = `$(MKFILE_DIR)../schemata/compile-catalog.pl $< | jq '.$(basename $(notdir $<))'` } s/(let meta = )\"\"/\1 $$j/' $(HTML_TEMPLATE) > $@

.PHONY: clean
clean:
	rm -f $(OUTDIR)/*.html
