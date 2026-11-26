#!/bin/sh
set -eu

repo=$(pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
docs="$work/git/Documentation"
mkdir -p "$docs/config" "$docs/mergetools" "$work/l10n/en" "$work/l10n/po"
cp "$repo/GIT-VERSION-FILE" "$work/git/"
cp "$repo/Makefile" "$repo/makefile.locale" "$work/l10n/"
ln -s "$repo/scripts" "$work/l10n/scripts"
ln -s "$repo/po4a" "$work/l10n/po4a"

for page in "$repo"/en/git*.adoc; do
    echo 'Existing manual.' >"$docs/${page##*/}"
done
printf 'Configuration reference.\n\ninclude::config/example.adoc[]\n' >"$docs/git-config.adoc"
echo 'include::{build_dir}/mergetools/vimdiff.adoc[]' >"$docs/config/example.adoc"

cd "$work/l10n"
echo 'Earlier manual.' >en/git-config.adoc
cat >po/documentation.fr.po <<'EOF'
msgid ""
msgstr ""
"Language: fr\n"
"Content-Type: text/plain; charset=UTF-8\n"

msgid "Nested paragraph."
msgstr "Paragraphe imbriqué."
EOF
./scripts/create_po4a_conf
export SOURCE_PATH="$docs"
if make update-sources >missing.log 2>&1; then
    echo 'Expected the missing include to fail the source update.' >&2
    exit 1
fi
grep -F "Required documentation source not found: $docs/mergetools/vimdiff.adoc" missing.log
grep -Fxq 'Earlier manual.' en/git-config.adoc
test ! -e en/config/example.adoc

echo 'Nested paragraph.' >"$docs/mergetools/vimdiff.adoc"
make -j4 update-sources install-translated prefix="$work/export"
grep -Fq 'en/mergetools/vimdiff.adoc' po4a.conf
grep -Fq 'msgid "Nested paragraph."' po/documentation.pot
python3 -c 'import polib
entry = polib.pofile("po/documentation.fr.po").find("Configuration reference.")
assert "priority:10" in entry.flags, entry.flags'
grep -Fxq 'Paragraphe imbriqué.' "$work/export/fr/mergetools/vimdiff.adoc"

if make install-translated prefix="$work/l10n/en/staging" >overlap.log 2>&1; then
    echo 'Expected an installation inside the English sources to fail.' >&2
    exit 1
fi
grep -Fq 'Installation destination is inside the English source tree' overlap.log
test ! -e en/staging

echo 'Revised paragraph.' >"$docs/mergetools/vimdiff.adoc"
touch -t 200001010000 "$docs/mergetools/vimdiff.adoc"
make update-sources
grep -Fq 'msgid "Revised paragraph."' po/documentation.pot
