import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/build_config.dart';
import '../models/crash_report.dart';
import './debug_logging_service.dart';
import './encryption_service.dart';
import './supabase_analytics_service.dart';

/// Crash handler service for local crash capture and diagnostics
/// Captures crashes in debug/staging builds for analysis
class CrashHandlerService {
  static CrashHandlerService? _instance;
  static CrashHandlerService get instance =>
      _instance ??= CrashHandlerService._();

  CrashHandlerService._();

  final _buildConfig = BuildConfig.instance;
  final _encryption = EncryptionService.instance;
  final _logging = DebugLoggingService.instance;
  final List<CrashReport> _crashReports = [];
  static const String _storageKey = 'crash_reports_encrypted';
  static const int _maxReports = 50;

  bool _isInitialized = false;

  /// Initialize crash handler
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Load existing crash reports
    await _loadCrashReports();

    // Set up Flutter error handler
    if (_buildConfig.enableCrashDiagnostics) {
      FlutterError.onError = (FlutterErrorDetails details) {
        _handleFlutterError(details);
      };

      // Set up platform dispatcher error handler
      PlatformDispatcher.instance.onError = (error, stack) {
        _handlePlatformError(error, stack);
        return true;
      };
    }

    _isInitialized = true;
    debugPrint('✅ Crash handler service initialized');
  }

  /// Handle Flutter framework errors
  void _handleFlutterError(FlutterErrorDetails details) {
    // Log to debug logging service
    _logging.error(
      'Flutter Error: ${details.exception}',
      category: 'crash',
      error: details.exception,
      stackTrace: details.stack,
    );

    // Create crash report
    _createCrashReport(
      errorType: 'FlutterError',
      errorMessage: details.exception.toString(),
      stackTrace: details.stack?.toString() ?? '',
    );

    // Send to Supabase Analytics
    SupabaseAnalyticsService.instance.logCrash(
      errorMessage: details.exception.toString(),
      stackTrace: details.stack?.toString() ?? '',
      errorType: 'FlutterError',
      severity: 'fatal',
    );

    // Print to console in debug mode
    if (_buildConfig.isDebugBuild) {
      FlutterError.presentError(details);
    }
  }

  /// Handle platform errors
  void _handlePlatformError(Object error, StackTrace stack) {
    _logging.error(
      'Platform Error: $error',
      category: 'crash',
      error: error,
      stackTrace: stack,
    );

    _createCrashReport(
      errorType: 'PlatformError',
      errorMessage: error.toString(),
      stackTrace: stack.toString(),
    );

    // Send to Supabase Analytics
    SupabaseAnalyticsService.instance.logCrash(
      errorMessage: error.toString(),
      stackTrace: stack.toString(),
      errorType: 'PlatformError',
      severity: 'fatal',
    );
  }

  /// Create and store crash report
  Future<void> _createCrashReport({
    required String errorType,
    required String errorMessage,
    required String stackTrace,
  }) async {
    try {
      final deviceInfo = await _collectDeviceInfo();
      final appState = _collectAppState();

      // Check for duplicate crash
      final existingCrash = _crashReports.firstWhere(
        (report) =>
            report.errorType == errorType &&
            report.errorMessage == errorMessage,
        orElse: () => CrashReport(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          timestamp: DateTime.now(),
          errorType: errorType,
          errorMessage: errorMessage,
          stackTrace: stackTrace,
          deviceInfo: deviceInfo,
          appState: appState,
        ),
      );

      if (_crashReports.contains(existingCrash)) {
        // Increment occurrence count
        final index = _crashReports.indexOf(existingCrash);
        _crashReports[index] = existingCrash.copyWith(
          occurrenceCount: existingCrash.occurrenceCount + 1,
        );
      } else {
        // Add new crash report
        _crashReports.add(existingCrash);
      }

      // Maintain max reports limit
      if (_crashReports.length > _maxReports) {
        _crashReports.removeAt(0);
      }

      // Save to storage
      await _saveCrashReports();
    } catch (e) {
      debugPrint('Failed to create crash report: $e');
    }
  }

  /// Collect device information
  Future<Map<String, dynamic>> _collectDeviceInfo() async {
    return {
      'platform': Platform.operatingSystem,
      'platformVersion': Platform.operatingSystemVersion,
      'buildMode': _buildConfig.buildMode,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Collect app state information
  Map<String, dynamic> _collectAppState() {
    return {
      'buildMode': _buildConfig.buildMode,
      'debugMode': _buildConfig.isDebugBuild,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Get all crash reports
  List<CrashReport> getAllCrashReports() => List.unmodifiable(_crashReports);

  /// Get unresolved crash reports
  List<CrashReport> getUnresolvedCrashReports() {
    return _crashReports.where((report) => !report.isResolved).toList();
  }

  /// Mark crash as resolved
  Future<void> markCrashAsResolved(String crashId) async {
    final index = _crashReports.indexWhere((report) => report.id == crashId);
    if (index != -1) {
      _crashReports[index] = _crashReports[index].copyWith(isResolved: true);
      await _saveCrashReports();
    }
  }

  /// Clear all crash reports
  Future<void> clearCrashReports() async {
    _crashReports.clear();
    await _saveCrashReports();
  }

  /// Export crash reports as encrypted JSON
  Future<String> exportCrashReports() async {
    final reportsJson = _crashReports.map((report) => report.toJson()).toList();
    final jsonString = jsonEncode(reportsJson);
    return _encryption.encrypt(jsonString);
  }

  /// Save crash reports to encrypted storage
  Future<void> _saveCrashReports() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reportsJson = _crashReports
          .map((report) => report.toJson())
          .toList();
      final jsonString = jsonEncode(reportsJson);
      final encrypted = _encryption.encrypt(jsonString);
      await prefs.setString(_storageKey, encrypted);
    } catch (e) {
      debugPrint('Failed to save crash reports: $e');
    }
  }

  /// Load crash reports from encrypted storage
  Future<void> _loadCrashReports() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encrypted = prefs.getString(_storageKey);
      if (encrypted != null && encrypted.isNotEmpty) {
        final decrypted = _encryption.decrypt(encrypted);
        final List<dynamic> reportsJson = jsonDecode(decrypted);
        _crashReports.clear();
        _crashReports.addAll(
          reportsJson.map((json) => CrashReport.fromJson(json)),
        );
      }
    } catch (e) {
      debugPrint('Failed to load crash reports: $e');
    }
  }

  /// Get crash statistics
  Map<String, dynamic> getCrashStatistics() {
    return {
      'total': _crashReports.length,
      'unresolved': _crashReports.where((r) => !r.isResolved).length,
      'critical': _crashReports.where((r) => r.severity == 'critical').length,
      'high': _crashReports.where((r) => r.severity == 'high').length,
      'medium': _crashReports.where((r) => r.severity == 'medium').length,
    };
  }
}
