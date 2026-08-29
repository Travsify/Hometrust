import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../models/purchase_model.dart';

class PurchaseProvider with ChangeNotifier {
  List<PurchaseModel> _userPurchases = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<PurchaseModel> get userPurchases => _userPurchases;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchMyPurchases() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiClient.get('/purchases/my-purchases');
      if (res is List) {
        _userPurchases = res.map((p) => PurchaseModel.fromJson(p)).toList();
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  Future<PurchaseModel?> initiatePurchase({
    String? propertyId,
    String? projectUnitId,
    String? paymentPlanId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiClient.post('/purchases', {
        'propertyId': propertyId,
        'projectUnitId': projectUnitId,
        'paymentPlanId': paymentPlanId,
      });

      final purchase = PurchaseModel.fromJson(res);
      _userPurchases.insert(0, purchase);
      _isLoading = false;
      notifyListeners();
      return purchase;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  Future<Map<String, dynamic>?> initializePayment({
    required double amount,
    required String purpose,
    String? purchaseId,
    String? verificationRequestId,
    String? legalRequestId,
    String? developerId,
  }) async {
    try {
      final res = await ApiClient.post('/payments/initialize', {
        'amount': amount,
        'purpose': purpose,
        'purchaseId': purchaseId,
        'verificationRequestId': verificationRequestId,
        'legalRequestId': legalRequestId,
        'developerId': developerId,
      });
      return res;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  Future<bool> verifyPayment(String reference) async {
    try {
      await ApiClient.get('/payments/verify/$reference');
      await fetchMyPurchases();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}
