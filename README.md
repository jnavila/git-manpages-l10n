# GIT Documentation Translations

This project holds the translations for the documentation of Git. This document describes how you can contribute to the effort of enhancing the language coverage and maintaining the translation.

This project is *not* about translating Git itself although the base content (the manpages) is extracted from it. Git uses a workflow for translations which is different from the one used by Git Manpages. If you feel interested, please refer to the [specific instructions][].

## Presentation

This project relies on the Git project itself for the original version of the Git manpages and documents. In order to allow the translations in a maintainable way over the changes to the Git project, the source files are processed with a converter named [po4a][] . This tool converts the source files into gettext po files which can be processed just like gettext internationalization files.

The source files for the manpages are written in [Asciidoc][] with some custom macros. Although the documents are split into simple paragraphs by po4a for translations, Asciidoc inline formatting marks are retained.

The two character language translation codes are defined by ISO_639-1,
as stated in the gettext(1) full manual, appendix A.1, Usual Language
Codes.

# Workflow

## Translation Process Flow

The overall data-flow looks like this:

    +-------------------+            +--------------------+
    | Git source code   |----(2)---->| Git doc translation|
    | repository    (1) |   +--------| repository         |
    +-------------------+   |        +--------------------+
                           (6)             |      ^
                            |             (3)     |
                            |              |     (5)
                            V              V      |
          +--------------------+     +--------------------+
          | Git translated doc |     | Language Team (4)  |
          | repository         |     +--------------------+
   	      +--------------------+

 1. The original documentation files are tagged for a new release 
 2. L10n coordinator pulls from the source and updates the local
    documentation source files and the message template
    po/documentation.pot, and merges the changes into all
    po/documentation.XX.po files
 3. Updated files are available on Weblate.org /Language team pulls
    from Git doc translation repository
 4. Language team updates the message file documentation.XX.po
 5. L10n coordinator pulls from Language team
 6. L10n coordinator updates translated source files for external use 

There are basically two ways to translate the documents. The first one
uses the standard Git workflow, similar to any software project. The
second one uses the more accessible web tool at Weblate.org and is the
preferred way of contributing.

## Contributing through Weblate

The translation files are uploaded to the [hosted weblate website][],
where contributors can easily translate the documents and use all the
helpers that are provided.

Contributing to Git manpages translation requires you to acknowledge
the project's code of contributors.

### Contributing to an existing translation

If the language you plan to translate is already listed, you can just
jump to the language's management page and start fixing translations
or tackling untranslated content. Your inputs will update the
translation file for your language.

The web application handles your submissions and generates a Git
commit in the local repository of weblate after one day of inactivity.

### Creating a new language translation

You cannot directly create a new language in Weblate by yourself, but
you can request the creation of the language to the maintainer. Upon
receiving this request, the maintainer will create the po translation
file and push it.

Weblate will update the list of available language accordingly and you
can then start to contribute.

## Contributing with the Git workflow

### Contributing to an existing translation

As a contributor for a language XX, you should first check TEAMS file
in this directory to see whether a dedicated team for your language XX
exists. Fork the dedicated repository and start to work if it exists.

Otherwise, you can just fork this project and start translating. When
committing, don't forget to follow the code of contribution and add
your "Signed-off-by:" line.

When you feel that your work is worth an update (e.g. a few new
manpages have been translated), you open a pull request to this
repository in order to get your changes merged.

### Creating a new language translation

If you are the first contributor for the language XX, please fork this
repository, prepare and/or update the translated message file
po/documentation.XX.po (described later), and ask the l10n coordinator
to pull your work.

If there are multiple contributors for the same language, please first
coordinate among yourselves and nominate the team leader for your
language, so that the l10n coordinator only needs to interact with one
person per language.

You add a translation for the first time by

 * initializing the translation po file by running:
       msginit --local=XX
   in the po/ directory, where XX is the locale, e.g. "de", "is", "pt_BR",
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

### Testing your changes

