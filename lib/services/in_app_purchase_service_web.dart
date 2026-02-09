import 'dart:async';
import 'package:flutter/foundation.dart';

/// Web stub for In-App Purchase Service
/// In-app purchases are not supported on web platform
class InAppPurchaseService {
  static InAppPurchaseService? _instance;
  static InAppPurchaseService get instance =>
      _instance ??= InAppPurchaseService._();

  InAppPurchaseService._();

  Future<void> initialize() async {
    debugPrint('In-app purchases not supported on web');
  }

  Future<void> loadProducts() async {
    debugPrint('In-app purchases not supported on web');
  }

  Future<bool> purchaseSubscription(String productId) async {
    debugPrint('In-app purchases not supported on web');
    return false;
  }

  Future<void> restorePurchases() async {
    debugPrint('In-app purchases not supported on web');
  }

  List<dynamic> get products => [];
  bool get isAvailable => false;

  void dispose() {}
}
