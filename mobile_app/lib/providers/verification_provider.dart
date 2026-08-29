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
    required String fileName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiClient.post('/verifications', {
        'propertyName': propertyName.trim(),
        'propertyAddress': propertyAddress.trim(),
        'state': state.trim(),
        'city': city.trim(),
        'documentType': documentType,
        'urgency': urgency,
        'documents': [
          {
            'fileName': fileName,
            'fileUrl': 'http://localhost:5000/api/v1/storage/files/uploaded_doc.pdf',
            'fileType': 'PDF',
            'fileSize': 1850000,
          },
        ],
      });

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
}
