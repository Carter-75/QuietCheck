import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:sizer/sizer.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../core/app_export.dart';
import '../../widgets/custom_icon_widget.dart';

/// Onboarding Flow screen for QuietCheck mental health application.
/// Educates new users about passive monitoring capabilities with privacy-first messaging.
/// Implements stack navigation with page indicators and skip functionality.
class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 5;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    HapticFeedback.lightImpact();
  }

  void _skipOnboarding() {
    HapticFeedback.mediumImpact();
    Navigator.of(
      context,
      rootNavigator: true,
    ).pushReplacementNamed('/permission-setup');
  }

  void _nextPage() {
    HapticFeedback.lightImpact();
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(
        context,
        rootNavigator: true,
      ).pushReplacementNamed('/permission-setup');
    }
  }

  void _previousPage() {
    HapticFeedback.lightImpact();
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(
        context,
        rootNavigator: true,
      ).pushReplacementNamed('/splash-screen');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
          child: Column(
            children: [
              _buildTopBar(theme),
              SizedBox(height: 2.h),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  children: [
                    _buildWelcomePage(theme),
                    _buildPrivacyPage(theme),
                    _buildWearablePage(theme),
                    _buildTrialPage(theme),
                    _buildFeatureComparisonPage(theme),
                  ],
                ),
              ),
              SizedBox(height: 2.h),
              _buildPageIndicator(theme),
              SizedBox(height: 3.h),
              _buildNavigationButtons(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _currentPage > 0
            ? IconButton(
                onPressed: _previousPage,
                icon: CustomIconWidget(
                  iconName: 'arrow_back',
                  color: theme.colorScheme.onSurface,
                  size: 24,
                ),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
              )
            : SizedBox(width: 48),
        TextButton(
          onPressed: _skipOnboarding,
          child: Text(
            'Skip',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomePage(ThemeData theme) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 4.h),
          SizedBox(
            width: 70.w,
            height: 30.h,
            child: Lottie.asset(
              'assets/animations/welcome.json',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return CustomIconWidget(
                  iconName: 'psychology',
                  color: theme.colorScheme.primary,
                  size: 120,
                );
              },
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Welcome to QuietCheck',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 2.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            child: Text(
              'Your personal mental health companion that passively monitors your well-being and helps prevent burnout before it happens.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 3.h),
          _buildFeatureHighlight(
            theme,
            'Real-time Monitoring',
            'Continuous mental load assessment',
            'speed',
          ),
          SizedBox(height: 2.h),
          _buildFeatureHighlight(
            theme,
            'Smart Alerts',
            'Intelligent notifications when you need them',
            'notifications_active',
          ),
          SizedBox(height: 2.h),
          _buildFeatureHighlight(
            theme,
            'Privacy First',
            'All data stays on your device',
            'lock',
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyPage(ThemeData theme) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 4.h),
          SizedBox(
            width: 70.w,
            height: 30.h,
            child: Lottie.asset(
              'assets/animations/privacy.json',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return CustomIconWidget(
                  iconName: 'shield',
                  color: theme.colorScheme.primary,
                  size: 120,
                );
              },
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Your Privacy Protected',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 2.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            child: Text(
              'QuietCheck processes all data locally on your device. No cloud storage, no data sharing, complete control.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 4.h),
          _buildPrivacyBadge(
            theme,
            'Local Processing',
            'All analysis happens on your device',
            'phone_android',
          ),
          SizedBox(height: 2.h),
          _buildPrivacyBadge(
            theme,
            'AES Encryption',
            'Military-grade data protection',
            'enhanced_encryption',
          ),
          SizedBox(height: 2.h),
          _buildPrivacyBadge(
            theme,
            'No Cloud Storage',
            'Your data never leaves your device',
            'cloud_off',
          ),
          SizedBox(height: 2.h),
          _buildPrivacyBadge(
            theme,
            'You Own Your Data',
            'Delete anytime, export anywhere',
            'verified_user',
          ),
        ],
      ),
    );
  }

  Widget _buildWearablePage(ThemeData theme) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 4.h),
          SizedBox(
            width: 70.w,
            height: 30.h,
            child: Lottie.asset(
              'assets/animations/wearable.json',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return CustomIconWidget(
                  iconName: 'watch',
                  color: theme.colorScheme.primary,
                  size: 120,
                );
              },
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Wearable Integration',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 2.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            child: Text(
              'Connect your smartwatch for enhanced biometric monitoring and more accurate mental load assessment.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 4.h),
          _buildWearableDevice(theme, 'Apple Watch', 'watchOS 8.0+', 'watch'),
          SizedBox(height: 2.h),
          _buildWearableDevice(theme, 'Wear OS', 'Wear OS 3.0+', 'watch'),
          SizedBox(height: 2.h),
          _buildWearableDevice(
            theme,
            'Health Connect',
            'Android integration',
            'favorite',
          ),
          SizedBox(height: 2.h),
          _buildWearableDevice(
            theme,
            'HealthKit',
            'iOS integration',
            'favorite',
          ),
        ],
      ),
    );
  }

  Widget _buildTrialPage(ThemeData theme) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 4.h),
          SizedBox(
            width: 70.w,
            height: 25.h,
            child: Lottie.asset(
              'assets/animations/trial.json',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return CustomIconWidget(
                  iconName: 'card_giftcard',
                  color: theme.colorScheme.primary,
                  size: 120,
                );
              },
            ),
          ),
          SizedBox(height: 3.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '7-DAY FREE TRIAL',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'Try Premium Free',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 1.h),
          Text(
            '\$1.99/month after trial',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 3.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            child: Text(
              'Experience all premium features risk-free. Cancel anytime during your trial.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 3.h),
          _buildPremiumFeature(
            theme,
            'Unlimited Monitoring',
            'No daily limits on mental load tracking',
          ),
          SizedBox(height: 1.5.h),
          _buildPremiumFeature(
            theme,
            'Advanced Analytics',
            'Weekly trends and sleep correlation',
          ),
          SizedBox(height: 1.5.h),
          _buildPremiumFeature(
            theme,
            'Custom Sound Packs',
            'Personalized alert tones',
          ),
          SizedBox(height: 1.5.h),
          _buildPremiumFeature(
            theme,
            'Data Export',
            'Export your mental health data',
          ),
          SizedBox(height: 1.5.h),
          _buildPremiumFeature(
            theme,
            'Priority Support',
            'Get help when you need it',
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureComparisonPage(ThemeData theme) {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 2.h),
          Text(
            'Choose Your Plan',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 3.h),
          _buildComparisonTable(theme),
          SizedBox(height: 3.h),
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                CustomIconWidget(
                  iconName: 'info_outline',
                  color: theme.colorScheme.primary,
                  size: 32,
                ),
                SizedBox(height: 1.h),
                Text(
                  'Start with 7 days free',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 0.5.h),
                Text(
                  'Cancel anytime during trial. No charges until trial ends.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureHighlight(
    ThemeData theme,
    String title,
    String description,
    String iconName,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: CustomIconWidget(
              iconName: iconName,
              color: theme.colorScheme.primary,
              size: 24,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyBadge(
    ThemeData theme,
    String title,
    String description,
    String iconName,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: CustomIconWidget(
              iconName: iconName,
              color: theme.colorScheme.onPrimary,
              size: 24,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWearableDevice(
    ThemeData theme,
    String name,
    String version,
    String iconName,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: CustomIconWidget(
              iconName: iconName,
              color: theme.colorScheme.primary,
              size: 28,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  version,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          CustomIconWidget(
            iconName: 'check_circle',
            color: theme.colorScheme.primary,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumFeature(
    ThemeData theme,
    String title,
    String description,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 6.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(top: 0.5.h),
            child: CustomIconWidget(
              iconName: 'check_circle',
              color: theme.colorScheme.primary,
              size: 20,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 0.3.h),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonTable(ThemeData theme) {
    final features = [
      {'name': 'Basic Monitoring', 'free': true, 'premium': true},
      {'name': 'Daily Limit', 'free': '10 checks', 'premium': 'Unlimited'},
      {'name': 'Mental Load Dashboard', 'free': true, 'premium': true},
      {'name': 'Smart Notifications', 'free': true, 'premium': true},
      {'name': 'Weekly Analytics', 'free': false, 'premium': true},
      {'name': 'Sleep Correlation', 'free': false, 'premium': true},
      {'name': 'Custom Sound Packs', 'free': false, 'premium': true},
      {'name': 'Data Export', 'free': false, 'premium': true},
      {'name': 'Priority Support', 'free': false, 'premium': true},
    ];

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Feature',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Free',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Premium',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          ...features.map((feature) => _buildComparisonRow(theme, feature)),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(ThemeData theme, Map<String, dynamic> feature) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              feature['name'] as String,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          Expanded(child: _buildFeatureCell(theme, feature['free'])),
          Expanded(child: _buildFeatureCell(theme, feature['premium'])),
        ],
      ),
    );
  }

  Widget _buildFeatureCell(ThemeData theme, dynamic value) {
    if (value is bool) {
      return Center(
        child: value
            ? CustomIconWidget(
                iconName: 'check',
                color: theme.colorScheme.primary,
                size: 20,
              )
            : CustomIconWidget(
                iconName: 'close',
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.3,
                ),
                size: 20,
              ),
      );
    } else {
      return Center(
        child: Text(
          value.toString(),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }
  }

  Widget _buildPageIndicator(ThemeData theme) {
    return SmoothPageIndicator(
      controller: _pageController,
      count: _totalPages,
      effect: WormEffect(
        dotHeight: 8,
        dotWidth: 8,
        activeDotColor: theme.colorScheme.primary,
        dotColor: theme.colorScheme.outline.withValues(alpha: 0.3),
        spacing: 12,
      ),
    );
  }

  Widget _buildNavigationButtons(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _currentPage > 0 ? _previousPage : null,
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 2.h),
              side: BorderSide(
                color: _currentPage > 0
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              'Back',
              style: theme.textTheme.titleMedium?.copyWith(
                color: _currentPage > 0
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
        SizedBox(width: 4.w),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _nextPage,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 2.h),
            ),
            child: Text(
              _currentPage == _totalPages - 1 ? 'Get Started' : 'Continue',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
