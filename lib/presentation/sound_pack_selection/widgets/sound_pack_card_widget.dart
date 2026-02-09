import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Sound Pack Card Widget
///
/// Displays individual sound pack with:
/// - Visual theme and icon
/// - Pack name and description
/// - Duration indicator
/// - Premium badge if applicable
/// - Selection checkmark
/// - Play/pause button
/// - Waveform visualization when playing
class SoundPackCardWidget extends StatelessWidget {
  final String packId;
  final String name;
  final String description;
  final String duration;
  final bool isPremium;
  final String icon;
  final Color color;
  final String semanticLabel;
  final bool isSelected;
  final bool isPlaying;
  final AnimationController waveformAnimation;
  final VoidCallback onSelect;
  final VoidCallback onPlayPause;

  const SoundPackCardWidget({
    super.key,
    required this.packId,
    required this.name,
    required this.description,
    required this.duration,
    required this.isPremium,
    required this.icon,
    required this.color,
    required this.semanticLabel,
    required this.isSelected,
    required this.isPlaying,
    required this.waveformAnimation,
    required this.onSelect,
    required this.onPlayPause,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onSelect,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon and badges
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Icon
                  Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: CustomIconWidget(
                      iconName: icon,
                      color: color,
                      size: 24,
                    ),
                  ),

                  // Badges
                  Row(
                    children: [
                      if (isPremium)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 2.w,
                            vertical: 0.5.h,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              CustomIconWidget(
                                iconName: 'lock',
                                color: theme.colorScheme.onPrimary,
                                size: 12,
                              ),
                              SizedBox(width: 1.w),
                              Text(
                                'PRO',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (isSelected && !isPremium)
                        Container(
                          padding: EdgeInsets.all(1.w),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: CustomIconWidget(
                            iconName: 'check',
                            color: theme.colorScheme.onPrimary,
                            size: 16,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(3.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 0.5.h),

                    // Description
                    Expanded(
                      child: Text(
                        description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    SizedBox(height: 1.h),

                    // Duration and play button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Duration
                        Row(
                          children: [
                            CustomIconWidget(
                              iconName: 'schedule',
                              color: theme.colorScheme.onSurfaceVariant,
                              size: 14,
                            ),
                            SizedBox(width: 1.w),
                            Text(
                              duration,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),

                        // Play/pause button
                        GestureDetector(
                          onTap: onPlayPause,
                          child: Container(
                            padding: EdgeInsets.all(1.5.w),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: CustomIconWidget(
                              iconName: isPlaying ? 'pause' : 'play_arrow',
                              color: color,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Waveform visualization (when playing)
            if (isPlaying)
              AnimatedBuilder(
                animation: waveformAnimation,
                builder: (context, child) {
                  return Container(
                    height: 4.h,
                    padding: EdgeInsets.symmetric(horizontal: 3.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: List.generate(8, (index) {
                        final height =
                            (0.5 +
                                (waveformAnimation.value * 0.5) *
                                    (index % 2 == 0 ? 1 : -1)) *
                            3.h;
                        return Container(
                          width: 2,
                          height: height,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        );
                      }),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
