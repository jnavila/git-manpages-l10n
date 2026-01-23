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
	QUIET_ASCIIDOC = @echo '   ' ASCIIDOC $(lang) $@;
	export V
endif
endif

# Include GIT version
-include GIT-VERSION-FILE

# Asciidoctor options for building manpages
ASCIIDOC_EXTRA = -d manpage -rasciidoctor-extensions
ASCIIDOC_EXTRA += -amanmanual='Git Manual' \
                  -amansource='Git $(GIT_VERSION)' \
                  -amanversion=$(GIT_VERSION)
ASCIIDOC_EXTRA += -alitdd='\--'
ASCIIDOC_EXTRA += -acompat-mode -atabsize=8

# Top-level targets (only when not building in a language directory)
ifeq ($(lang),)

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

# Build manpages and HTML for a language after translation
# Uses recursive make invocation to compile files in parallel
define BUILD_LANG_DOCS
$(1)/.man: $(1)/.translated asciidoctor-extensions.rb GIT-VERSION-FILE
	@if [ -d $(1) ]; then \
		man1_files=$$$$(cd $(1) && find . -maxdepth 1 -name 'git-*.adoc' -o -name 'git.adoc' 2>/dev/null | sed 's/\.adoc$$$$/.1/'); \
		man5_files=$$$$(cd $(1) && find . -maxdepth 1 -name 'gitignore.adoc' 2>/dev/null | sed 's/\.adoc$$$$/.5/'); \
		man7_files=$$$$(cd $(1) && find . -maxdepth 1 -name 'gitglossary.adoc' 2>/dev/null | sed 's/\.adoc$$$$/.7/'); \
		all_files="$$$$man1_files $$$$man5_files $$$$man7_files"; \
		if [ -n "$$$$all_files" ]; then \
			$(MAKE) -C $(1) -f ../Makefile lang=$(1) $$$$man1_files $$$$man5_files $$$$man7_files; \
		fi; \
	fi
	@touch $(1)/.man

$(1)/.html: $(1)/.translated asciidoctor-extensions.rb GIT-VERSION-FILE
	@if [ -d $(1) ]; then \
		html_files=$$$$(cd $(1) && find . -maxdepth 1 -name '*.adoc' 2>/dev/null | sed 's/\.adoc$$$$/.html/'); \
		if [ -n "$$$$html_files" ]; then \
			$(MAKE) -C $(1) -f ../Makefile lang=$(1) $$$$html_files; \
		fi; \
	fi
	@touch $(1)/.html

$(1)/.all: $(1)/.man $(1)/.html
	@touch $(1)/.all

$(1)/.doc-l10n: $(1)/.all
	@touch $(1)/.doc-l10n

