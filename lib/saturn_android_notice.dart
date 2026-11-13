// Native Android notifications, never compiled into the Web implementation.
export 'saturn_android_notice_stub.dart'
    if (dart.library.io) 'saturn_android_notice_io.dart';
