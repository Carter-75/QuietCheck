import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Custom bottom navigation bar for QuietCheck mental health application.
/// Implements Bottom-Heavy Primary Actions pattern with tab bar navigation.
///
/// Features:
/// - Parameterized design for reusability
/// - Haptic feedback on navigation
/// - Platform-aware styling
/// - Matches Mobile Navigation Hierarchy from design theme
class CustomBottomBar extends StatelessWidget {
  /// Current selected index
  final int currentIndex;

  /// Callback when navigation item is tapped
  final Function(int) onTap;

  const CustomBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: theme.bottomNavigationBarTheme.backgroundColor,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8.0,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) {
            // Haptic feedback for navigation (Mindful Motion)
            HapticFeedback.lightImpact();
            onTap(index);
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: theme.bottomNavigationBarTheme.selectedItemColor,
          unselectedItemColor:
              theme.bottomNavigationBarTheme.unselectedItemColor,
          selectedLabelStyle: theme.bottomNavigationBarTheme.selectedLabelStyle,
          unselectedLabelStyle:
              theme.bottomNavigationBarTheme.unselectedLabelStyle,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: [
            // Dashboard/Gauge Icon - Real-time mental load monitoring
            BottomNavigationBarItem(
              icon: Icon(Icons.speed_outlined, size: 24),
              activeIcon: Icon(Icons.speed, size: 24),
              label: 'Dashboard',
              tooltip: 'Real-time mental load monitoring',
            ),

            // Analytics/Chart Icon - Trend analysis and insights
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics_outlined, size: 24),
              activeIcon: Icon(Icons.analytics, size: 24),
              label: 'Analytics',
              tooltip: 'Trend analysis and insights',
            ),

            // Goals/Flag Icon - Wellness goals and progress tracking
            BottomNavigationBarItem(
              icon: Icon(Icons.flag_outlined, size: 24),
              activeIcon: Icon(Icons.flag, size: 24),
              label: 'Goals',
              tooltip: 'Wellness goals and progress tracking',
            ),

            // Recovery/Heart Icon - Stress reduction guidance (Critical emergency access)
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_outline, size: 24),
              activeIcon: Icon(Icons.favorite, size: 24),
              label: 'Recovery',
              tooltip: 'Stress reduction guidance',
            ),

            // Settings/Gear Icon - Configuration and privacy controls
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined, size: 24),
              activeIcon: Icon(Icons.settings, size: 24),
              label: 'Settings',
              tooltip: 'Configuration and privacy controls',
            ),

            // Profile/Person Icon - Subscription and account management
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline, size: 24),
              activeIcon: Icon(Icons.person, size: 24),
              label: 'Profile',
              tooltip: 'Subscription and account management',
            ),
          ],
        ),
      ),
    );
  }
}