(This is done by the language teams, after creating or updating
documentation.XX.po file).

Before being able to compile the documents, you need to have a working
compilation toolchain which you can get by running:

    $ sh ci/install_po4a.sh # install a patched version of po4a
    $ bundle install        # install  asciidoctor

Before you submit your changes do:

    $ bundle exec make all

On systems with GNU gettext (i.e. not Solaris) and po4a, this will try
to merge translations with the source asciidoc files into translated
asciidoc files and compile them to manpages.

Then you can check the translated manpages, for instance for `git add`
in French:

    $ man -l fr/git-add.1

and verify how your translated manpage is rendered.

# Advices for translators

## Helpful Tips

Git is a [version control system](https://en.wikipedia.org/wiki/Version_control) (VCS in short) and this kind of software expects users to understand some dedicated concepts. More generally, translating a tool requires at least a minimum of knowledge of its purpose and use. Git is no exception, and its manpages are full of its specifics.

Here are a few helpful advices in order to help you work through this translation.

### Know a little more about Git

As said earlier, knowing the base of Git is necessary in order to prevent mistranslations. Even if you are not going to be an expert at Git (you could, given the content of the manpages), you can try to install it and make a basic use of it. To get you started, please refer to the introductory chapters of the [Progit book](https://git-scm.com/book/en/v2), at least the first three chapters.

### Set up a glossary of the key concepts

When translating a software where some words have been chosen to hold some key concepts, it is often necessary to maintain a list of the selected translation of these words, that convey the concept correctly and are used in every place the original word is used.

Git provides a [glossary](https://git-scm.com/docs/gitglossary) with definitions and Weblate has a [glossary feature](https://docs.weblate.org/en/latest/user/glossary.html) where a reminder is shown when a glossary term appears in the original string. This is an excellent way to enhance the quality of the translation, while helping translators share the same vocabulary.

Also, some translators of git maintain their own glossary of terms in the headers of the their translation files. You can find these files [in the repository of Git](https://github.com/git/git/tree/master/po).

### Learn a little about Asciidoc formatting

While po4a is quite good at extracting paragraphs from the Asciidoc sources, all the inline formattings are still pushed in the po files. For the translations to be faithful to the original these formatting marks must be pushed at the right places in the translated content.

Learn to recognize [these marks][] and to manage them in your content. 

### Translate placeholders in command lines

When some template command lines contain `<terms-in-brackets>`, it is helpful for the reader that these terms are translated in their language and used repeatedly (use the glossary for that). That way, the reader knows at a glance that this part is a placeholder and the corresponding concept.

### Translate in order

If you don't specify an order on Weblate, the source segments are presented in the order priority, which places in first the content of most used git commands. The corresponding manpages are more susceptible to be read by beginners. So your work has the biggest impact right when starting.

## Get in touch with the maintainer

In case you need to contact the maintainer for e.g. an issue in a source string or an issue with the translated manpages, the project is hosted on [GitHub][] where issues can be opened.

# Maintainer's Tasks

## Maintaining the documentation.pot file

(This is done by the documentation l10n coordinator).

The documentation.pot file in the po directory contains a message
catalog extracted from Git's documentation sources. The l10n
coordinator maintains it by adding new translations or update existing
ones with po4a(1).  In order to update the document sources to extract
the messages from, the l10n coordinator is expected to pull from the
main git repository at strategic point in history (e.g. when a major
release and release candidates are tagged), and then run "make
update-sources" at the top-level directory.

Language contributors use this file to prepare translations for their
language, but they are not expected to modify it.

[specific instructions]: https://github.com/git/git/blob/master/po/README.md
[po4a]: https://github.com/mquinson/po4a
[Asciidoc]: https://asciidoc-py.github.io/index.html
[hosted weblate website]: https://hosted.weblate.org/projects/git-manpages/
[these marks]: https://docs.asciidoctor.org/asciidoc/latest/text/
[Github]: https://github.com/jnavila/git-manpages-l10n
