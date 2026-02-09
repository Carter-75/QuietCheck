import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../core/build_config.dart';
import '../../../models/debug_log_entry.dart';
import '../../../services/debug_logging_service.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Debug Console Screen - Development builds only
/// Real-time system monitoring and diagnostic capabilities
class DebugConsoleScreen extends StatefulWidget {
  const DebugConsoleScreen({super.key});

  @override
  State<DebugConsoleScreen> createState() => _DebugConsoleScreenState();
}

class _DebugConsoleScreenState extends State<DebugConsoleScreen> {
  final _loggingService = DebugLoggingService.instance;
  final _buildConfig = BuildConfig.instance;

  List<DebugLogEntry> _filteredLogs = [];
  final Set<Level> _selectedLevels = {Level.error, Level.warning, Level.info, Level.debug};
  String _searchQuery = '';
  String? _expandedLogId;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  void _loadLogs() {
    setState(() {
      _filteredLogs = _loggingService.getAllLogs().where((log) {
        final matchesLevel = _selectedLevels.contains(log.level);
        final matchesSearch = _searchQuery.isEmpty ||
            log.message.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            log.category.toLowerCase().contains(_searchQuery.toLowerCase());
        return matchesLevel && matchesSearch;
      }).toList().reversed.toList();
    });
  }

  void _toggleLevel(Level level) {
    setState(() {
      if (_selectedLevels.contains(level)) {
        _selectedLevels.remove(level);
      } else {
        _selectedLevels.add(level);
      }
      _loadLogs();
    });
  }

  Future<void> _clearLogs() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear Logs'),
        content: Text('Are you sure you want to clear all logs?'),
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
      await _loggingService.clearLogs();
      _loadLogs();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logs cleared')),
        );
      }
    }
  }

  Future<void> _exportLogs() async {
    try {
      final encrypted = await _loggingService.exportLogs();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logs exported (${encrypted.length} bytes)'),
            action: SnackBarAction(
              label: 'Copy',
              onPressed: () {
                // Copy to clipboard functionality would go here
              },
            ),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stats = _loggingService.getLogStatistics();

    if (!_buildConfig.enableDebugFeatures) {
      return Scaffold(
        appBar: AppBar(title: Text('Debug Console')),
        body: Center(
          child: Text('Debug features disabled in release builds'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: Text('Debug Console', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: CustomIconWidget(
            iconName: 'close',
            color: Colors.white,
            size: 24,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: CustomIconWidget(
              iconName: 'refresh',
              color: Colors.white,
              size: 24,
            ),
            onPressed: _loadLogs,
          ),
          IconButton(
            icon: CustomIconWidget(
              iconName: 'download',
              color: Colors.white,
              size: 24,
            ),
            onPressed: _exportLogs,
          ),
          IconButton(
            icon: CustomIconWidget(
              iconName: 'delete',
              color: Colors.white,
              size: 24,
            ),
            onPressed: _clearLogs,
          ),
        ],
      ),
      body: Column(
        children: [
          // System status indicators
          Container(
            padding: EdgeInsets.all(3.w),
            color: Colors.grey[900],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatusChip('Total', stats['total'].toString(), Colors.blue),
                _buildStatusChip('Errors', stats['errors'].toString(), Colors.red),
                _buildStatusChip('Warnings', stats['warnings'].toString(), Colors.orange),
                _buildStatusChip('Info', stats['info'].toString(), Colors.green),
              ],
            ),
          ),

          // Filter chips
          Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
            color: Colors.grey[850],
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Error', Level.error, Colors.red),
                  SizedBox(width: 2.w),
                  _buildFilterChip('Warning', Level.warning, Colors.orange),
                  SizedBox(width: 2.w),
                  _buildFilterChip('Info', Level.info, Colors.blue),
                  SizedBox(width: 2.w),
                  _buildFilterChip('Debug', Level.debug, Colors.green),
                ],
              ),
            ),
          ),

          // Search bar
          Container(
            padding: EdgeInsets.all(3.w),
            color: Colors.grey[850],
            child: TextField(
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search logs...',
                hintStyle: TextStyle(color: Colors.grey),
                prefixIcon: Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[800],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _loadLogs();
                });
              },
            ),
          ),

          // Log entries
          Expanded(
            child: _filteredLogs.isEmpty
                ? Center(
                    child: Text(
                      'No logs found',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredLogs.length,
                    itemBuilder: (context, index) {
                      final log = _filteredLogs[index];
                      final isExpanded = _expandedLogId == log.id;

                      return InkWell(
                        onTap: () {
                          setState(() {
                            _expandedLogId = isExpanded ? null : log.id;
                          });
                        },
                        child: Container(
                          margin: EdgeInsets.symmetric(
                            horizontal: 2.w,
                            vertical: 0.5.h,
                          ),
                          padding: EdgeInsets.all(2.w),
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Color(int.parse(
                                log.levelColor.replaceFirst('#', '0xFF'),
                              )),
                              width: 2,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CustomIconWidget(
                                    iconName: log.levelIcon,
                                    color: Color(int.parse(
                                      log.levelColor.replaceFirst('#', '0xFF'),
                                    )),
                                    size: 16,
                                  ),
                                  SizedBox(width: 2.w),
                                  Text(
                                    log.timestamp.toString().split('.')[0],
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 10.sp,
                                    ),
                                  ),
                                  SizedBox(width: 2.w),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 2.w,
                                      vertical: 0.5.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[800],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      log.category,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10.sp,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 1.h),
                              Text(
                                log.message,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.sp,
                                ),
                                maxLines: isExpanded ? null : 2,
                                overflow: isExpanded
                                    ? TextOverflow.visible
                                    : TextOverflow.ellipsis,
                              ),
                              if (isExpanded && log.stackTrace != null) ...[
                                SizedBox(height: 1.h),
                                Container(
                                  padding: EdgeInsets.all(2.w),
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    log.stackTrace!,
                                    style: TextStyle(
                                      color: Colors.red[300],
                                      fontSize: 10.sp,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                              ],
                              if (isExpanded && log.metadata != null) ...[
                                SizedBox(height: 1.h),
                                Container(
                                  padding: EdgeInsets.all(2.w),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[800],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    log.metadata.toString(),
                                    style: TextStyle(
                                      color: Colors.grey[300],
                                      fontSize: 10.sp,
                                    ),
                                  ),
                                ),
                              ],
                            ],
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

  Widget _buildStatusChip(String label, String value, Color color) {
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

  Widget _buildFilterChip(String label, Level level, Color color) {
    final isSelected = _selectedLevels.contains(level);
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _toggleLevel(level),
      backgroundColor: Colors.grey[800],
      selectedColor: color.withValues(alpha: 0.3),
      labelStyle: TextStyle(
        color: isSelected ? color : Colors.grey,
      ),
      checkmarkColor: color,
    );
  }
}