EN_SOURCES = $(wildcard en/*.adoc)
LANGUAGE_PO = $(wildcard po/documentation.*.po)
ALL_LANGUAGES = $(subst po/documentation.,,$(subst .po,,$(LANGUAGE_PO)))

L10N_BUILD_TARGETS = all man html install doc-l10n install-l10n install-adoc
L10N_CLEAN_TARGETS = clean cleaner mrproper
L10N_TARGETS = $(L10N_CLEAN_TARGETS) $(L10N_BUILD_TARGETS)

QUIET_LANG  = +$(MAKE) -C # space to separate -C and subdir

ifneq ($(findstring $(MAKEFLAGS),s),s)
ifndef V
	QUIET_PO4A = @echo '   ' PO4A $(lang) $@;
	QUIET_LANG = +@echo '   ' LANG $(2);$(MAKE) --no-print-directory -C
	export V
endif
endif

po4a.conf: scripts/create_po4a_conf sources.txt
	@./scripts/create_po4a_conf

po/documentation.pot: po4a.conf $(EN_SOURCES) Makefile
	$(QUIET_PO4A)PERL5LIB=./po4a/lib po4a/po4a -v po4a.conf --no-translations
	@./scripts/set-priorities po/documentation.*.po
	@for f in po/documentation.*.po; do ./scripts/pre-translate-po $$f; done
	@touch po/documentation.pot

update-pot: po/documentation.pot

update-sources:
	@./scripts/update-sources
	$(QUIET_PO4A)PERL5LIB=./po4a/lib po4a/po4a -v --no-translations po4a.conf
	@for f in po/documentation.*.po; do ./scripts/pre-translate-po $$f; done
	@./scripts/set-priorities po/documentation.*.po

define MAKE_TARGET

$(2)/.$(1):
	@mkdir -p $(2)
	$(QUIET_LANG) $(2) -f ../makefile.locale $(1) lang=$(2)
	@touch $(2)/.$(1)


$(2)/.$(1): $(2)/.translated

$(1): $(2)/.$(1)

endef

define PROCESS_LANG
$(1)/.translated: po/documentation.$(1).po po/documentation.pot
	@mkdir -p $(1)
	$(QUIET_PO4A)PERL5LIB=./po4a/lib po4a/po4a -v -f ./po4a.conf --target-lang=$(1) --no-update
	@touch $(1)/.translated

$(1)/.man: asciidoctor-extensions.rb
$(1)/.html: asciidoctor-extensions.rb
endef

.PHONY: $(L10N_BUILD_TARGETS) $(L10N_CLEAN_TARGETS) update-pot

man all html doc-l10n : po/documentation.pot

$(foreach lang,$(ALL_LANGUAGES),$(foreach target,$(L10N_TARGETS),$(eval $(call MAKE_TARGET,$(target),$(lang),DEPEND_PO4A))))

$(foreach lang,$(ALL_LANGUAGES),$(foreach target,$(L10N_BUILD_TARGETS),$(eval $(call DEPEND_PO4A,$(target),$(lang)))))

$(foreach lang,$(ALL_LANGUAGES),$(eval $(call PROCESS_LANG,$(lang))))

mrproper: mrproper-local

mrproper-local:
	rm -f po4a-stamp po4a.conf */.translated */.man */.html */.install */.doc-l10n */.install-l10n */.install-txt
