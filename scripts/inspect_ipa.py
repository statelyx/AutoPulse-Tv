"""Inspect packaged CarPlay configuration. Does not verify Apple's cryptographic signature."""
import argparse
import json
import plistlib
import zipfile


def inspect(path):
    with zipfile.ZipFile(path) as archive:
        candidates = [n for n in archive.namelist()
                      if n.startswith('Payload/') and n.count('/') == 2 and n.endswith('.app/Info.plist')]
        if len(candidates) != 1:
            raise ValueError('Expected one main application Info.plist')
        info_path = candidates[0]
        base = info_path.rsplit('/', 1)[0] + '/'
        info = plistlib.loads(archive.read(info_path))
        scenes = info.get('UIApplicationSceneManifest', {}).get('UISceneConfigurations', {})
        configurations = scenes.get('CPTemplateApplicationSceneSessionRoleApplication', [])
        profile_path = base + 'embedded.mobileprovision'
        profile = {}
        if profile_path in archive.namelist():
            data = archive.read(profile_path)
            start = data.find(b'<?xml')
            end = data.find(b'</plist>', start)
            if start >= 0 and end >= 0:
                profile = plistlib.loads(data[start:end + len(b'</plist>')])
        permitted = profile.get('Entitlements', {}).get('com.apple.developer.carplay-video', False)
        return {
            'bundle_id': info.get('CFBundleIdentifier'),
            'display_name': info.get('CFBundleDisplayName'),
            'minimum_os': info.get('MinimumOSVersion'),
            'carplay_scene_declared': bool(configurations),
            'scene_delegates': [c.get('UISceneDelegateClassName') for c in configurations],
            'provisioning_profile_found': bool(profile),
            'profile_permits_carplay_video': bool(permitted),
            'code_signature_verified': False,
            'receiver_video_capability_verified': False,
            'testflight_or_app_store_status_verified': False,
            'note': 'A matching code-signature entitlement, Apple authorization and a compatible receiver are also required.'
        }


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('ipa')
    args = parser.parse_args()
    print(json.dumps(inspect(args.ipa), indent=2))
