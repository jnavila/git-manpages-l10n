EN_SOURCES = $(wildcard en/*.txt)
LANGUAGE_PO = $(wildcard po/*.po)
ALL_LANGUAGES = $(subst po/documentation.,,$(subst .po,,$(LANGUAGE_PO)))

L10N_BUILD_TARGETS = all man html install doc-l10n install-l10n
L10N_CLEAN_TARGETS = clean mrproper
L10N_TARGETS = $(L10N_CLEAN_TARGETS) $(L10N_BUILD_TARGETS)

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
	$(QUIET_PO4A)PERL5LIB=./po4a/lib po4a/po4a -v po4a.conf
	@touch $@

update-sources:
	./update-sources.sh

define MAKE_TARGET

$(1)_$(2):
	+$(MAKE) -C $(2) -f ../makefile.locale $(1) lang=$(2)

$(1): $(1)_$(2)

.PHONY: $(1)_$(2)

endef

define DEPEND_PO4A
 $(1)_$(2): po4a-stamp
endef

.PHONY: $(L10N_BUILD_TARGETS) $(L10N_CLEAN_TARGETS)

man all html doc-l10n : po4a-stamp

$(foreach lang,$(ALL_LANGUAGES),$(foreach target,$(L10N_TARGETS),$(eval $(call MAKE_TARGET,$(target),$(lang),DEPEND_PO4A))))

$(foreach lang,$(ALL_LANGUAGES),$(foreach target,$(L10N_BUILD_TARGETS),$(eval $(call DEPEND_PO4A,$(target),$(lang)))))

mrproper: mrproper-local

mrproper-local:
	rm -f po4a-stamp po4a.conf
