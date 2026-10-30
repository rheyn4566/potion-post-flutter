"""Create a portable source ZIP, including the retained private test key."""
import argparse
from pathlib import Path
import zipfile

ROOT = Path(__file__).resolve().parents[1]
EXCLUDED = {'build', '.dart_tool', '.gradle', '.cxx', '.git', '__pycache__',
            'node_modules', 'coverage', '.pub-cache', '.pub', '.idea', 'preview'}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    args.output.parent.mkdir(parents=True, exist_ok=True)
    count = 0
    with zipfile.ZipFile(args.output, 'w', zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
        for path in sorted(ROOT.rglob('*')):
            relative = path.relative_to(ROOT)
            if not path.is_file() or any(part in EXCLUDED for part in relative.parts):
                continue
            if path.name in {'local.properties', '.flutter-plugins-dependencies', '.DS_Store'}:
                continue
            if path.suffix in {'.pyc', '.log', '.apk', '.aab'}:
                continue
            archive.write(path, Path('potion_post') / relative)
            count += 1
    with zipfile.ZipFile(args.output) as archive:
        assert archive.testzip() is None
        assert 'potion_post/test-signing/potion-post-ads-test.jks' in archive.namelist()
        assert 'potion_post/android/gradle/wrapper/gradle-wrapper.jar' in archive.namelist()
        assert 'potion_post/docs/APK_BUILD.json' in archive.namelist()
    print(f'{args.output}: {count} source files, {args.output.stat().st_size:,} bytes; CRCs verified')


if __name__ == '__main__':
    main()
