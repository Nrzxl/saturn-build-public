import 'saturn_notification_inbox.dart';

/// Browser and unsupported devices continue using SATURN's Web Push.
class SaturnAndroidNotice {
  static bool get supported => false;
  static Future<bool> enable(List<SaturnNotice> current,
          {required int profile}) async => false;
  static Future<void> disable() async {}
  static Future<void> onCloudSync(List<SaturnNotice> current,
      {required int profile}) async {}
}
