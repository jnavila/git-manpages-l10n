#!/bin/bash

(cat <<EOF
[po4a_langs] fr
[po4a_paths] po/documentation.pot \$lang:po/documentation.\$lang.po
[options] opt: " -k 80"

EOF
) >po4a.conf 

for f in $(cat sources.txt)
do
echo "[type: asciidoc] en/$f \$lang:./\$lang/$f" >> po4a.conf
done
