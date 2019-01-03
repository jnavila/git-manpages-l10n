EN_SOURCES = $(wildcard en/*.txt)
LANGUAGE_PO = $(wildcard po/*.po)
ALL_LANGUAGES = $(subst po/documentation.,,$(subst .po,,$(LANGUAGE_PO)))

TARGETS = all man html clean install doc-l10n install-l10n mrproper

ifneq ($(findstring $(MAKEFLAGS),s),s)
ifndef V
	QUIET_PO4A      = @echo '   ' PO4A $@;
	QUIET_ASCIIDOC	= @echo '   ' ASCIIDOC $@;
	QUIET_XMLTO	= @echo '   ' XMLTO $@;
	QUIET_DB2TEXI	= @echo '   ' DB2TEXI $@;
	QUIET_MAKEINFO	= @echo '   ' MAKEINFO $@;
	QUIET_DBLATEX	= @echo '   ' DBLATEX $@;
	QUIET_XSLTPROC	= @echo '   ' XSLTPROC $@;
	QUIET_GEN	= @echo '   ' GEN $@;
	QUIET_LINT	= @echo '   ' LINT $@;
	QUIET_STDERR	= 2> /dev/null
	QUIET_SUBDIR0	= +@subdir=
	QUIET_SUBDIR1	= ;$(NO_SUBDIR) echo '   ' SUBDIR $$subdir; \
			  $(MAKE) $(PRINT_DIR) -C $$subdir
	export V
endif
endif

po4a.conf: create_po4a_conf.sh sources.txt
	./create_po4a_conf.sh

po4a-stamp: po4a.conf $(EN_SOURCES) $(LANGUAGE_PO) Makefile
	$(QUIET_PO4A)po4a -v po4a.conf
	@touch $@

update-sources:
	./update-sources.sh

define MAKE_TARGET

$(1)_$(2):
	@echo $lang; cd $(2) && $(MAKE) -f ../makefile.locale $(1) lang=$(2)

$(1): $(1)_$(2)

.PHONY: $(1)_$(2)

endef

.PHONY: $(TARGETS)

man all html : po4a-stamp

$(foreach lang,$(ALL_LANGUAGES),$(foreach target, $(TARGETS), $(eval $(call MAKE_TARGET,$(target),$(lang)))))

mrproper: mrproper-local

mrproper-local:
	rm -f po4a-stamp
