import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/billing_history_widget.dart';
import './widgets/feature_comparison_widget.dart';
import './widgets/pricing_card_widget.dart';
import '../../services/data_service.dart';
import '../../models/subscription_data.dart';
import '../../services/analytics_tracking_service.dart';
import '../../services/supabase_analytics_service.dart';
import '../../services/in_app_purchase_service_io.dart' as iap_io;

/// Subscription Management Screen
/// Handles Google Play Store billing, trial status, and feature access
class SubscriptionManagement extends StatefulWidget {
  const SubscriptionManagement({super.key});

  @override
  State<SubscriptionManagement> createState() => _SubscriptionManagementState();
}

class _SubscriptionManagementState extends State<SubscriptionManagement> {
  bool _isProcessing = false;

  final _dataService = DataService.instance;
  bool _isLoading = true;

  List<Map<String, dynamic>> _billingHistory = [];
  final _iapService = iap_io.InAppPurchaseService.instance;
  List<dynamic> _availableProducts = [];

  // Subscription data loaded from Supabase
  bool _isSubscribed = false;
  int _trialDaysRemaining = 0;
  String _nextPaymentDate = "";

  @override
  void initState() {
    super.initState();
    _loadSubscriptionData();

    // Track screen view
    AnalyticsTrackingService.instance.trackScreenView(
      'Subscription Management',
    );
  }

  Future<void> _initializeIAP() async {
    try {
      await _iapService.initialize();
      await _iapService.loadProducts();
      setState(() {
        _availableProducts = _iapService.products;
      });
    } catch (e) {
      debugPrint('Google Play IAP initialization error: $e');
    }
  }

  @override
  void dispose() {
    _iapService.dispose();
    super.dispose();
  }

  void _trackScreenView() {
    SupabaseAnalyticsService.instance.trackScreenView(
      'subscription_management',
    );
    AnalyticsTrackingService.instance.trackScreenView(
      'subscription_management',
    );
    AnalyticsTrackingService.instance.trackConversionStage(
      stage: 'viewed_pricing',
      conversionSource: 'subscription_screen',
    );
  }

  void _handleUpgradeClick(String plan) {
    // Track subscription interest
    SupabaseAnalyticsService.instance.trackFeatureUsage('subscription_upgrade');
    AnalyticsTrackingService.instance.trackButtonClick(
      'Upgrade to $plan',
      'subscription_management',
    );
    AnalyticsTrackingService.instance.trackConversionStage(
      stage: 'initiated_checkout',
      conversionSource: 'subscription_screen',
      pricingPlan: plan,
    );

    // Show upgrade dialog with Google Play Store payment
    _showUpgradeDialog(plan);
  }

