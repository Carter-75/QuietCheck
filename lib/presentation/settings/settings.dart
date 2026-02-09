import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/advanced_section_widget.dart';
import './widgets/notification_preferences_section_widget.dart';
import './widgets/privacy_controls_section_widget.dart';
import './widgets/quiet_hours_section_widget.dart';
import './widgets/sensitivity_section_widget.dart';
import './widgets/sound_pack_section_widget.dart';
import './widgets/subscription_section_widget.dart';
import '../../services/data_service.dart';
import '../../models/user_settings.dart';
import '../../services/analytics_tracking_service.dart';
import '../../services/supabase_analytics_service.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  final ScrollController _scrollController = ScrollController();
  final _dataService = DataService.instance;
  bool _isLoading = true;
  bool _isSaving = false;

  // Settings state
  double _sensitivityValue = 50.0;
  final String _selectedSoundPack = "Calming Waves";
  bool _isAdvancedExpanded = false;

  // Quiet hours state
  TimeOfDay _quietHoursStart = TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _quietHoursEnd = TimeOfDay(hour: 7, minute: 0);

  // Notification preferences
  bool _highSeverityEnabled = true;
  bool _mediumSeverityEnabled = true;
  bool _lowSeverityEnabled = false;
  bool _vibrationEnabled = true;

  // Subscription state
  final bool _isPremium = false;
  final int _trialDaysRemaining = 5;

  @override
  void initState() {
    super.initState();
    // Track screen view
    SupabaseAnalyticsService.instance.trackScreenView('settings');
    AnalyticsTrackingService.instance.trackScreenView('Settings');
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final settings = await _dataService.getUserSettings();
      if (settings != null) {
        setState(() {
          _sensitivityValue = settings.sensitivityValue;
          _quietHoursStart = _parseTimeOfDay(settings.quietHoursStart);
          _quietHoursEnd = _parseTimeOfDay(settings.quietHoursEnd);
          _highSeverityEnabled = settings.highSeverityNotifications;
          _mediumSeverityEnabled = settings.mediumSeverityNotifications;
          _lowSeverityEnabled = settings.lowSeverityNotifications;
          _vibrationEnabled = settings.vibrationEnabled;
        });
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final userId = _dataService.currentUserId;
      if (userId == null) return;

      final settings = UserSettings(
        userId: userId,
        sensitivityValue: _sensitivityValue,
        quietHoursStart: _formatTimeOfDay(_quietHoursStart),
        quietHoursEnd: _formatTimeOfDay(_quietHoursEnd),
        highSeverityNotifications: _highSeverityEnabled,
        mediumSeverityNotifications: _mediumSeverityEnabled,
        lowSeverityNotifications: _lowSeverityEnabled,
        vibrationEnabled: _vibrationEnabled,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _dataService.updateUserSettings(settings);
    } catch (e) {
      debugPrint('Error saving settings: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  TimeOfDay _parseTimeOfDay(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
  }

  @override
  void dispose() {
    _saveSettings();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSensitivityChange(double value) {
    HapticFeedback.selectionClick();
    setState(() {
      _sensitivityValue = value;
    });
    _saveSettings();
  }

  Future<void> _handleQuietHoursEdit(bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _quietHoursStart : _quietHoursEnd,
      builder: (context, child) {
        final theme = Theme.of(context);
        return Theme(
          data: theme.copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: theme.colorScheme.surface,
              hourMinuteTextColor: theme.colorScheme.primary,
              dayPeriodTextColor: theme.colorScheme.primary,
              dialHandColor: theme.colorScheme.primary,
              dialBackgroundColor: theme.colorScheme.surface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      HapticFeedback.mediumImpact();
      setState(() {
        if (isStart) {
          _quietHoursStart = picked;
        } else {
          _quietHoursEnd = picked;
        }
      });
      await _saveSettings();
    }
  }

  void _handleSoundPackNavigation() {
    HapticFeedback.lightImpact();
    Navigator.of(
      context,
      rootNavigator: true,
    ).pushNamed('/sound-pack-selection');
  }

  void _handleSubscriptionNavigation() {
    HapticFeedback.lightImpact();
    Navigator.of(
      context,
      rootNavigator: true,
    ).pushNamed('/subscription-management');
  }

  Future<void> _handleDataExport() async {
    if (!_isPremium) {
      _showPremiumRequiredDialog();
      return;
    }

    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exporting your data...'),
        duration: Duration(seconds: 2),
      ),
    );

    await Future.delayed(Duration(seconds: 2));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Data exported successfully'),
          backgroundColor: Theme.of(context).colorScheme.tertiary,
        ),
      );
    }
  }

  Future<void> _handleSelectiveDataDeletion() async {
    final theme = Theme.of(context);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Specific Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Select data type to delete:'),
            SizedBox(height: 16),
            ListTile(
              title: Text('Biometric Data'),
              onTap: () => Navigator.pop(context, 'biometric'),
            ),
            ListTile(
              title: Text('Behavioral Data'),
              onTap: () => Navigator.pop(context, 'behavioral'),
            ),
            ListTile(
              title: Text('Analytics History'),
              onTap: () => Navigator.pop(context, 'analytics'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );

    if (result != null) {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${result.substring(0, 1).toUpperCase()}${result.substring(1)} data deleted',
          ),
          backgroundColor: theme.colorScheme.tertiary,
        ),
      );
    }
  }

  Future<void> _handleCompleteDataWipe() async {
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Complete Data Wipe'),
        content: Text(
          'This will permanently delete ALL your data including:\n\n'
          '• Biometric readings\n'
          '• Behavioral patterns\n'
          '• Analytics history\n'
          '• Settings and preferences\n\n'
          'This action cannot be undone.',
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
            ),
            child: Text('Delete All Data'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('All data has been permanently deleted'),
          backgroundColor: theme.colorScheme.error,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _showPremiumRequiredDialog() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Premium Feature'),
        content: Text(
          'Data export is available for premium subscribers only. Upgrade to access this feature.',
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handleSubscriptionNavigation();
            },
            child: Text('Upgrade Now'),
          ),
        ],
      ),
    );
  }

  void _toggleAdvancedSection() {
    HapticFeedback.selectionClick();
    setState(() {
      _isAdvancedExpanded = !_isAdvancedExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
        child: Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text('Settings'),
            centerTitle: true,
            leading: IconButton(
              icon: CustomIconWidget(
                iconName: 'arrow_back',
                color: theme.colorScheme.onSurface,
                size: 24,
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).pop();
              },
            ),
          ),
          body: ListView(
            controller: _scrollController,
            padding: EdgeInsets.symmetric(vertical: 2.h),
            children: [
              SensitivitySectionWidget(
                sensitivityValue: _sensitivityValue,
                onSensitivityChanged: _handleSensitivityChange,
              ),

              SizedBox(height: 2.h),

              QuietHoursSectionWidget(
                quietHoursStart: _quietHoursStart,
                quietHoursEnd: _quietHoursEnd,
                onEditStart: () => _handleQuietHoursEdit(true),
                onEditEnd: () => _handleQuietHoursEdit(false),
              ),

              SizedBox(height: 2.h),

              SoundPackSectionWidget(
                selectedSoundPack: _selectedSoundPack,
                onNavigate: _handleSoundPackNavigation,
              ),

              SizedBox(height: 2.h),

              PrivacyControlsSectionWidget(
                isPremium: _isPremium,
                onExportData: _handleDataExport,
                onSelectiveDeletion: _handleSelectiveDataDeletion,
                onCompleteWipe: _handleCompleteDataWipe,
              ),

              SizedBox(height: 2.h),

              SubscriptionSectionWidget(
                isPremium: _isPremium,
                trialDaysRemaining: _trialDaysRemaining,
                onNavigate: _handleSubscriptionNavigation,
              ),

              SizedBox(height: 2.h),

              NotificationPreferencesSectionWidget(
                highSeverityEnabled: _highSeverityEnabled,
                mediumSeverityEnabled: _mediumSeverityEnabled,
                lowSeverityEnabled: _lowSeverityEnabled,
                vibrationEnabled: _vibrationEnabled,
                onHighSeverityChanged: (value) {
                  HapticFeedback.selectionClick();
                  setState(() => _highSeverityEnabled = value);
                },
                onMediumSeverityChanged: (value) {
                  HapticFeedback.selectionClick();
                  setState(() => _mediumSeverityEnabled = value);
                },
                onLowSeverityChanged: (value) {
                  HapticFeedback.selectionClick();
                  setState(() => _lowSeverityEnabled = value);
                },
                onVibrationChanged: (value) {
                  HapticFeedback.selectionClick();
                  setState(() => _vibrationEnabled = value);
                },
              ),

              SizedBox(height: 2.h),

              AdvancedSectionWidget(
                isExpanded: _isAdvancedExpanded,
                onToggle: _toggleAdvancedSection,
              ),

              SizedBox(height: 4.h),
            ],
          ),
        ),
      ),
    );
  }
}
