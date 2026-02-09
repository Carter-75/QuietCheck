import 'package:flutter/foundation.dart';

/// Build configuration service for detecting debug vs release builds
/// Enables conditional debug features and logging based on build mode
class BuildConfig {
  static BuildConfig? _instance;
  static BuildConfig get instance => _instance ??= BuildConfig._();

  BuildConfig._();

  /// Returns true if running in debug mode
  bool get isDebugBuild => kDebugMode;

  /// Returns true if running in release mode
  bool get isReleaseBuild => kReleaseMode;

  /// Returns true if running in profile mode
  bool get isProfileBuild => kProfileMode;

  /// Returns build mode as string
  String get buildMode {
    if (kDebugMode) return 'debug';
    if (kReleaseMode) return 'release';
    if (kProfileMode) return 'profile';
    return 'unknown';
  }

  /// Returns true if debug features should be enabled
  bool get enableDebugFeatures => kDebugMode || kProfileMode;

  /// Returns true if verbose logging should be enabled
  bool get enableVerboseLogging => kDebugMode;

  /// Returns true if crash diagnostics should be enabled
  bool get enableCrashDiagnostics => kDebugMode || kProfileMode;
}