$(1)/.install-adoc:
	@if [ -d $(1) ]; then \
		install -d -m 755 $$(prefix)/$(1); \
		cd $(1) && [ -n "$$$$(ls *.adoc 2>/dev/null)" ] && install *.adoc -m 644 $$(prefix)/$(1) || true; \
		cd $(1) && [ -n "$$$$(ls *.html 2>/dev/null)" ] && install *.html -m 644 $$(prefix)/$(1) || true; \
		install -d -m 755 $$(prefix)/$(1)/includes; \
		cd $(1) && [ -n "$$$$(ls includes/*.adoc 2>/dev/null)" ] && install includes/*.adoc -m 644 $$(prefix)/$(1)/includes || true; \
		cd $(1) && [ -n "$$$$(ls includes/*.html 2>/dev/null)" ] && install includes/*.html -m 644 $$(prefix)/$(1)/includes || true; \
	fi
	@touch $(1)/.install-adoc

$(1)/.install-l10n: $(1)/.man
	@if [ -d $(1) ]; then \
		install -d -m 755 $$(DESTDIR)$$(mandir)/$(1)/man1; \
		install -d -m 755 $$(DESTDIR)$$(mandir)/$(1)/man5; \
		install -d -m 755 $$(DESTDIR)$$(mandir)/$(1)/man7; \
		cd $(1) && [ -n "$$$$(ls *.1 2>/dev/null)" ] && install -m 644 *.1 $$(DESTDIR)$$(mandir)/$(1)/man1 || true; \
		cd $(1) && [ -n "$$$$(ls *.5 2>/dev/null)" ] && install -m 644 *.5 $$(DESTDIR)$$(mandir)/$(1)/man5 || true; \
		cd $(1) && [ -n "$$$$(ls *.7 2>/dev/null)" ] && install -m 644 *.7 $$(DESTDIR)$$(mandir)/$(1)/man7 || true; \
	fi
	@touch $(1)/.install-l10n

$(1)/.install: $(1)/.install-l10n
	@touch $(1)/.install

$(1)/.clean:
	@if [ -d $(1) ]; then \
		cd $(1) && rm -f *.1 *.5 *.7 *.html .man .all .translated .install .install-l10n .install-adoc .doc-l10n; \
	fi

$(1)/.cleaner: $(1)/.clean

$(1)/.mrproper: $(1)/.clean
	@if [ -d $(1) ]; then \
		cd $(1) && rm -f *.adoc; \
	fi
endef

define PROCESS_LANG
$(1)/.translated: po/documentation.$(1).po po/documentation.pot
	@mkdir -p $(1)
	$(QUIET_PO4A)PERL5LIB=./po4a/lib po4a/po4a -v -f ./po4a.conf --target-lang=$(1) --no-update
	@touch $(1)/.translated

# Generate all build targets for this language
$(call BUILD_LANG_DOCS,$(1))
endef

# Define phony targets that build all languages
define BUILD_TARGET
$(1): $$(foreach lang,$$(ALL_LANGUAGES),$$(lang)/.$(1))
endef

.PHONY: $(L10N_BUILD_TARGETS) $(L10N_CLEAN_TARGETS) update-pot

man all html doc-l10n : po/documentation.pot

# Generate targets for each language
$(foreach lang,$(ALL_LANGUAGES),$(eval $(call PROCESS_LANG,$(lang))))

# Generate phony targets for build commands
$(foreach target,$(L10N_BUILD_TARGETS),$(eval $(call BUILD_TARGET,$(target))))

# Generate phony targets for clean commands
clean: $(foreach lang,$(ALL_LANGUAGES),$(lang)/.clean)
cleaner: $(foreach lang,$(ALL_LANGUAGES),$(lang)/.cleaner)

mrproper: mrproper-local $(foreach lang,$(ALL_LANGUAGES),$(lang)/.mrproper)

mrproper-local:
	rm -f po4a-stamp po4a.conf */.translated */.man */.html */.install */.doc-l10n */.install-l10n */.install-txt */.install-adoc

endif  # ifeq ($(lang),)

# Pattern rules for compiling .adoc files to manpages and HTML
# These are used by the recursive make invocation in BUILD_LANG_DOCS
ifneq ($(lang),)
ifndef V
	QUIET_ASCIIDOC = @echo '   ' ASCIIDOC $(lang) $@;
endif

%.1: %.adoc
	$(QUIET_ASCIIDOC)asciidoctor -b manpage -o $@ \
		$(ASCIIDOC_EXTRA) -I.. -I. -amanvolnum=1 -abuild_dir=. $<

%.5: %.adoc
	$(QUIET_ASCIIDOC)asciidoctor -b manpage -o $@ \
		$(ASCIIDOC_EXTRA) -I.. -I. -amanvolnum=5 -abuild_dir=. $<

%.7: %.adoc
	$(QUIET_ASCIIDOC)asciidoctor -b manpage -o $@ \
		$(ASCIIDOC_EXTRA) -I.. -I. -amanvolnum=7 -abuild_dir=. $<

%.html: %.adoc
	$(QUIET_ASCIIDOC)asciidoctor -b xhtml5 \
		$(ASCIIDOC_EXTRA) -I.. -I. -abuild_dir=. $<
endif
