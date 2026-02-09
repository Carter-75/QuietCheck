import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../models/user_settings.dart';
import '../../services/data_service.dart';
import '../../services/sound_system_service.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/volume_control_widget.dart';

/// Sound Pack Selection Screen
/// Allows users to preview and select notification sound packs
class SoundPackSelection extends StatefulWidget {
  const SoundPackSelection({super.key});

  @override
  State<SoundPackSelection> createState() => _SoundPackSelectionState();
}

class _SoundPackSelectionState extends State<SoundPackSelection> {
  final _dataService = DataService.instance;
  final _soundSystem = SoundSystemService.instance;

  String _selectedPack = 'default';
  double _volume = 70.0;
  bool _isLoading = true;
  String? _previewingSound;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _soundSystem.initialize();
  }

  @override
  void dispose() {
    _soundSystem.stopSound();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final settings = await _dataService.getUserSettings();
      if (settings != null) {
        setState(() {
          _selectedPack = settings.selectedSoundPack;
          _volume = settings.sensitivityValue;
        });
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    try {
      final settings = await _dataService.getUserSettings();
      if (settings != null) {
        final updatedSettings = UserSettings(
          id: settings.id,
          userId: settings.userId,
          selectedSoundPack: _selectedPack,
          quietHoursStart: settings.quietHoursStart,
          quietHoursEnd: settings.quietHoursEnd,
          vibrationEnabled: settings.vibrationEnabled,
          createdAt: settings.createdAt,
          updatedAt: DateTime.now(),
        );
        await _dataService.updateUserSettings(updatedSettings);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sound settings saved'),
              backgroundColor: Theme.of(context).colorScheme.tertiary,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save settings: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _previewSound(String soundType) async {
    setState(() => _previewingSound = soundType);
    await _soundSystem.playNotificationSound(soundType);
    await Future.delayed(Duration(seconds: 2));
    if (mounted) {
      setState(() => _previewingSound = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: CustomIconWidget(
            iconName: 'close',
            color: theme.colorScheme.onSurface,
            size: 24,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Sound Pack Selection'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: theme.colorScheme.primary,
                  ),
                )
              : Column(
                  children: [
                    // Header description
                    Text(
                      'Choose your notification sound',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 3.h),

                    // Sound pack grid
                    Expanded(
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 3.w,
                          mainAxisSpacing: 2.h,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: 0,
                        itemBuilder: (context, index) {
                          return SizedBox.shrink();
                        },
                      ),
                    ),

                    SizedBox(height: 2.h),

                    // Volume control
                    VolumeControlWidget(
                      volumeLevel: _volume,
                      onVolumeChanged: (value) {
                        setState(() => _volume = value);
                      },
                      isPlaying: _previewingSound != null,
                    ),

                    SizedBox(height: 2.h),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          Navigator.pop(context);
                        },
                        child: Text('Save Selection'),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}