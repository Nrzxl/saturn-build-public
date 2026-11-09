import 'package:web/web.dart' as web;

/// True when the browser is presenting SATURN as an installed PWA window.
/// This has no effect on Android/iOS native builds.
bool isSaturnWebStandalone() =>
    web.window.matchMedia('(display-mode: standalone)').matches;

bool isSaturnWebOnline() => web.window.navigator.onLine;

/// Navigate to a fresh document URL rather than merely reloading a cached
/// document. This does not touch localStorage, IndexedDB or SharedPreferences.
void refreshSaturnWeb() {
  final current = Uri.base;
  final next = current.replace(queryParameters: {
    ...current.queryParameters,
    'saturn_refresh': DateTime.now().millisecondsSinceEpoch.toString(),
  });
  web.window.location.replace(next.toString());
}
