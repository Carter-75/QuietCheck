import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import './data_service.dart';
import '../models/subscription_data.dart';
import './debug_logging_service.dart';
import '../core/build_config.dart';

/// In-App Purchase Service for Android Google Play Store
/// Handles subscription management, trial periods, and billing
class InAppPurchaseService {
  static InAppPurchaseService? _instance;
  static InAppPurchaseService get instance =>
      _instance ??= InAppPurchaseService._();

  InAppPurchaseService._();

  final InAppPurchase _iap = InAppPurchase.instance;
  final _dataService = DataService.instance;
  final _logging = DebugLoggingService.instance;
  final _buildConfig = BuildConfig.instance;

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  bool _isAvailable = false;

  // Google Play Store Product IDs
  static const String monthlySubscriptionId = 'premium_monthly';
  static const String annualSubscriptionId = 'premium_annual';

  List<ProductDetails> _products = [];

  Future<void> initialize() async {
    int retryCount = 0;
    const maxRetries = 3;
    const retryDelays = [2, 5, 10];

    while (retryCount <= maxRetries) {
      try {
        _isAvailable = await _iap.isAvailable();

        if (_isAvailable) {
          // Listen to purchase updates
          _subscription = _iap.purchaseStream.listen(
            _onPurchaseUpdate,
            onDone: () => _subscription?.cancel(),
            onError: (error) {
              debugPrint('Purchase stream error: $error');
              if (_buildConfig.enableDebugFeatures) {
                _logging.error(
                  'Purchase stream error',
                  category: 'iap',
                  error: error,
                );
              }
            },
          );

          // Load products from Google Play Store
          await loadProducts();

          if (_buildConfig.enableDebugFeatures) {
            _logging.info(
              'Google Play IAP service initialized',
              category: 'iap',
              metadata: {'available': _isAvailable},
            );
          }
        }
        return;
      } catch (e) {
        if (retryCount < maxRetries) {
          retryCount++;
          debugPrint(
            'Retry $retryCount/$maxRetries for IAP initialization: $e',
          );
          if (_buildConfig.enableDebugFeatures) {
            _logging.warning(
              'IAP initialization retry $retryCount',
              category: 'iap',
              metadata: {'error': e.toString()},
            );
          }
          await Future.delayed(Duration(seconds: retryDelays[retryCount - 1]));
        } else {
          debugPrint('IAP initialization error: $e');
          if (_buildConfig.enableDebugFeatures) {
            _logging.error(
              'IAP initialization failed',
              category: 'iap',
              error: e,
            );
          }
          rethrow;
        }
      }
    }
  }

  Future<void> loadProducts() async {
    if (!_isAvailable) return;

    int retryCount = 0;
    const maxRetries = 3;
    const retryDelays = [2, 5, 10];

    while (retryCount <= maxRetries) {
      try {
        const Set<String> productIds = {
          monthlySubscriptionId,
          annualSubscriptionId,
        };

        final ProductDetailsResponse response = await _iap.queryProductDetails(
          productIds,
        );

        if (response.notFoundIDs.isNotEmpty) {
          debugPrint(
            'Products not found in Google Play Store: ${response.notFoundIDs}',
          );
          if (_buildConfig.enableDebugFeatures) {
            _logging.warning(
              'Products not found in Google Play Store',
              category: 'iap',
              metadata: {'notFoundIDs': response.notFoundIDs},
            );
          }
        }

        _products = response.productDetails;
        return;
      } catch (e) {
        if (retryCount < maxRetries) {
          retryCount++;
          debugPrint('Retry $retryCount/$maxRetries for loading products: $e');
          await Future.delayed(Duration(seconds: retryDelays[retryCount - 1]));
        } else {
          debugPrint('Error loading products: $e');
          if (_buildConfig.enableDebugFeatures) {
            _logging.error(
              'Failed to load products from Google Play Store',
              category: 'iap',
              error: e,
            );
          }
          rethrow;
        }
      }
    }
  }

  /// Purchase subscription from Google Play Store
  /// Initiates 7-day free trial, then $1.99/month
  Future<bool> purchaseSubscription(String productId) async {
    if (!_isAvailable) return false;

    try {
      final product = _products.firstWhere(
        (p) => p.id == productId,
        orElse: () => throw Exception('Product not found in Google Play Store'),
      );

      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: product,
      );

      return await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      debugPrint('Purchase error: $e');
      if (_buildConfig.enableDebugFeatures) {
        _logging.error('Purchase failed', category: 'iap', error: e);
      }
      return false;
    }
  }

  /// Restore purchases from Google Play Store
  Future<void> restorePurchases() async {
    if (!_isAvailable) return;

    try {
      await _iap.restorePurchases();
      if (_buildConfig.enableDebugFeatures) {
        _logging.info(
          'Purchases restored from Google Play Store',
          category: 'iap',
        );
      }
    } catch (e) {
      debugPrint('Restore purchases error: $e');
      if (_buildConfig.enableDebugFeatures) {
        _logging.error('Restore purchases failed', category: 'iap', error: e);
      }
    }
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) async {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // Show pending UI
        if (_buildConfig.enableDebugFeatures) {
          _logging.info(
            'Purchase pending',
            category: 'iap',
            metadata: {'productId': purchaseDetails.productID},
          );
        }
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        // Handle error
        debugPrint('Purchase error: ${purchaseDetails.error}');
        if (_buildConfig.enableDebugFeatures) {
          _logging.error(
            'Purchase error',
            category: 'iap',
            error: purchaseDetails.error,
          );
        }
      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        // Verify and deliver product
        await _verifyAndDeliverProduct(purchaseDetails);
      }

      if (purchaseDetails.pendingCompletePurchase) {
        await _iap.completePurchase(purchaseDetails);
      }
    }
  }

  Future<void> _verifyAndDeliverProduct(PurchaseDetails purchaseDetails) async {
    try {
      // Update subscription status in database
      final subscriptionData = await _dataService.getSubscriptionData();

      if (subscriptionData != null) {
        // Create new subscription data with updated values since fields are final
        final now = DateTime.now();
        final updatedSubscriptionData = SubscriptionData(
          id: subscriptionData.id,
          userId: subscriptionData.userId,
          status: 'active',
          trialDaysRemaining: 0,
          subscriptionStartDate: now,
          nextPaymentDate: now.add(
            purchaseDetails.productID == monthlySubscriptionId
                ? Duration(days: 30)
                : Duration(days: 365),
          ),
          encryptedPaymentInfo: subscriptionData.encryptedPaymentInfo,
          createdAt: subscriptionData.createdAt,
          updatedAt: now,
        );

        await _dataService.updateSubscriptionData(updatedSubscriptionData);

        if (_buildConfig.enableDebugFeatures) {
          _logging.info(
            'Subscription activated',
            category: 'iap',
            metadata: {
              'productId': purchaseDetails.productID,
              'status': 'active',
            },
          );
        }
      }
    } catch (e) {
      debugPrint('Error delivering product: $e');
      if (_buildConfig.enableDebugFeatures) {
        _logging.error('Product delivery failed', category: 'iap', error: e);
      }
    }
  }

  List<ProductDetails> get products => _products;
  bool get isAvailable => _isAvailable;

  void dispose() {
    _subscription?.cancel();
  }
}
