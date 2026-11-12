import 'dart:js_interop';

@JS('saturnPushSupport')
external JSString _saturnPushSupport();

@JS('saturnPushPermission')
external JSPromise<JSString> _saturnPushPermission();

@JS('saturnPushSubscribe')
external JSPromise<JSString> _saturnPushSubscribe(JSString publicKey);

@JS('saturnPushUnsubscribe')
external JSPromise<JSString> _saturnPushUnsubscribe();

class SaturnBrowserPush {
  static String support() => _saturnPushSupport().toDart;

  static Future<String> permission() async =>
      (await _saturnPushPermission().toDart).toDart;

  static Future<String> subscribe(String key) async =>
      (await _saturnPushSubscribe(key.toJS).toDart).toDart;

  static Future<String> unsubscribe() async =>
      (await _saturnPushUnsubscribe().toDart).toDart;
}
