import 'package:flutter_test/flutter_test.dart';
import 'package:saturn_app/saturn_orbit_cloud.dart';

void main() {
  test('Personal SATURN cloud has public client configuration', () {
    expect(SaturnCloudConfig.enabled, isTrue);
    expect(SaturnCloudConfig.url,
      'https://uiyjeiddnirdhquapkic.supabase.co');
    expect(SaturnCloudConfig.publishableKey,
      startsWith('sb_publishable_'));
    expect(SaturnCloudConfig.publishableKey,
      isNot(contains('service_role')));
    expect(SaturnCloudConfig.publishableKey,
      isNot(contains('sb_secret_')));
  });
}
