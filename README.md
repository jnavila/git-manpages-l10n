# GIT Documentation Translations

=====================

This project holds the translations for the documentation of Git. This
document describes how you can contribute to the effort of enhancing
the language coverage and maintaining the translation.

The two character language translation codes are defined by ISO_639-1,
as stated in the gettext(1) full manual, appendix A.1, Usual Language
Codes.

## Contributing to an existing translation

---------------------------------------

As a contributor for a language XX, you should first check TEAMS file
in this directory to see whether a dedicated team for your language XX
exists. Fork the dedicated repository and start to work if it exists.

Sometimes, contributors may find that the translations of their Git
documentation distributions are quite different with the translations
of the corresponding version from Git official. This is because some
Git distributions (such as from Ubuntu, etc.) have their own l10n
workflow.  For this case, wrong translations should be reported and
fixed through their workflows.

## Creating a new language translation (direct translation)

--------------------------------------------------------

If you are the first contributor for the language XX, please fork this
repository, prepare and/or update the translated message file
po/documentation.XX.po (described later), and ask the l10n coordinator
to pull your work.

If there are multiple contributors for the same language, please first
coordinate among yourselves and nominate the team leader for your
language, so that the l10n coordinator only needs to interact with one
person per language.


## Creating a new language translation (direct translation)

--------------------------------------------------------

Alternatively, you can start translating in your own language by
registering to Weblate and starting a new language translation at

https://hosted.weblate.org/projects/git-manpages/translations/

## Translation Process Flow

------------------------

The overall data-flow looks like this:

    +-------------------+            +------------------+
    | Git source code   | ---(1)---> | L10n coordinator |
    | repository        | <---(4)--- | repository       |
    +-------------------+            +------------------+
                                          |      ^
                                         (2)    (3)
                                          V      |
                                     +------------------+
                                     | Language Team XX |
                                     +------------------+

 * The original documentation files are updated by the development team
 * L10n coordinator pulls from the source (1) and updates the local
   documentation source files and the message template
   po/documentation.pot, and merges the changes into all
   po/documentation.XX.po files
 * Language team pulls from L10n coordinator (2)
 * Language team updates the message file documentation.XX.po (2)
 * L10n coordinator pulls from Language team (3)
 * L10n coordinator asks the result to be integrated (4).

## Maintaining the documentation.pot file

--------------------------------------

(This is done by the documentation l10n coordinator).

The documentation.pot file contains a message catalog extracted from
Git's documentation sources. The l10n coordinator maintains it by
adding new translations or update existing ones with po4a(1).  In
order to update the document sources to extract the messages from, the
l10n coordinator is expected to pull from the main git repository at
strategic point in history (e.g. when a major release and release
candidates are tagged), and then run "make update-sources" at the
top-level directory.

Language contributors use this file to prepare translations for their
language, but they are not expected to modify it.


## Initializing a documentation.XX.po file

---------------------------------------

(This is done by the language teams).

If your language XX does not have translated message file
documentation.XX.po yet, you add a translation for the first time by

 * initializing the translation po file by running:
       msginit --local=XX
   in the po/directory, where XX is the locale, e.g. "de", "is", "pt_BR",
   "zh_CN", etc.
 * pre-translating the file for unchanged strings by running:
       scripts/pre-translate-po po/documentation.XX.po

A file po/documentation.XX.po was created, corresponding
to the newly created translation and is ready for your translations.

Then edit the automatically generated copyright info in your new
documentation.XX.po to be correct, e.g. for Icelandic:

    @@ -1,6 +1,6 @@
    -# Icelandic translations for PACKAGE package.
    -# Copyright (C) 2010 THE PACKAGE'S COPYRIGHT HOLDER
    -# This file is distributed under the same license as the PACKAGE package.
    +# Icelandic translations for Git documentation.
    +# Copyright (C) 2010 Ævar Arnfjörð Bjarmason <avarab@gmail.com>
    +# This file is distributed under the same license as the Git package.
     # Ævar Arnfjörð Bjarmason <avarab@gmail.com>, 2010.

And change references to PACKAGE VERSION in the PO Header Entry to
just "Git Documentation":

    perl -pi -e 's/(?<="Project-Id-Version: )PACKAGE VERSION/Git
    Documentation/' documentation.XX.po

Once you are done testing the translation (see below), commit the
documentation.XX.po files and ask the l10n coordinator to pull from you.

## Updating a documentation.XX.po file

-----------------------------------

(This is done by the language teams).

If you are replacing translation strings in an existing
documentation.XX.po file to improve the translation, just edit the
file.

If there's an existing documentation.XX.po file for your language, but
the repository of the l10n coordinator has newer documentation.pot
file, chances are the upstreamed documentation.XX.po already includes the
changes of the new version.

Once you are done testing the translation (see below), commit the result
and ask the l10n coordinator to pull from you.

## Testing your changes

--------------------

(This is done by the language teams, after creating or updating
documentation.XX.po file).


Before being able to compile the documents, you need to have a working
compilation toolchain which you can get by running:

```sh
    $ sh ci/install_po4a.sh # install a patched version of po4a
    $ bundle install        # install  asciidoctor
```

Before you submit your changes do:

```sh
    $ bundle exec make all
```

On systems with GNU gettext (i.e. not Solaris) and po4a this will try
to merge translations with the source asciidoc files into translated
asciidoc files and compile them to manpages.

Then you can check the translated manpages, for instance for `git add`
in French:

```sh
    $ man -l fr/git-add.1
```

and verify how your translated manpage is rendered.
