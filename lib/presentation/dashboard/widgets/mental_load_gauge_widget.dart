import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'dart:math' as math;

class MentalLoadGaugeWidget extends StatefulWidget {
  final int score;
  final VoidCallback onLongPress;

  const MentalLoadGaugeWidget({
    super.key,
    required this.score,
    required this.onLongPress,
  });

  @override
  State<MentalLoadGaugeWidget> createState() => _MentalLoadGaugeWidgetState();
}

class _MentalLoadGaugeWidgetState extends State<MentalLoadGaugeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: widget.score.toDouble()).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();
  }

  @override
  void didUpdateWidget(MentalLoadGaugeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score) {
      _animation =
          Tween<double>(
            begin: oldWidget.score.toDouble(),
            end: widget.score.toDouble(),
          ).animate(
            CurvedAnimation(
              parent: _animationController,
              curve: Curves.easeOutCubic,
            ),
          );
      _animationController.forward(from: 0);
      HapticFeedback.lightImpact();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getColorForScore(int score) {
    if (score <= 40) return Colors.green;
    if (score <= 65) return Colors.yellow.shade700;
    if (score <= 80) return Colors.orange;
    return Colors.red;
  }

  String _getZoneLabel(int score) {
    if (score <= 40) return "Optimal";
    if (score <= 65) return "Moderate";
    if (score <= 80) return "Elevated";
    return "Critical";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onLongPress: () {
        HapticFeedback.mediumImpact();
        widget.onLongPress();
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              "Mental Load",
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 2.h),
            SizedBox(
              height: 30.h,
              width: 30.h,
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return CustomPaint(
                    painter: GaugePainter(
                      score: _animation.value.toInt(),
                      color: _getColorForScore(_animation.value.toInt()),
                      backgroundColor: theme.colorScheme.surface,
                      strokeColor: theme.colorScheme.outline,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _animation.value.toInt().toString(),
                            style: theme.textTheme.displayLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: _getColorForScore(
                                _animation.value.toInt(),
                              ),
                            ),
                          ),
                          Text(
                            _getZoneLabel(_animation.value.toInt()),
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              "Long press for detailed breakdown",
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.7,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GaugePainter extends CustomPainter {
  final int score;
  final Color color;
  final Color backgroundColor;
  final Color strokeColor;

  GaugePainter({
    required this.score,
    required this.color,
    required this.backgroundColor,
    required this.strokeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 20;

    // Background arc
    final backgroundPaint = Paint()
      ..color = strokeColor.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi * 0.75,
      math.pi * 1.5,
      false,
      backgroundPaint,
    );

    // Foreground arc
    final foregroundPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;

    final sweepAngle = (score / 100) * math.pi * 1.5;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi * 0.75,
      sweepAngle,
      false,
      foregroundPaint,
    );
  }

  @override
  bool shouldRepaint(GaugePainter oldDelegate) {
    return oldDelegate.score != score || oldDelegate.color != color;
  }
}
