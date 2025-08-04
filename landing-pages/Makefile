# vim: set noexpandtab
MKFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
MKFILE_DIR  := $(dir $(MKFILE_PATH))

.PHONY: all
all: landing-pages

YAML_DIRS   := $(MKFILE_DIR)../dta $(MKFILE_DIR)../dwds
YAML_FILES  := $(wildcard $(addsuffix /*.yml, $(YAML_DIRS)))
OUTDIR     := $(MKFILE_DIR)web
HTML_TEMPLATE := $(MKFILE_DIR)template.html

HTML_FILES := $(patsubst %.yml,$(OUTDIR)/%.html,$(notdir $(YAML_FILES)))

.PHONY: landing-pages
landing-pages: $(HTML_FILES)

$(OUTDIR):
	mkdir -p $(OUTDIR)

vpath %.yml $(YAML_DIRS)
$(OUTDIR)/%.html: %.yml $(HTML_TEMPLATE) | $(OUTDIR)
	perl -pE 'BEGIN { $$j = `$(MKFILE_DIR)../schemata/compile-catalog.pl -s $<`; exit if !$$j or $$j =~ /^\{\}/ } s/(let meta = )\"\"/\1 $$j/' $(HTML_TEMPLATE) > $@
	test -s $@ || rm -f $@

.PHONY: publish
publish:
	rsync -av $(OUTDIR)/* kaskade:/var/www/sammlungen

.PHONY: clean
clean:
	rm -f $(OUTDIR)/*.html
