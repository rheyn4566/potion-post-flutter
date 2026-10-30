"""Offer a lossless ZIP download containing exactly the verified signed APK."""
import argparse
import hashlib
import json
from pathlib import Path
import zipfile

root = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument('apk', type=Path)
parser.add_argument('output', type=Path)
args = parser.parse_args()
apk = args.apk.resolve()
with apk.open('rb') as stream:
    digest = hashlib.file_digest(stream, 'sha256').hexdigest()
verified = json.loads((root/'docs/APK_BUILD.json').read_text())
assert verified['sha256'] == digest, 'Verify this exact signed APK first'
args.output.parent.mkdir(parents=True, exist_ok=True)
with zipfile.ZipFile(args.output, 'w', zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
    archive.write(apk, apk.name)
with zipfile.ZipFile(args.output) as archive:
    assert archive.namelist() == [apk.name]
    assert archive.testzip() is None
    with archive.open(apk.name) as stream:
        assert hashlib.file_digest(stream, 'sha256').hexdigest() == digest
with args.output.open('rb') as stream:
    zip_digest = hashlib.file_digest(stream, 'sha256').hexdigest()
report = {
    'apk_name': apk.name,
    'apk_bytes': apk.stat().st_size,
    'apk_sha256': digest,
    'zip_name': args.output.name,
    'zip_bytes': args.output.stat().st_size,
    'zip_sha256': zip_digest,
    'zip_integrity_verified': True,
    'inner_apk_byte_identical': True,
    'instructions': 'Extract the APK and install it as an Update to keep existing private progress.',
}
(root/'docs/INSTALLER_BUILD.json').write_text(json.dumps(report, indent=2))
print(json.dumps(report, indent=2))
