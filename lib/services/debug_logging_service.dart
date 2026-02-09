import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/build_config.dart';
import '../models/debug_log_entry.dart';
import './encryption_service.dart';

/// Debug logging service with encrypted circular buffer
/// Stores logs locally for development/staging builds only
class DebugLoggingService {
  static DebugLoggingService? _instance;
  static DebugLoggingService get instance =>
      _instance ??= DebugLoggingService._();

  DebugLoggingService._();

  final _buildConfig = BuildConfig.instance;
  final _encryption = EncryptionService.instance;
  final List<DebugLogEntry> _logBuffer = [];
  static const int _maxBufferSize = 500;
  static const String _storageKey = 'debug_logs_encrypted';

  late Logger _logger;
  bool _isInitialized = false;

  /// Initialize logging service
  Future<void> initialize() async {
    if (_isInitialized) return;

    _logger = Logger(
      printer: PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        printTime: true,
      ),
      level: _buildConfig.enableVerboseLogging ? Level.debug : Level.info,
    );

    // Load existing logs from storage
    await _loadLogsFromStorage();

    _isInitialized = true;
    debugPrint('✅ Debug logging service initialized');
  }

  /// Log debug message
  void debug(
    String message, {
    String category = 'general',
    Map<String, dynamic>? metadata,
  }) {
    if (!_buildConfig.enableDebugFeatures) return;
    _log(Level.debug, category, message, metadata: metadata);
  }

  /// Log info message
  void info(
    String message, {
    String category = 'general',
    Map<String, dynamic>? metadata,
  }) {
    _log(Level.info, category, message, metadata: metadata);
  }

  /// Log warning message
  void warning(
    String message, {
    String category = 'general',
    Map<String, dynamic>? metadata,
  }) {
    _log(Level.warning, category, message, metadata: metadata);
  }

  /// Log error message
  void error(
    String message, {
    String category = 'general',
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  }) {
    _log(
      Level.error,
      category,
      message,
      error: error,
      stackTrace: stackTrace,
      metadata: metadata,
    );
  }

  /// Internal log method
  void _log(
    Level level,
    String category,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  }) {
    if (!_isInitialized) return;

    // Log to console in debug builds
    if (_buildConfig.enableVerboseLogging) {
      switch (level) {
        case Level.debug:
          _logger.d(message);
          break;
        case Level.info:
          _logger.i(message);
          break;
        case Level.warning:
          _logger.w(message);
          break;
        case Level.error:
        case Level.fatal:
          _logger.e(message, error: error, stackTrace: stackTrace);
          break;
        default:
          _logger.t(message);
      }
    }

    // Add to circular buffer
    final logEntry = DebugLogEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      level: level,
      category: category,
      message: message,
      stackTrace: stackTrace?.toString(),
      metadata: metadata,
    );

    _logBuffer.add(logEntry);

    // Maintain buffer size limit (circular buffer)
    if (_logBuffer.length > _maxBufferSize) {
      _logBuffer.removeAt(0);
    }

    // Persist to storage
    _saveLogsToStorage();
  }

  /// Get all logs
  List<DebugLogEntry> getAllLogs() => List.unmodifiable(_logBuffer);

  /// Get logs by category
  List<DebugLogEntry> getLogsByCategory(String category) {
    return _logBuffer.where((log) => log.category == category).toList();
  }

  /// Get logs by level
  List<DebugLogEntry> getLogsByLevel(Level level) {
    return _logBuffer.where((log) => log.level == level).toList();
  }

  /// Clear all logs
  Future<void> clearLogs() async {
    _logBuffer.clear();
    await _saveLogsToStorage();
  }

  /// Export logs as encrypted JSON
  Future<String> exportLogs() async {
    final logsJson = _logBuffer.map((log) => log.toJson()).toList();
    final jsonString = jsonEncode(logsJson);
    return _encryption.encrypt(jsonString);
  }

  /// Save logs to encrypted storage
  Future<void> _saveLogsToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logsJson = _logBuffer.map((log) => log.toJson()).toList();
      final jsonString = jsonEncode(logsJson);
      final encrypted = _encryption.encrypt(jsonString);
      await prefs.setString(_storageKey, encrypted);
    } catch (e) {
      debugPrint('Failed to save logs to storage: $e');
    }
  }

  /// Load logs from encrypted storage
  Future<void> _loadLogsFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encrypted = prefs.getString(_storageKey);
      if (encrypted != null && encrypted.isNotEmpty) {
        final decrypted = _encryption.decrypt(encrypted);
        final List<dynamic> logsJson = jsonDecode(decrypted);
        _logBuffer.clear();
        _logBuffer.addAll(logsJson.map((json) => DebugLogEntry.fromJson(json)));
      }
    } catch (e) {
      debugPrint('Failed to load logs from storage: $e');
    }
  }

  /// Get log statistics
  Map<String, int> getLogStatistics() {
    return {
      'total': _logBuffer.length,
      'errors': _logBuffer
          .where((log) => log.level == Level.error || log.level == Level.fatal)
          .length,
      'warnings': _logBuffer.where((log) => log.level == Level.warning).length,
      'info': _logBuffer.where((log) => log.level == Level.info).length,
      'debug': _logBuffer.where((log) => log.level == Level.debug).length,
    };
  }
}
