/// Web stub for Firebase Crashlytics (not supported on web)
/// This file prevents compilation errors when building for web
library;

class FirebaseCrashlytics {
  static FirebaseCrashlytics get instance => FirebaseCrashlytics._();
  FirebaseCrashlytics._();

  Future<void> setCrashlyticsCollectionEnabled(bool enabled) async {}
  Future<void> recordFlutterFatalError(dynamic details) async {}
  Future<void> recordError(
    dynamic error,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  }) async {}
  Future<void> setUserIdentifier(String userId) async {}
  Future<void> setCustomKey(String key, dynamic value) async {}
}