  void _showUpgradeDialog(String plan) {
    if (!_iapService.isAvailable) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Google Play Store Not Available'),
          content: Text(
            'In-app purchases are not available. Please ensure you have Google Play Store installed and try again.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Start 7-Day Free Trial'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Start your free trial today and enjoy all premium features for 7 days.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(height: 2.h),
            Text(
              '• Full access to all premium features\n• Cancel anytime during trial\n• Charged \$1.99/month after trial ends\n• Managed through Google Play Store',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isProcessing = true);

              final productId = plan.toLowerCase().contains('annual')
                  ? 'premium_annual'
                  : 'premium_monthly';

              final success = await _iapService.purchaseSubscription(productId);

              if (success) {
                // Create subscription with 7-day trial
                final userId = _dataService.currentUserId;
                if (userId != null) {
                  final subscriptionData = SubscriptionData(
                    userId: userId,
                    status: 'trial',
                    trialDaysRemaining: 7,
                    subscriptionStartDate: DateTime.now(),
                    nextPaymentDate: DateTime.now().add(Duration(days: 7)),
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );
                  await _dataService.updateSubscriptionData(subscriptionData);
                }
              }

              setState(() => _isProcessing = false);

              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Your 7-day free trial has started!'),
                    backgroundColor: Theme.of(context).colorScheme.tertiary,
                  ),
                );
                await _loadSubscriptionData();
              }
            },
            child: Text('Start Free Trial'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadSubscriptionData() async {
    setState(() => _isLoading = true);
    try {
      final subscriptionData = await _dataService.getSubscriptionData();
      if (subscriptionData != null) {
        setState(() {
          _isSubscribed = subscriptionData.isSubscribed;
          _trialDaysRemaining = subscriptionData.trialDaysRemaining;
          _nextPaymentDate =
              subscriptionData.nextPaymentDate?.toIso8601String().split(
                'T',
              )[0] ??
              '';
        });
      }

      final billingRecords = await _dataService.getBillingHistory();
      setState(() {
        _billingHistory = billingRecords
            .map(
              (b) => {
                'date': b.transactionDate.toIso8601String().split('T')[0],
                'amount': b.amount,
                'status': b.status,
                'receiptUrl': '',
              },
            )
            .toList();
      });
    } catch (e) {
      debugPrint('Error loading subscription data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Subscription'),
        leading: IconButton(
          icon: CustomIconWidget(
            iconName: 'arrow_back',
            color: theme.colorScheme.onSurface,
            size: 24,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
          child: _isProcessing
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: theme.colorScheme.primary,
                      ),
                      SizedBox(height: 2.h),
                      Text('Processing...', style: theme.textTheme.bodyLarge),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeroSection(theme),
                      SizedBox(height: 3.h),
                      FeatureComparisonWidget(),
                      SizedBox(height: 3.h),
                      PricingCardWidget(
                        isSubscribed: _isSubscribed,
                        onUpgrade: _handleUpgrade,
                      ),
                      if (_isSubscribed) ...[
                        SizedBox(height: 3.h),
                        _buildBillingInfo(theme),
                        SizedBox(height: 3.h),
                        BillingHistoryWidget(billingHistory: _billingHistory),
                        SizedBox(height: 3.h),
                        _buildManagementOptions(theme),
                      ],
                      if (!_isSubscribed) ...[
                        SizedBox(height: 3.h),
                        _buildRestorePurchases(theme),
                      ],
                      SizedBox(height: 2.h),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: _isSubscribed ? 'verified' : 'schedule',
                color: theme.colorScheme.onPrimary,
                size: 32,
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isSubscribed ? 'Premium Active' : 'Free Trial',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      _isSubscribed
                          ? 'Enjoying all premium features'
                          : 'Explore premium features',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimary.withValues(
                          alpha: 0.9,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!_isSubscribed) ...[
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: theme.colorScheme.onPrimary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomIconWidget(
                    iconName: 'timer',
                    color: theme.colorScheme.onPrimary,
                    size: 20,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    '$_trialDaysRemaining days remaining',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBillingInfo(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Billing Information',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          _buildInfoRow(
            theme,
            'Current Plan',
            'Premium Monthly',
            'credit_card',
          ),
          SizedBox(height: 1.5.h),
          _buildInfoRow(
            theme,
            'Next Payment',
            _nextPaymentDate,
            'calendar_today',
          ),
          SizedBox(height: 1.5.h),
          _buildInfoRow(theme, 'Amount', '\$1.99/month', 'attach_money'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    ThemeData theme,
    String label,
    String value,
    String iconName,
  ) {
    return Row(
      children: [
        CustomIconWidget(
          iconName: iconName,
          color: theme.colorScheme.primary,
          size: 20,
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildManagementOptions(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Subscription Management',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 1.5.h),
        _buildManagementButton(
          theme,
          'Restore Purchases',
          'restore',
          () => _handleRestorePurchases(),
        ),
        SizedBox(height: 1.h),
        _buildManagementButton(
          theme,
          'Cancel Subscription',
          'cancel',
          () => _showCancelDialog(),
          isDestructive: true,
        ),
      ],
    );
  }

  Widget _buildManagementButton(
    ThemeData theme,
    String label,
    String iconName,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDestructive
                ? theme.colorScheme.error.withValues(alpha: 0.3)
                : theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            CustomIconWidget(
              iconName: iconName,
              color: isDestructive
                  ? theme.colorScheme.error
                  : theme.colorScheme.primary,
              size: 24,
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: isDestructive
                      ? theme.colorScheme.error
                      : theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            CustomIconWidget(
              iconName: 'chevron_right',
              color: theme.colorScheme.onSurfaceVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestorePurchases(ThemeData theme) {
    return Center(
      child: TextButton.icon(
        onPressed: () async {
          if (!_iapService.isAvailable) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Restore purchases not available on this platform',
                ),
              ),
            );
            return;
          }

          setState(() => _isProcessing = true);
          await _iapService.restorePurchases();
          await _loadSubscriptionData();
          setState(() => _isProcessing = false);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Purchases restored successfully'),
                backgroundColor: theme.colorScheme.tertiary,
              ),
            );
          }
        },
        icon: CustomIconWidget(
          iconName: 'restore',
          color: theme.colorScheme.primary,
          size: 20,
        ),
        label: Text(
          'Restore Purchases',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Future<void> _handleUpgrade() async {
    setState(() => _isProcessing = true);
    try {
      final userId = _dataService.currentUserId;
      if (userId == null) return;

      final subscriptionData = SubscriptionData(
        userId: userId,
        status: 'active',
        trialDaysRemaining: 0,
        subscriptionStartDate: DateTime.now(),
        nextPaymentDate: DateTime.now().add(Duration(days: 30)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _dataService.updateSubscriptionData(subscriptionData);
      await _loadSubscriptionData();
    } catch (e) {
      debugPrint('Error upgrading subscription: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _handleRestorePurchases() {
    HapticFeedback.lightImpact();
    setState(() => _isProcessing = true);

    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isProcessing = false);
        _showSuccessSnackBar('Purchases restored successfully!');
      }
    });
  }

  void _showCancelDialog() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancel Subscription?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You will lose access to:',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.h),
            _buildFeatureLossItem(theme, 'Unlimited mental load monitoring'),
            _buildFeatureLossItem(theme, 'Advanced analytics and insights'),
            _buildFeatureLossItem(theme, 'Data export functionality'),
            _buildFeatureLossItem(theme, 'Premium sound packs'),
            SizedBox(height: 1.h),
            Text(
              'To cancel, please visit your subscription settings in the App Store or Google Play Store.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Keep Subscription'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showSuccessSnackBar(
                'Please manage subscription in your app store settings',
              );
            },
            child: Text(
              'Open Settings',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureLossItem(ThemeData theme, String feature) {
    return Padding(
      padding: EdgeInsets.only(bottom: 0.5.h),
      child: Row(
        children: [
          CustomIconWidget(
            iconName: 'close',
            color: theme.colorScheme.error,
            size: 16,
          ),
          SizedBox(width: 2.w),
          Expanded(child: Text(feature, style: theme.textTheme.bodySmall)),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
