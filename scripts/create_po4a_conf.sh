#!/bin/bash

echo -n "[po4a_langs]" >po4a.conf
for l in po/documentation.*.po
do
    rstripped=${l%%.po}
    echo -n " ${rstripped##po/documentation.}" >> po4a.conf
done
echo >> po4a.conf

cat <<EOF >>po4a.conf
[po4a_paths] po/documentation.pot \$lang:po/documentation.\$lang.po
[options] opt: " -k 80"

EOF

for f in $(cat sources.txt)
do
echo "[type: asciidoc] en/$f \$lang:./\$lang/$f" >> po4a.conf
done
