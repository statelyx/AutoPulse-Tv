"""Portable syntax/config checks; not a replacement for an Apple SDK build."""
from pathlib import Path
import json
import plistlib
import sys
import yaml
from tree_sitter import Language, Parser
import tree_sitter_swift

root = Path(__file__).resolve().parents[1]
parser = Parser(Language(tree_sitter_swift.language()))
failures = []
def project_files(pattern):
    return [p for p in root.rglob(pattern) if not {'.git', '.local', '.venv', 'build'}.intersection(p.relative_to(root).parts)]

swift_files = project_files('*.swift')
for path in swift_files:
    tree = parser.parse(path.read_bytes())
    if tree.root_node.has_error:
        def errors(node):
            if node.type == 'ERROR' or node.is_missing:
                failures.append(f'{path.relative_to(root)}:{node.start_point}: {node.type}')
            for child in node.children:
                errors(child)
        errors(tree.root_node)
for path in [*project_files('*.yml'), *project_files('*.yaml')]:
    yaml.safe_load(path.read_text(encoding='utf-8-sig'))
for path in [*project_files('*.xcprivacy'), *project_files('*.entitlements')]:
    plistlib.loads(path.read_bytes())
for path in project_files('Contents.json'):
    json.loads(path.read_text())
legacy = []
for path in project_files('*'):
    if not path.is_file() or '.git' in path.relative_to(root).parts:
        continue
    if path.suffix in ['.swift', '.yml', '.yaml', '.md', '.sh', '.entitlements']:
        if 'ParkPlay' in path.read_text(encoding='utf-8-sig'):
            legacy.append(str(path.relative_to(root)))
report = {'swift_files_syntax_checked': len(swift_files), 'syntax_errors': failures,
          'yaml_plist_json_parsed': True, 'legacy_brand_references': legacy,
          'apple_sdk_build_run': False, 'xctest_run': False, 'vehicle_test_run': False}
(root / 'VALIDATION.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
print(json.dumps(report, indent=2))
if failures or legacy:
    sys.exit(1)
