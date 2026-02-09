import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../core/build_config.dart';
import '../../../models/crash_report.dart';
import '../../../services/crash_handler_service.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Crash Report Viewer Screen - Development builds only
/// Analyze application failures through comprehensive crash data
class CrashReportViewerScreen extends StatefulWidget {
  const CrashReportViewerScreen({super.key});

  @override
  State<CrashReportViewerScreen> createState() =>
      _CrashReportViewerScreenState();
}

class _CrashReportViewerScreenState extends State<CrashReportViewerScreen> {
  final _crashHandler = CrashHandlerService.instance;
  final _buildConfig = BuildConfig.instance;

  List<CrashReport> _crashReports = [];
  String _filterSeverity = 'all';
  bool _showResolvedOnly = false;
  String? _expandedCrashId;

  @override
  void initState() {
    super.initState();
    _loadCrashReports();
  }

  void _loadCrashReports() {
    setState(() {
      _crashReports = _crashHandler.getAllCrashReports().where((crash) {
        final matchesSeverity =
            _filterSeverity == 'all' || crash.severity == _filterSeverity;
        final matchesResolved =
            !_showResolvedOnly || crash.isResolved;
        return matchesSeverity && matchesResolved;
      }).toList();
    });
  }

  Future<void> _clearCrashReports() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear Crash Reports'),
        content: Text('Are you sure you want to clear all crash reports?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text('Clear'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _crashHandler.clearCrashReports();
      _loadCrashReports();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Crash reports cleared')),
        );
      }
    }
  }

  Future<void> _exportCrashReports() async {
    try {
      final encrypted = await _crashHandler.exportCrashReports();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Crash reports exported (${encrypted.length} bytes)'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Future<void> _markAsResolved(String crashId) async {
    await _crashHandler.markCrashAsResolved(crashId);
    _loadCrashReports();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Crash marked as resolved')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stats = _crashHandler.getCrashStatistics();

    if (!_buildConfig.enableCrashDiagnostics) {
      return Scaffold(
        appBar: AppBar(title: Text('Crash Reports')),
        body: Center(
          child: Text('Crash diagnostics disabled in release builds'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Crash Reports'),
        leading: IconButton(
          icon: CustomIconWidget(
            iconName: 'arrow_back',
            color: theme.colorScheme.onSurface,
            size: 24,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: CustomIconWidget(
              iconName: 'refresh',
              color: theme.colorScheme.onSurface,
              size: 24,
            ),
            onPressed: _loadCrashReports,
          ),
          IconButton(
            icon: CustomIconWidget(
              iconName: 'download',
              color: theme.colorScheme.onSurface,
              size: 24,
            ),
            onPressed: _exportCrashReports,
          ),
          IconButton(
            icon: CustomIconWidget(
              iconName: 'delete',
              color: theme.colorScheme.onSurface,
              size: 24,
            ),
            onPressed: _clearCrashReports,
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistics header
          Container(
            padding: EdgeInsets.all(4.w),
            color: theme.colorScheme.surfaceContainerHighest,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatChip('Total', stats['total'].toString(), theme.colorScheme.primary),
                _buildStatChip('Unresolved', stats['unresolved'].toString(), theme.colorScheme.error),
                _buildStatChip('Critical', stats['critical'].toString(), Colors.red),
                _buildStatChip('High', stats['high'].toString(), Colors.orange),
              ],
            ),
          ),

          // Filter controls
          Container(
            padding: EdgeInsets.all(3.w),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _filterSeverity,
                    decoration: InputDecoration(
                      labelText: 'Severity',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(value: 'all', child: Text('All')),
                      DropdownMenuItem(value: 'critical', child: Text('Critical')),
                      DropdownMenuItem(value: 'high', child: Text('High')),
                      DropdownMenuItem(value: 'medium', child: Text('Medium')),
                      DropdownMenuItem(value: 'low', child: Text('Low')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _filterSeverity = value!;
                        _loadCrashReports();
                      });
                    },
                  ),
                ),
                SizedBox(width: 3.w),
                FilterChip(
                  label: Text('Resolved'),
                  selected: _showResolvedOnly,
                  onSelected: (value) {
                    setState(() {
                      _showResolvedOnly = value;
                      _loadCrashReports();
                    });
                  },
                ),
              ],
            ),
          ),

          // Crash reports list
          Expanded(
            child: _crashReports.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomIconWidget(
                          iconName: 'check_circle',
                          color: theme.colorScheme.tertiary,
                          size: 64,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'No crash reports found',
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(3.w),
                    itemCount: _crashReports.length,
                    itemBuilder: (context, index) {
                      final crash = _crashReports[index];
                      final isExpanded = _expandedCrashId == crash.id;

                      return Card(
                        margin: EdgeInsets.only(bottom: 2.h),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _expandedCrashId = isExpanded ? null : crash.id;
                            });
                          },
                          child: Padding(
                            padding: EdgeInsets.all(3.w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 2.w,
                                        vertical: 0.5.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getSeverityColor(crash.severity),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        crash.severity.toUpperCase(),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 2.w),
                                    if (crash.isResolved)
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 2.w,
                                          vertical: 0.5.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.tertiary,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'RESOLVED',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10.sp,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    Spacer(),
                                    Text(
                                      '${crash.occurrenceCount}x',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.error,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 1.h),
                                Text(
                                  crash.errorType,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 0.5.h),
                                Text(
                                  crash.errorMessage,
                                  style: theme.textTheme.bodyMedium,
                                  maxLines: isExpanded ? null : 2,
                                  overflow: isExpanded
                                      ? TextOverflow.visible
                                      : TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 1.h),
                                Text(
                                  crash.timestamp.toString().split('.')[0],
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                if (isExpanded) ...[
                                  Divider(height: 3.h),
                                  Text(
                                    'Stack Trace:',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 1.h),
                                  Container(
                                    padding: EdgeInsets.all(2.w),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      crash.stackTrace,
                                      style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 10.sp,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    'Device Info:',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 1.h),
                                  ...crash.deviceInfo.entries.map(
                                    (entry) => Padding(
                                      padding: EdgeInsets.only(bottom: 0.5.h),
                                      child: Row(
                                        children: [
                                          Text(
                                            '${entry.key}: ',
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            entry.value.toString(),
                                            style: theme.textTheme.bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 2.h),
                                  if (!crash.isResolved)
                                    ElevatedButton(
                                      onPressed: () => _markAsResolved(crash.id),
                                      child: Text('Mark as Resolved'),
                                    ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey,
            fontSize: 10.sp,
          ),
        ),
      ],
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.yellow[700]!;
      case 'low':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}