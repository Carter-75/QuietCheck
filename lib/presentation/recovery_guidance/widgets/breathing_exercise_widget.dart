import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';
import '../../../services/tts_service.dart';

/// Breathing Exercise Widget
/// Animated breathing guide with inhale/exhale timing and customizable session duration
class BreathingExerciseWidget extends StatefulWidget {
  final bool isActive;
  final int selectedDuration;
  final bool audioGuidanceEnabled;
  final VoidCallback onToggleBreathing;
  final Function(int) onUpdateDuration;
  final VoidCallback onToggleAudioGuidance;

  const BreathingExerciseWidget({
    super.key,
    required this.isActive,
    required this.selectedDuration,
    required this.audioGuidanceEnabled,
    required this.onToggleBreathing,
    required this.onUpdateDuration,
    required this.onToggleAudioGuidance,
  });

  @override
  State<BreathingExerciseWidget> createState() =>
      _BreathingExerciseWidgetState();
}

class _BreathingExerciseWidgetState extends State<BreathingExerciseWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _breathController;
  late Animation<double> _breathAnimation;
  Timer? _sessionTimer;
  Timer? _hapticTimer;
  int _remainingSeconds = 0;
  String _breathPhase = 'Inhale';
  int _cycleCount = 0;
  final _ttsService = TtsService.instance;

  @override
  void initState() {
    super.initState();
    _ttsService.initialize();
    _breathController = AnimationController(
      duration: Duration(seconds: 8),
      vsync: this,
    );

    _breathAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );

    _breathController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _breathPhase = 'Exhale';
        });
        if (widget.audioGuidanceEnabled) {
          _ttsService.speakExhale();
        }
        _breathController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        setState(() {
          _breathPhase = 'Inhale';
          _cycleCount++;
        });
        if (widget.audioGuidanceEnabled) {
          _ttsService.speakInhale();
        }
        _breathController.forward();
      }
    });
  }

  @override
  void didUpdateWidget(BreathingExerciseWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _startBreathingSession();
      } else {
        _stopBreathingSession();
      }
    }
  }

  void _startBreathingSession() {
    setState(() {
      _remainingSeconds = widget.selectedDuration * 60;
      _cycleCount = 0;
      _breathPhase = 'Inhale';
    });

    if (widget.audioGuidanceEnabled) {
      _ttsService.speakInhale();
    }

    _breathController.forward();

    _sessionTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _remainingSeconds--;
        if (_remainingSeconds <= 0) {
          _stopBreathingSession();
          _showCompletionMessage();
        }
      });
    });

    _hapticTimer = Timer.periodic(Duration(seconds: 4), (timer) {
      if (!mounted || !widget.isActive) {
        timer.cancel();
        return;
      }
      HapticFeedback.lightImpact();
    });
  }

  void _stopBreathingSession() {
    _breathController.stop();
    _breathController.reset();
    _sessionTimer?.cancel();
    _hapticTimer?.cancel();
    _ttsService.stop();
    setState(() {
      _remainingSeconds = 0;
    });
  }

  void _showCompletionMessage() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Breathing session completed! Great work.'),
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _breathController.dispose();
    _sessionTimer?.cancel();
    _hapticTimer?.cancel();
    _ttsService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Breathing Exercise',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              CustomIconWidget(
                iconName: 'air',
                color: theme.colorScheme.primary,
                size: 28,
              ),
            ],
          ),

          SizedBox(height: 1.h),

          Text(
            'Follow the breathing guide to calm your mind and reduce stress',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),

          SizedBox(height: 3.h),

          // Breathing Circle Animation
          Center(
            child: AnimatedBuilder(
              animation: _breathAnimation,
              builder: (context, child) {
                return Container(
                  width: 60.w * _breathAnimation.value,
                  height: 60.w * _breathAnimation.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        theme.colorScheme.primary.withValues(alpha: 0.6),
                        theme.colorScheme.primary.withValues(alpha: 0.2),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 20 * _breathAnimation.value,
                        spreadRadius: 5 * _breathAnimation.value,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _breathPhase,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                        widget.isActive
                            ? SizedBox(height: 1.h)
                            : SizedBox.shrink(),
                        widget.isActive
                            ? Text(
                                _formatTime(_remainingSeconds),
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.onPrimary.withValues(
                                    alpha: 0.8,
                                  ),
                                ),
                              )
                            : SizedBox.shrink(),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          SizedBox(height: 3.h),

          widget.isActive
              ? Center(
                  child: Text(
                    'Cycle ${_cycleCount + 1}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : SizedBox.shrink(),

          widget.isActive ? SizedBox(height: 2.h) : SizedBox.shrink(),

          // Duration Selector (only when not active)
          !widget.isActive
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Session Duration',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Wrap(
                      spacing: 2.w,
                      runSpacing: 1.h,
                      children: [1, 3, 5, 7, 10].map((minutes) {
                        final isSelected = widget.selectedDuration == minutes;
                        return InkWell(
                          onTap: () => widget.onUpdateDuration(minutes),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 4.w,
                              vertical: 1.h,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.outline,
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              '$minutes min',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: isSelected
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.onSurface,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 2.h),
                  ],
                )
              : SizedBox.shrink(),

          // Audio Guidance Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Audio Guidance',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Switch(
                value: widget.audioGuidanceEnabled,
                onChanged: (value) => widget.onToggleAudioGuidance(),
              ),
            ],
          ),

          SizedBox(height: 2.h),

          // Start/Stop Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.onToggleBreathing,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.isActive
                    ? theme.colorScheme.error
                    : theme.colorScheme.primary,
                padding: EdgeInsets.symmetric(vertical: 2.h),
              ),
              child: Text(
                widget.isActive ? 'Stop Session' : 'Start Breathing',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: widget.isActive
                      ? theme.colorScheme.onError
                      : theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
