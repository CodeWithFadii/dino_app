import 'dart:async';
import 'dart:developer';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:hive/hive.dart';
import '/models/player_data.dart';

class InAppPurchaseService {
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  bool available = false;
  List<ProductDetails> products = [];

  final List<String> _productIds = ['starter', 'small', 'medium', 'large', 'mega'];

  static final InAppPurchaseService instance = InAppPurchaseService._internal();
  InAppPurchaseService._internal();

  Future<void> init() async {
    if (_subscription != null) return; // Prevent reinitialization

    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdated,
      onError: _onError,
    );

    available = await _iap.isAvailable();
    if (!available) return;

    final response = await _iap.queryProductDetails(_productIds.toSet());
    if (response.error != null) {
      print('ProductDetails error: ${response.error}');
    } else {
      products = response.productDetails;
    }
  }

  void _onPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchase in purchaseDetailsList) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          break;
        case PurchaseStatus.error:
          _onError(purchase.error!);
          Fluttertoast.showToast(
              msg: "Failed to purchase coins!",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              timeInSecForIosWeb: 1,
              backgroundColor: Colors.red,
              textColor: Colors.white,
              fontSize: 16.0);
          break;
        case PurchaseStatus.purchased:
          _deliverProduct(purchase);
          Fluttertoast.showToast(
              msg: "Successfully purchased coins!",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              timeInSecForIosWeb: 1,
              backgroundColor: Colors.green,
              textColor: Colors.white,
              fontSize: 16.0);
          break;
        case PurchaseStatus.canceled:
          break;
        default:
          break;
      }

      if (purchase.pendingCompletePurchase) {
        _iap.completePurchase(purchase);
      }
    }
  }

  void _deliverProduct(PurchaseDetails purchase) {
    print('Purchased: ${purchase.productID}');
    final coins = _getCoinsForProduct(purchase.productID);

    try {
      final playerDataBox = Hive.box<PlayerData>('DinoRun.PlayerDataBox');
      final playerData = playerDataBox.get('DinoRun.PlayerData');
      playerData?.addCoins(coins);
      playerDataBox.put('DinoRun.PlayerData', playerData!);
    } catch (e) {
      print('Error saving to Hive: $e');
    }

    _iap.completePurchase(purchase);
  }

  int _getCoinsForProduct(String productId) {
    switch (productId) {
      case 'starter':
        return 100;
      case 'small':
        return 200;
      case 'medium':
        return 300;
      case 'large':
        return 400;
      case 'mega':
        return 500;
      default:
        return 0;
    }
  }

  void _onError(Object error, [StackTrace? stackTrace]) {
    if (error is IAPError) {
      print('Purchase Error: ${error.message}');
    } else {
      print('Unknown purchase error: $error');
    }
    if (stackTrace != null) {
      print(stackTrace);
    }
  }

  Future<bool> buy(ProductDetails product) async {
    final param = PurchaseParam(productDetails: product);
    return await _iap.buyConsumable(purchaseParam: param, autoConsume: true);
  }

  Future<void> restore() async {
    await _iap.restorePurchases();
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}
