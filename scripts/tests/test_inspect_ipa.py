import importlib.util
import pathlib
import plistlib
import tempfile
import unittest
import zipfile

spec = importlib.util.spec_from_file_location('inspect_ipa', pathlib.Path(__file__).parents[1] / 'inspect_ipa.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class InspectIPATests(unittest.TestCase):
    def inspect_archive(self, entries):
        with tempfile.TemporaryDirectory() as directory:
            path = pathlib.Path(directory) / 'app.ipa'
            with zipfile.ZipFile(path, 'w') as archive:
                for name, data in entries.items():
                    archive.writestr(name, data)
            return module.inspect(path)

    def test_phone_build_does_not_claim_carplay(self):
        result = self.inspect_archive({'Payload/App.app/Info.plist': plistlib.dumps({'CFBundleIdentifier': 'test.app'})})
        self.assertFalse(result['carplay_scene_declared'])
        self.assertFalse(result['profile_permits_carplay_video'])

    def test_profile_permission_does_not_claim_signature_verification(self):
        info = {'UIApplicationSceneManifest': {'UISceneConfigurations': {
            'CPTemplateApplicationSceneSessionRoleApplication': [{'UISceneDelegateClassName': 'App.CarPlaySceneDelegate'}]}}}
        profile = {'Entitlements': {'com.apple.developer.carplay-video': True}}
        result = self.inspect_archive({
            'Payload/App.app/Info.plist': plistlib.dumps(info),
            'Payload/App.app/embedded.mobileprovision': b'CMS-prefix' + plistlib.dumps(profile) + b'CMS-suffix'})
        self.assertTrue(result['carplay_scene_declared'])
        self.assertTrue(result['profile_permits_carplay_video'])
        self.assertFalse(result['code_signature_verified'])
        self.assertFalse(result['receiver_video_capability_verified'])

    def test_ambiguous_main_app_rejected(self):
        with self.assertRaises(ValueError):
            self.inspect_archive({f'Payload/{name}.app/Info.plist': plistlib.dumps({}) for name in ['One', 'Two']})


if __name__ == '__main__':
    unittest.main()
