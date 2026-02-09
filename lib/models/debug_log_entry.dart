import 'package:logger/logger.dart';

/// Debug log entry model for circular buffer storage
class DebugLogEntry {
  final String id;
  final DateTime timestamp;
  final Level level;
  final String category;
  final String message;
  final String? stackTrace;
  final Map<String, dynamic>? metadata;

  DebugLogEntry({
    required this.id,
    required this.timestamp,
    required this.level,
    required this.category,
    required this.message,
    this.stackTrace,
    this.metadata,
  });

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'level': level.toString(),
    'category': category,
    'message': message,
    'stackTrace': stackTrace,
    'metadata': metadata,
  };

  /// Create from JSON
  factory DebugLogEntry.fromJson(Map<String, dynamic> json) {
    return DebugLogEntry(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      level: _parseLevel(json['level'] as String),
      category: json['category'] as String,
      message: json['message'] as String,
      stackTrace: json['stackTrace'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  static Level _parseLevel(String levelStr) {
    if (levelStr.contains('error')) return Level.error;
    if (levelStr.contains('warning')) return Level.warning;
    if (levelStr.contains('info')) return Level.info;
    if (levelStr.contains('debug')) return Level.debug;
    return Level.trace;
  }

  /// Get color for log level
  String get levelColor {
    switch (level) {
      case Level.error:
      case Level.fatal:
        return '#F44336';
      case Level.warning:
        return '#FF9800';
      case Level.info:
        return '#2196F3';
      case Level.debug:
        return '#4CAF50';
      default:
        return '#9E9E9E';
    }
  }

  /// Get icon for log level
  String get levelIcon {
    switch (level) {
      case Level.error:
      case Level.fatal:
        return 'error';
      case Level.warning:
        return 'warning';
      case Level.info:
        return 'info';
      case Level.debug:
        return 'bug_report';
      default:
        return 'circle';
    }
  }
}
