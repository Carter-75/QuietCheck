import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Volume Control Widget
///
/// Provides volume adjustment interface with:
/// - Volume slider with real-time feedback
/// - Volume level indicator
/// - Mute/unmute button
/// - Visual feedback during playback
class VolumeControlWidget extends StatelessWidget {
  final double volumeLevel;
  final ValueChanged<double> onVolumeChanged;
  final bool isPlaying;

  const VolumeControlWidget({
    super.key,
    required this.volumeLevel,
    required this.onVolumeChanged,
    required this.isPlaying,
  });

  String get _volumeIcon {
    if (volumeLevel == 0) return 'volume_off';
    if (volumeLevel < 0.3) return 'volume_mute';
    if (volumeLevel < 0.7) return 'volume_down';
    return 'volume_up';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Volume',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${(volumeLevel * 100).round()}%',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          SizedBox(height: 1.h),

          // Volume slider with icons
          Row(
            children: [
              // Volume icon
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onVolumeChanged(volumeLevel == 0 ? 0.7 : 0);
                },
                child: Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: CustomIconWidget(
                    iconName: _volumeIcon,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                ),
              ),

              SizedBox(width: 3.w),

              // Slider
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 4,
                    thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8),
                    overlayShape: RoundSliderOverlayShape(overlayRadius: 16),
                    activeTrackColor: theme.colorScheme.primary,
                    inactiveTrackColor: theme.colorScheme.outline,
                    thumbColor: theme.colorScheme.primary,
                    overlayColor: theme.colorScheme.primary.withValues(
                      alpha: 0.2,
                    ),
                  ),
                  child: Slider(
                    value: volumeLevel,
                    min: 0.0,
                    max: 1.0,
                    divisions: 20,
                    onChanged: (value) {
                      HapticFeedback.selectionClick();
                      onVolumeChanged(value);
                    },
                  ),
                ),
              ),
            ],
          ),

          // Playback indicator
          if (isPlaying)
            Padding(
              padding: EdgeInsets.only(top: 1.h),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'graphic_eq',
                    color: theme.colorScheme.primary,
                    size: 16,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    'Playing preview...',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
