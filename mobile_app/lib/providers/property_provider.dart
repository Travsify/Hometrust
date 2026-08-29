import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../models/property_model.dart';
import '../models/project_model.dart';

class PropertyProvider with ChangeNotifier {
  List<PropertyModel> _properties = [];
  List<ProjectModel> _projects = [];
  List<DeveloperSummaryModel> _developers = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Active filters
  String? _selectedState;
  String? _selectedType;
  String? _selectedListingType; // OUTRIGHT, OFF_PLAN, PAY_SMALL_SMALL
  bool _verifiedOnly = false;
  String _searchQuery = '';

  List<PropertyModel> get properties => _properties;
  List<ProjectModel> get projects => _projects;
  List<DeveloperSummaryModel> get developers => _developers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String? get selectedState => _selectedState;
  String? get selectedType => _selectedType;
  String? get selectedListingType => _selectedListingType;
  bool get verifiedOnly => _verifiedOnly;

  List<PropertyModel> get offPlanProperties =>
      _properties.where((p) => p.listingType == 'OFF_PLAN').toList();

  List<PropertyModel> get paySmallSmallProperties =>
      _properties.where((p) => p.listingType == 'PAY_SMALL_SMALL').toList();

  List<PropertyModel> get featuredProperties =>
      _properties.where((p) => p.isFeatured).toList();

  Future<void> fetchAll() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Build query string
      String query = '?';
      if (_selectedState != null && _selectedState != 'All') query += 'state=$_selectedState&';
      if (_selectedType != null && _selectedType != 'All') query += 'propertyType=$_selectedType&';
      if (_selectedListingType != null && _selectedListingType != 'All') query += 'listingType=$_selectedListingType&';
      if (_verifiedOnly) query += 'isVerifiedDeveloperOnly=true&';
      if (_searchQuery.isNotEmpty) query += 'search=$_searchQuery&';

      final propRes = await ApiClient.get('/properties$query');
      if (propRes is List) {
        _properties = propRes.map((p) => PropertyModel.fromJson(p)).toList();
      }

      final projRes = await ApiClient.get('/projects');
      if (projRes is Map && projRes['projects'] != null) {
        _projects = (projRes['projects'] as List)
            .map((p) => ProjectModel.fromJson(p))
            .toList();
      }

      final devRes = await ApiClient.get('/developers?isVerified=true');
      if (devRes is Map && devRes['developers'] != null) {
        _developers = (devRes['developers'] as List)
            .map((d) => DeveloperSummaryModel.fromJson(d))
            .toList();
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  void setFilters({
    String? state,
    String? propertyType,
    String? listingType,
    bool? verifiedOnly,
    String? search,
  }) {
    if (state != null) _selectedState = state;
    if (propertyType != null) _selectedType = propertyType;
    if (listingType != null) _selectedListingType = listingType;
    if (verifiedOnly != null) _verifiedOnly = verifiedOnly;
    if (search != null) _searchQuery = search;
    fetchAll();
  }

  void clearFilters() {
    _selectedState = null;
    _selectedType = null;
    _selectedListingType = null;
    _verifiedOnly = false;
    _searchQuery = '';
    fetchAll();
  }
}
