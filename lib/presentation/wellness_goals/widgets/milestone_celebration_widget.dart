import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'dart:math'; // Add this import for cos() and sin() methods
import '../../../models/goal_milestone.dart';

class MilestoneCelebrationWidget extends StatefulWidget {
  final GoalMilestone milestone;
  final VoidCallback onDismiss;

  const MilestoneCelebrationWidget({
    super.key,
    required this.milestone,
    required this.onDismiss,
  });

  @override
  State<MilestoneCelebrationWidget> createState() =>
      _MilestoneCelebrationWidgetState();
}

class _MilestoneCelebrationWidgetState extends State<MilestoneCelebrationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _confettiAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );
    _confettiAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Animated confetti particles
          AnimatedBuilder(
            animation: _confettiAnimation,
            builder: (context, child) {
              return CustomPaint(
                size: const Size(300, 400),
                painter: ConfettiPainter(
                  progress: _confettiAnimation.value,
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary,
                    theme.colorScheme.tertiary,
                    Colors.pink,
                    Colors.orange,
                  ],
                ),
              );
            },
          ),

          // Content
          ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              padding: EdgeInsets.all(6.w),
              margin: EdgeInsets.symmetric(horizontal: 8.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(51),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Trophy icon
                  Container(
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getMilestoneIcon(widget.milestone.milestoneType),
                      size: 50,
                      color: theme.colorScheme.primary,
                    ),
                  ),

                  SizedBox(height: 3.h),

                  // Title
                  Text(
                    widget.milestone.title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: 1.h),

                  // Description
                  if (widget.milestone.description != null)
                    Text(
                      widget.milestone.description!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),

                  SizedBox(height: 3.h),

                  // Achievement value
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 1.h,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer.withAlpha(51),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Text(
                      '${widget.milestone.achievementValue} ${_getAchievementUnit(widget.milestone.milestoneType)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  ),

                  SizedBox(height: 3.h),

                  // Continue button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: widget.onDismiss,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 2.h),
                      ),
                      child: const Text('Continue'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getMilestoneIcon(String type) {
    switch (type) {
      case 'goal_completion':
        return Icons.emoji_events;
      case 'streak_achievement':
        return Icons.local_fire_department;
      case 'progress_milestone':
        return Icons.stars;
      case 'consistency_badge':
        return Icons.verified;
      default:
        return Icons.celebration;
    }
  }

  String _getAchievementUnit(String type) {
    switch (type) {
      case 'streak_achievement':
        return 'days';
      case 'progress_milestone':
        return 'completed';
      default:
        return 'achieved';
    }
  }
}

class ConfettiPainter extends CustomPainter {
  final double progress;
  final List<Color> colors;

  ConfettiPainter({required this.progress, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0) return;

    final paint = Paint()..style = PaintingStyle.fill;

    // Generate 30 confetti particles
    for (int i = 0; i < 30; i++) {
      final angle = (i / 30) * 2 * 3.14159;
      final distance = progress * (100 + (i % 10) * 10);
      final x = size.width / 2 + cos(angle * distance / 6.28318) * distance;
      final y =
          size.height / 2 +
          sin(angle * distance / 6.28318) * distance +
          progress * 200;

      paint.color = colors[i % colors.length].withAlpha(
        ((1 - progress) * 255).toInt(),
      );

      // Draw confetti as small rectangles with rotation
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(progress * 4 * 3.14159 + i);
      canvas.drawRect(const Rect.fromLTWH(-4, -8, 8, 16), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}