"""Check the synchronizer against a prepared Git Documentation directory."""

import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile


repo = Path(__file__).resolve().parents[1]
upstream = Path(sys.argv[1]).resolve()
with tempfile.TemporaryDirectory() as work:
    english = Path(work) / "en"
    shutil.copytree(repo / "en", english)
    pending = [path.relative_to(english) for path in english.rglob("*.adoc")]
    subprocess.run([repo / "scripts/update-sources"], cwd=work, check=True,
                   env={**os.environ, "SOURCE_PATH": str(upstream)})
    subprocess.run([repo / "scripts/create_po4a_conf"], cwd=work, check=True)
    configured = {line.split()[2] for line in (Path(work) / "po4a.conf").read_text().splitlines()
                  if line.startswith("[type: asciidoc] ")}

    checked = set()
    while pending:
        name = pending.pop()
        if name in checked:
            continue
        checked.add(name)
        original = upstream / name
        content = original.read_bytes()
        if (english / name).read_bytes() != content:
            sys.exit(f"Source differs from Git: {name}")
        if f"en/{name}" not in configured:
            sys.exit(f"Source missing from po4a.conf: {name}")
        for line in content.decode("utf-8").splitlines():
            if line.startswith("include::"):
                target = line[len("include::"):].split("[", 1)[0]
                included = original.parent / target
                if target.startswith("{build_dir}/"):
                    included = upstream / target[len("{build_dir}/"):]
                pending.append(included.resolve().relative_to(upstream))

    print(f"Verified {len(checked)} synchronized documentation sources.")
