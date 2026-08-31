import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../models/verification_model.dart';

class VerificationProvider with ChangeNotifier {
  List<VerificationRequestModel> _userRequests = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<VerificationRequestModel> get userRequests => _userRequests;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchMyRequests() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiClient.get('/verifications/my-requests');
      if (res is List) {
        _userRequests = res.map((r) => VerificationRequestModel.fromJson(r)).toList();
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  Future<VerificationRequestModel?> submitVerification({
    required String propertyName,
    required String propertyAddress,
    required String state,
    required String city,
    required String documentType,
    String urgency = 'STANDARD',
    String deliveryOption = 'DIGITAL_ONLY',
    String? deliveryAddress,
    double deliveryFee = 0.0,
    required String fileName,
    Uint8List? fileBytes,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      dynamic res;

      if (fileBytes != null) {
        // Upload as multipart — backend receives the real file
        res = await ApiClient.uploadFile(
          '/verifications',
          fileBytes: fileBytes,
          fileName: fileName,
          fieldName: 'document',
          extraFields: {
            'propertyName': propertyName.trim(),
            'propertyAddress': propertyAddress.trim(),
            'state': state.trim(),
            'city': city.trim(),
            'documentType': documentType,
            'urgency': urgency,
            'deliveryOption': deliveryOption,
            'deliveryAddress': deliveryAddress ?? '',
            'deliveryFee': deliveryFee.toString(),
          },
        );
      } else {
        // Fallback JSON
        res = await ApiClient.post('/verifications', {
          'propertyName': propertyName.trim(),
          'propertyAddress': propertyAddress.trim(),
          'state': state.trim(),
          'city': city.trim(),
          'documentType': documentType,
          'urgency': urgency,
          'deliveryOption': deliveryOption,
          'deliveryAddress': deliveryAddress,
          'deliveryFee': deliveryFee,
        });
      }

      final newReq = VerificationRequestModel.fromJson(res);
      _userRequests.insert(0, newReq);
      _isLoading = false;
      notifyListeners();
      return newReq;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  Future<bool> payVerificationWithWallet(String requestId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await ApiClient.post('/verifications/$requestId/pay-wallet', {});
      await fetchMyRequests();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}
