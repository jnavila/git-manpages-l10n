EN_SOURCES = $(wildcard en/*.adoc) $(wildcard en/config/*.adoc) $(wildcard en/includes/*.adoc)
DOC_SOURCES = $(wildcard en/git*.adoc)
DOCS = $(patsubst en/%.adoc,%.adoc,$(DOC_SOURCES))
LANGUAGE_PO = $(wildcard po/documentation.*.po)
ALL_LANGUAGES = $(subst po/documentation.,,$(subst .po,,$(LANGUAGE_PO)))

L10N_BUILD_TARGETS = all man html
L10N_INSTALL_TARGETS = man html translated

QUIET_LANG  = +$(MAKE) -C # space to separate -C and subdir

ifneq ($(findstring $(MAKEFLAGS),s),s)
ifndef V
	QUIET_PO4A = @echo '   ' PO4A $(lang) $@;
	QUIET_DEPS = @echo '   ' DEPS $(lang) $@;
	QUIET_LANG = +@echo '   ' LANG $(2);$(MAKE) --no-print-directory -C
	export V
endif
endif

po4a.conf: scripts/create_po4a_conf en/*.adoc en/config/*.adoc en/includes/*.adoc
	@echo '   ' PO4A $@;./scripts/create_po4a_conf

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

define PROCESS_LANG
$(1)/.translated: po/documentation.$(1).po po/documentation.pot
	@mkdir -p $(1)
	$(QUIET_PO4A)PERL5LIB=./po4a/lib po4a/po4a -f ./po4a.conf --target-lang=$(1) --no-update
	@$(QUIET_DEPS)cd $(1) && ../scripts/generate-make-deps $(DOCS)
	@touch $(1)/.translated
endef

define MAKE_BUILD_TARGET

$(2)/.$(1):
	@mkdir -p $(2)
	$(QUIET_LANG) $(2) -f ../makefile.locale $(1) lang=$(2) && touch $(2)/.$(1)

$(2)/.$(1): $(2)/.translated GIT-VERSION-FILE asciidoctor-extensions.rb makefile.locale

$(1): $(2)/.$(1)

endef

define MAKE_INSTALL_TARGET

$(2)/.install-$(1): $(2)/.$(1)
	@mkdir -p $(2)
	$(QUIET_LANG) $(2) -f ../makefile.locale install-$(1) lang=$(2)

install-$(1): $(2)/.install-$(1)

PHONY: $(2)/.install-$(1)

endef


.PHONY: $(L10N_BUILD_TARGETS) $(L10N_CLEAN_TARGETS) update-pot

man all html doc-l10n : po/documentation.pot

$(foreach lang,$(ALL_LANGUAGES),$(eval $(call PROCESS_LANG,$(lang))))

$(foreach lang,$(ALL_LANGUAGES),$(foreach target,$(L10N_BUILD_TARGETS),$(eval $(call MAKE_BUILD_TARGET,$(target),$(lang)))))

$(foreach lang,$(ALL_LANGUAGES),$(foreach target,$(L10N_INSTALL_TARGETS),$(eval $(call MAKE_INSTALL_TARGET,$(target),$(lang),DEPEND_PO4A))))

mrproper: mrproper-local

mrproper-local:
	@echo CLEAN && rm -f po4a-stamp po4a.conf */.translated */.man */.html */.install */.doc-l10n */.install-l10n */.install-adoc */*.1 */*.5 */*.7 */*.html
