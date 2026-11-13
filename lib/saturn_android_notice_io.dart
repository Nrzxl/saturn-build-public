import 'dart:io';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'saturn_notification_inbox.dart';

/// Native Android NotificationManager bridge for verified partner activity
/// observed during the app's authenticated, live Supabase session.
/// This is NOT FCM: a force-closed APK cannot receive background messages.
class SaturnAndroidNotice {
  static const MethodChannel _channel = MethodChannel('saturn/native_notices');
  static const _enabledKey = 'saturn_android_notices_enabled_v1';
  static const _seenPrefix = 'saturn_android_notices_seen_v1_';
  static bool _busy = false;

  static bool get supported => Platform.isAndroid;

  static Future<bool> enable(List<SaturnNotice> current,
      {required int profile}) async {
    if (!supported) return false;
    final permitted = await _channel.invokeMethod<bool>('requestPermission') ??
        false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, permitted);
    if (permitted) {
      // Opt-in starts from now; never flood the notification shade with
      // historic reviews, and never silently switch the other person's role.
      await prefs.setStringList(_seenPrefix + profile.toString(),
          current.map((item) => item.id).take(200).toList());
    }
    return permitted;
  }

  static Future<void> disable() async {
    if (!supported) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, false);
  }

  static Future<void> onCloudSync(List<SaturnNotice> current,
      {required int profile}) async {
    if (!supported || _busy || (profile != 0 && profile != 1)) return;
    _busy = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_enabledKey) != true) return;
      final key = _seenPrefix + profile.toString();
      final previous = prefs.getStringList(key);
      if (previous == null) {
        // Migration/first launch after updating the APK: establish baseline.
        await prefs.setStringList(key,
            current.map((notice) => notice.id).take(200).toList());
        return;
      }
      final seen = previous.toSet();
      // Only post genuine partner events first observed after opt-in.
      final fresh = current.where((item) => !seen.contains(item.id))
          .take(3).toList(growable: false);
      for (final item in fresh.reversed) {
        try {
          await _channel.invokeMethod<void>('notify', {
            'id': item.id.hashCode & 0x7fffffff,
            'title': item.headline,
            'body': item.title,
          });
        } catch (_) {
          // The user can disable OS notifications; keep the in-app inbox.
          return;
        }
      }
      await prefs.setStringList(key,
          current.map((item) => item.id).take(200).toList());
    } finally {
      _busy = false;
    }
  }
}
