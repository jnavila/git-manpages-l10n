EN_SOURCES = $(wildcard en/*.txt)
LANGUAGE_PO = $(wildcard po/documentation.*.po)
ALL_LANGUAGES = $(subst po/documentation.,,$(subst .po,,$(LANGUAGE_PO)))

L10N_BUILD_TARGETS = all man html install doc-l10n install-l10n install-txt
L10N_CLEAN_TARGETS = clean mrproper
L10N_TARGETS = $(L10N_CLEAN_TARGETS) $(L10N_BUILD_TARGETS)

QUIET_LANG  = +$(MAKE) -C # space to separate -C and subdir

ifneq ($(findstring $(MAKEFLAGS),s),s)
ifndef V
	QUIET_LANG = +@echo '   ' LANG $(2);$(MAKE) --no-print-directory -C
	export V
endif
endif

po4a.conf: scripts/create_po4a_conf sources.txt $(LANGUAGE_PO)
	@./scripts/create_po4a_conf

po4a-stamp: po4a.conf $(EN_SOURCES) $(LANGUAGE_PO) Makefile
	$(QUIET_PO4A)PERL5LIB=./po4a/lib po4a/po4a -v po4a.conf
	./scripts/set-priorities po/documentation.*.po
	for f in po/documentation.*.po; do ./scripts/pre-translate-po $$f; done
	@touch $@

update-sources:
	@./scripts/update-sources
	$(QUIET_PO4A)PERL5LIB=./po4a/lib po4a/po4a -v --no-translations po4a.conf
	@for f in po/documentation.*.po; do ./scripts/pre-translate-po $$f; done
	@./scripts/set-priorities po/documentation.*.po

define MAKE_TARGET

$(1)_$(2):
	@mkdir -p $(2)
	$(QUIET_LANG) $(2) -f ../makefile.locale $(1) lang=$(2)

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
