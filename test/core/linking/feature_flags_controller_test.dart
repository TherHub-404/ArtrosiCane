import 'package:artrosi_cane/core/linking/feature_flags_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FeatureFlagsController', () {
    test('normalizes Bibione aliases from deep links', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final controller = FeatureFlagsController(prefs);

      await controller.persistInviteLocationFromLink('bibiobe');
      expect(controller.state.inviteLocation, 'bibione');
      expect(prefs.getString('invite_location'), 'bibione');

      await controller.persistInviteLocationFromLink('bibbine');
      expect(controller.state.inviteLocation, 'bibione');
      expect(prefs.getString('invite_location'), 'bibione');
    });

    test('clears location when the link has empty/missing location', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final controller = FeatureFlagsController(prefs);

      await controller.persistInviteLocationFromLink('bibbione');
      expect(controller.state.inviteLocation, 'bibione');

      await controller.persistInviteLocationFromLink(null);
      expect(controller.state.inviteLocation, isNull);
      expect(prefs.containsKey('invite_location'), isFalse);
    });

    test('hydrates location even without persisted flags', () async {
      SharedPreferences.setMockInitialValues({
        'invite_location': 'bibbine',
      });
      final prefs = await SharedPreferences.getInstance();
      final controller = FeatureFlagsController(prefs);

      expect(controller.state.inviteLocation, 'bibione');
    });
  });
}
