/// Crash report model for local crash capture and diagnostics
class CrashReport {
  final String id;
  final DateTime timestamp;
  final String errorType;
  final String errorMessage;
  final String stackTrace;
  final Map<String, dynamic> deviceInfo;
  final Map<String, dynamic> appState;
  final bool isResolved;
  final int occurrenceCount;

  CrashReport({
    required this.id,
    required this.timestamp,
    required this.errorType,
    required this.errorMessage,
    required this.stackTrace,
    required this.deviceInfo,
    required this.appState,
    this.isResolved = false,
    this.occurrenceCount = 1,
  });

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'errorType': errorType,
    'errorMessage': errorMessage,
    'stackTrace': stackTrace,
    'deviceInfo': deviceInfo,
    'appState': appState,
    'isResolved': isResolved,
    'occurrenceCount': occurrenceCount,
  };

  /// Create from JSON
  factory CrashReport.fromJson(Map<String, dynamic> json) {
    return CrashReport(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      errorType: json['errorType'] as String,
      errorMessage: json['errorMessage'] as String,
      stackTrace: json['stackTrace'] as String,
      deviceInfo: json['deviceInfo'] as Map<String, dynamic>,
      appState: json['appState'] as Map<String, dynamic>,
      isResolved: json['isResolved'] as bool? ?? false,
      occurrenceCount: json['occurrenceCount'] as int? ?? 1,
    );
  }

  /// Create copy with updated fields
  CrashReport copyWith({bool? isResolved, int? occurrenceCount}) {
    return CrashReport(
      id: id,
      timestamp: timestamp,
      errorType: errorType,
      errorMessage: errorMessage,
      stackTrace: stackTrace,
      deviceInfo: deviceInfo,
      appState: appState,
      isResolved: isResolved ?? this.isResolved,
      occurrenceCount: occurrenceCount ?? this.occurrenceCount,
    );
  }

  /// Get severity level based on error type
  String get severity {
    if (errorType.contains('Fatal') || errorType.contains('Critical')) {
      return 'critical';
    }
    if (errorType.contains('Exception')) return 'high';
    if (errorType.contains('Error')) return 'medium';
    return 'low';
  }
}
