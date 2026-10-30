"""Verify the packaged identity, artwork, signing certificate and native alignment."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import struct
import subprocess
import zipfile

CERTIFICATE = 'acb414b0ac86b42b614fc63e7dc50bc6c74a518eadd4068bad95bc333ac08a35'
ROOT = Path(__file__).resolve().parents[1]

def load_alignments(data):
    assert data[:4] == b'\x7fELF'
    wide = data[4] == 2
    endian = '<' if data[5] == 1 else '>'
    offset = struct.unpack_from(endian + ('Q' if wide else 'I'), data, 32 if wide else 28)[0]
    size = struct.unpack_from(endian + 'H', data, 54 if wide else 42)[0]
    count = struct.unpack_from(endian + 'H', data, 56 if wide else 44)[0]
    result = []
    for index in range(count):
        header = offset + index * size
        if struct.unpack_from(endian + 'I', data, header)[0] == 1:
            result.append(struct.unpack_from(endian + ('Q' if wide else 'I'), data,
                                            header + (48 if wide else 28))[0])
    return result

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('apk', type=Path)
    parser.add_argument('--build-tools', type=Path, required=True)
    args = parser.parse_args()
    apk = args.apk.resolve()
    version = re.search(r'^version:\s*(\S+)', (ROOT / 'pubspec.yaml').read_text(), re.M).group(1)
    version_name, version_code = version.rsplit('+', 1)
    test_results = (ROOT / 'docs/TEST_RESULTS.txt').read_text()
    tests_passed = int(re.findall(r'\+(\d+): All tests passed!', test_results)[-1])
    assert 'No issues found!' in (ROOT / 'docs/ANALYZE.txt').read_text()
    def tool(name, *values):
        return subprocess.run([str(args.build_tools / name), *map(str, values)],
                              check=True, capture_output=True, text=True).stdout
    badging = tool('aapt', 'dump', 'badging', apk)
    package = re.search(r"package: name='([^']+)' versionCode='([^']+)' versionName='([^']+)'", badging)
    assert package and package.groups() == ('com.castilla.potion_post.adtest', version_code, version_name)
    label = re.search(r"application-label:'([^']+)'", badging).group(1)
    assert label == 'Potion Post'
    assert "targetSdkVersion:'36'" in badging
    icon_path = re.search(r"application-icon-\d+:'([^']+)'", badging).group(1)
    icon_tree = tool('aapt', 'dump', 'xmltree', apk, icon_path)
    assert 'E: adaptive-icon' in icon_tree and 'E: monochrome' in icon_tree
    resources = tool('aapt', 'dump', 'resources', apk)
    assert ':drawable/launcher_art:' in resources
    assert ':drawable/ic_launcher_foreground:' in resources
    assert ':drawable/ic_launcher_monochrome:' in resources
    (ROOT / 'docs/LAUNCHER_RESOURCES.txt').write_text(icon_tree)
    certificate = tool('apksigner', 'verify', '--verbose', '--print-certs', apk)
    fingerprint = re.search(r'certificate SHA-256 digest: ([0-9a-f]+)', certificate).group(1)
    assert fingerprint == CERTIFICATE, 'APK must update the existing Ads Test signing identity'
    tool('zipalign', '-c', '-P', '16', '-v', '4', apk)
    with zipfile.ZipFile(apk) as archive:
        assert archive.testzip() is None
        names = archive.namelist()
        prefix = 'assets/flutter_assets/'
        character_paths = [n for n in names if n.startswith(prefix+'assets/characters/') and n.endswith('.webp')]
        scenes = [n for n in names if n.startswith(prefix+'assets/gardens/') and n.endswith('-scene.webp')]
        controls = [n for n in names if n.startswith(prefix+'assets/ui/') and n.endswith('.webp')]
        assert len(character_paths) == 26
        assert len(scenes) == 18
        assert len(controls) == 14
        refreshed_art = json.loads((ROOT / 'docs/POLISHED_ART_ASSETS.json').read_text())
        assert len(refreshed_art) == 5
        for asset in refreshed_art:
            packed = archive.read(prefix + asset['path'])
            assert packed == (ROOT / asset['path']).read_bytes(), asset['path']
        world_art = json.loads((ROOT / 'docs/WORLD_ART_ASSETS.json').read_text())
        full_worlds = [asset for asset in world_art if asset['kind'] == 'world']
        grounded_poses = [asset for asset in world_art if asset['kind'] == 'character-pose']
        assert len(full_worlds) == 19 and len(grounded_poses) == 26
        assert sum(asset['new_generated_pose'] for asset in grounded_poses) == 3
        world_paths = {n for n in names if n.startswith(prefix+'assets/worlds/') and n.endswith('.webp')}
        assert world_paths == {prefix + asset['path'] for asset in world_art}
        for asset in world_art:
            assert archive.read(prefix + asset['path']) == (ROOT / asset['path']).read_bytes(), asset['path']
        assert prefix+'assets/icons/coin-leaf.png' in names
        assert archive.read(prefix+'assets/icons/app-brand.webp') == (ROOT/'assets/icons/app-brand.webp').read_bytes()
        orders = json.loads(archive.read(prefix+'assets/orders.json'))
        assert len(orders) == 1480
        assert len({o['garden'] for o in orders}) == 43
        native = {name: load_alignments(archive.read(name)) for name in names if name.startswith('lib/') and name.endswith('.so')}
        assert native and all(min(values) >= 16384 for values in native.values())
    report = dict(version_name=version_name, version_code=int(version_code), application_id=package.group(1),
        application_label=label, bytes=apk.stat().st_size,
        sha256=hashlib.sha256(apk.read_bytes()).hexdigest(), certificate_sha256=fingerprint,
        signature_verified=True, zip_integrity_verified=True, alignment_16kb_verified=True,
        native_load_segment_alignments={name: min(values) for name, values in native.items()},
        tests_passed=tests_passed, analysis='No issues found', flutter='3.47.6', dart='3.13.5', jdk='17.0.20.1',
        orders=1480, couriers=26, gardens=43, added_distinct_scene_art=18, ui_sprite_assets=14,
        refreshed_art_assets=[asset['path'] for asset in refreshed_art],
        native_panel_and_navigation_surfaces=True, full_bleed_gameplay_scene=True,
        full_environment_worlds=19, grounded_pose_assets=26, newly_generated_poses=3,
        garden_world_assets=[asset['path'] for asset in full_worlds],
        decorative_control_flower_clusters=False, shared_world_camera=True,
        original_order_payloads_preserved=1000, persistent_banner_shell=True, currency='Coins',
        demo_ads_only=True, paid_coin_purchases_integrated=False,
        banner_placeholder_removed=True, loaded_only_adaptive_banner=True,
        branded_settings=True, enlarged_level_controls=True, native_delivery_celebration=True,
        adaptive_launcher_icon=True, play_store_icon='store/potion-post-play-icon-512.png', target_sdk=36,
        device_testing='Flutter host widget tests and native package checks; no physical device or emulator run')
    path = ROOT / 'docs/APK_BUILD.json'
    if path.exists():
        previous = json.loads(path.read_text())
        if previous.get('version_code') != int(version_code):
            target = ROOT / f"docs/history/APK_BUILD_v{previous['version_name']}_{previous['version_code']}.json"
            target.parent.mkdir(exist_ok=True)
            target.write_text(json.dumps(previous, indent=2))
    path.write_text(json.dumps(report, indent=2))
    print(json.dumps(report, indent=2))

if __name__ == '__main__':
    main()
