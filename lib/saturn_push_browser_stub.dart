class SaturnBrowserPush {
  static String support() => 'unsupported';
  static Future<String> permission() async => 'unsupported';
  static Future<String> subscribe(String key) async =>
      throw UnsupportedError('Web Push requires an installed PWA');
  static Future<String> unsubscribe() async => '';
}
