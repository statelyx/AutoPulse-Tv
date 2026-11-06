"""Extract named, genuine XCUITest screenshot attachments; fail on missing pages."""
import json
from pathlib import Path
import shutil
import sys

source, destination = map(Path, sys.argv[1:3])
destination.mkdir(parents=True, exist_ok=True)
manifest = json.loads((source / 'manifest.json').read_text())
pages = ['library', 'import', 'discover', 'photo']
found = set()

def walk(value):
    if isinstance(value, dict):
        name = str(value.get('suggestedHumanReadableName', value.get('name', '')))
        exported = value.get('exportedFileName')
        if exported:
            for index, page in enumerate(pages, 1):
                if f'store-{page}' in name and str(exported).lower().endswith('.png'):
                    shutil.copy2(source / exported, destination / f'{index:02}-{page}.png')
                    found.add(page)
        for child in value.values():
            walk(child)
    elif isinstance(value, list):
        for child in value:
            walk(child)

walk(manifest)
missing = set(pages) - found
if missing:
    raise SystemExit(f'Missing screenshot attachments: {sorted(missing)}; inspect {source / "manifest.json"}')
print(f'Exported {len(found)} genuine screenshots to {destination}')
