import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../core/utils/currency_formatter.dart';

class CreateProjectScreen extends StatefulWidget {
  final VoidCallback? onProjectCreated;

  const CreateProjectScreen({super.key, this.onProjectCreated});

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  int _currentStep = 0;
  bool _isSubmitting = false;

  // ── STEP 1: Basic Information ──
  String _projectType = 'OFF_PLAN'; // OFF_PLAN or PAY_SMALL_SMALL
  String _propertyCategory = 'TERRACE'; // TERRACE, DUPLEX, APARTMENT, LAND, COMMERCIAL
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _completionCtrl = TextEditingController(text: 'Q4 2027');
  String _selectedState = 'Lagos';
  final String _selectedCity = 'Lekki';

  // ── STEP 2: Pricing & Payment Terms ──
  final _unitNameCtrl = TextEditingController(text: '3 Bedroom Luxury Terrace');
  final _unitPriceCtrl = TextEditingController(text: '75000000');
  final _unitDepositCtrl = TextEditingController(text: '15000000');
  final _unitCountCtrl = TextEditingController(text: '8');
  final _durationMonthsCtrl = TextEditingController(text: '12');
  final _possessionThresholdCtrl = TextEditingController(text: '50');

  // ── STEP 3: Media & Title Documents ──
  final List<Map<String, dynamic>> _projectWalkthroughs = [
    {
      'mediaType': 'Aerial Drone Walkthrough (YouTube / MP4)',
      'titleCtrl': TextEditingController(text: 'Aerial Drone Site Walkthrough'),
      'urlCtrl': TextEditingController(),
    },
    {
      'mediaType': 'Matterport 3D Virtual Tour / 360°',
      'titleCtrl': TextEditingController(text: '3D Virtual Matterport Tour'),
      'urlCtrl': TextEditingController(),
    },
  ];

  final List<Map<String, dynamic>> _projectDocuments = [
    {
      'type': 'Certificate of Occupancy (C of O)',
      'numberCtrl': TextEditingController(),
      'urlCtrl': TextEditingController(),
    },
    {
      'type': 'Registered Cadastral Survey Plan',
      'numberCtrl': TextEditingController(),
      'urlCtrl': TextEditingController(),
    },
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _addressCtrl.dispose();
    _areaCtrl.dispose();
    _completionCtrl.dispose();
    _unitNameCtrl.dispose();
    _unitPriceCtrl.dispose();
    _unitDepositCtrl.dispose();
    _unitCountCtrl.dispose();
    _durationMonthsCtrl.dispose();
    _possessionThresholdCtrl.dispose();
    for (var w in _projectWalkthroughs) {
      (w['titleCtrl'] as TextEditingController).dispose();
      (w['urlCtrl'] as TextEditingController).dispose();
    }
    for (var d in _projectDocuments) {
      (d['numberCtrl'] as TextEditingController).dispose();
      (d['urlCtrl'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  bool _validateCurrentStep() {
    if (_currentStep == 0) {
      if (_nameCtrl.text.trim().isEmpty) {
        _showToast('Please enter the project / package name');
        return false;
      }
      if (_addressCtrl.text.trim().isEmpty) {
        _showToast('Please enter the site physical address');
        return false;
      }
      return true;
    } else if (_currentStep == 1) {
      if (_unitNameCtrl.text.trim().isEmpty) {
        _showToast('Please enter the unit or package name');
        return false;
      }
      final price = double.tryParse(_unitPriceCtrl.text.replaceAll(',', '').trim());
      if (price == null || price <= 0) {
        _showToast('Please enter a valid property price');
        return false;
      }
      final deposit = double.tryParse(_unitDepositCtrl.text.replaceAll(',', '').trim());
      if (deposit == null || deposit <= 0 || deposit > price) {
        _showToast('Please enter a valid initial deposit (cannot exceed price)');
        return false;
      }
      final units = int.tryParse(_unitCountCtrl.text.trim());
      if (units == null || units <= 0) {
        _showToast('Please specify the total available units');
        return false;
      }
      return true;
    }
    return true;
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _handleNext() {
    if (!_validateCurrentStep()) return;
    if (_currentStep < 3) {
      setState(() => _currentStep++);
    } else {
      _publishProject();
    }
  }

  void _handleBack() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _publishProject() async {
    final isPaySmallSmall = _projectType == 'PAY_SMALL_SMALL';
    final price = double.tryParse(_unitPriceCtrl.text.replaceAll(',', '').trim()) ?? 50000000;
    final deposit = double.tryParse(_unitDepositCtrl.text.replaceAll(',', '').trim()) ?? 15000000;
    final count = int.tryParse(_unitCountCtrl.text.trim()) ?? 4;
    final tenor = int.tryParse(_durationMonthsCtrl.text.trim()) ?? (isPaySmallSmall ? 24 : 12);
    final monthly = (price - deposit) > 0 ? (price - deposit) / (tenor > 0 ? tenor : 1) : 0.0;

    final validWalkthroughs = _projectWalkthroughs
        .where((w) => (w['urlCtrl'] as TextEditingController).text.trim().isNotEmpty)
        .toList();
    final firstVideo = validWalkthroughs.isNotEmpty
        ? (validWalkthroughs.first['urlCtrl'] as TextEditingController).text.trim()
        : null;
    final first3dTour = validWalkthroughs.length > 1
        ? (validWalkthroughs[1]['urlCtrl'] as TextEditingController).text.trim()
        : null;

    final formattedDocs = _projectDocuments.map((d) {
      final docType = d['type'] as String;
      final numText = (d['numberCtrl'] as TextEditingController).text.trim();
      final urlText = (d['urlCtrl'] as TextEditingController).text.trim();
      final docSlug = docType.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');

      return {
        'documentType': docType,
        'fileName': numText.isNotEmpty ? '$docType ($numText)' : docType,
        'documentNumber': numText.isNotEmpty ? numText : 'VERIFIED-DOC-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        'fileUrl': urlText.isNotEmpty ? urlText : 'https://vault.hometrust.ng/docs/$docSlug.pdf',
      };
    }).toList();

    final payload = {
      'projectType': _projectType,
      'propertyCategory': _propertyCategory,
      'name': _nameCtrl.text.trim(),
      'description': _descCtrl.text.trim().isNotEmpty
          ? _descCtrl.text.trim()
          : (isPaySmallSmall
              ? 'Serviced plots & residential packages with structured monthly instalment plans.'
              : 'Luxury off-plan development protected by Hometrust Milestone Escrow.'),
      'state': _selectedState,
      'city': _selectedCity,
      'area': _areaCtrl.text.trim().isNotEmpty ? _areaCtrl.text.trim() : 'Lekki',
      'address': _addressCtrl.text.trim(),
      'expectedCompletion': isPaySmallSmall ? 'Immediate / Ready' : _completionCtrl.text.trim(),
      'videoUrl': firstVideo,
      'virtualTourUrl': first3dTour,
      'mediaWalkthroughs': validWalkthroughs.map((w) => {
        'mediaType': w['mediaType'],
        'title': (w['titleCtrl'] as TextEditingController).text.trim(),
        'url': (w['urlCtrl'] as TextEditingController).text.trim(),
      }).toList(),
      'documentUrls': formattedDocs,
      'units': [
        {
          'unitType': _unitNameCtrl.text.trim(),
          'name': _unitNameCtrl.text.trim(),
          'size': _propertyCategory == 'LAND' ? '500 SQM Serviced Plot' : '220 SQM Living Area',
          'bedrooms': _propertyCategory == 'LAND' ? 0 : 3,
          'bathrooms': _propertyCategory == 'LAND' ? 0 : 3,
          'price': price,
          'initialDeposit': deposit,
          'durationMonths': tenor,
          'monthlyInstalment': monthly,
          'totalUnits': count,
        },
      ],
    };

    setState(() => _isSubmitting = true);

    try {
      await ApiClient.post('/developers/projects', payload);
      if (mounted) {
        widget.onProjectCreated?.call();
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '🎉 ${isPaySmallSmall ? "Pay-Small-Small Package" : "Off-Plan Project"} published successfully!',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showToast(e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 20),
          onPressed: _handleBack,
        ),
        title: Text(
          _projectType == 'PAY_SMALL_SMALL' ? 'Create Pay-Small-Small' : 'Create Off-Plan Project',
          style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 16),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF059669).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Step ${_currentStep + 1} of 4',
              style: const TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.w900, fontSize: 12),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── PROGRESS STEP INDICATOR BAR ──
          _buildProgressStepper(),

          // ── STEP CONTENT AREA ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: _buildCurrentStepContent(),
            ),
          ),

          // ── BOTTOM NAVIGATION ACTIONS ──
          _buildBottomNavigationBar(),
        ],
      ),
    );
  }

  Widget _buildProgressStepper() {
    final steps = [
      {'title': 'Basic Info', 'icon': Icons.apartment_rounded},
      {'title': 'Pricing', 'icon': Icons.payments_outlined},
      {'title': 'Docs & Media', 'icon': Icons.folder_shared_outlined},
      {'title': 'Review', 'icon': Icons.fact_check_outlined},
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: List.generate(steps.length, (idx) {
          final isCompleted = idx < _currentStep;
          final isCurrent = idx == _currentStep;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: isCompleted
                                  ? const Color(0xFF059669)
                                  : isCurrent
                                      ? const Color(0xFF0F172A)
                                      : const Color(0xFFE2E8F0),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: isCompleted
                                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                                  : Text(
                                      '${idx + 1}',
                                      style: TextStyle(
                                        color: isCurrent ? Colors.white : const Color(0xFF64748B),
                                        fontWeight: FontWeight.w900,
                                        fontSize: 12,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        steps[idx]['title'] as String,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                          color: isCurrent
                              ? const Color(0xFF0F172A)
                              : isCompleted
                                  ? const Color(0xFF059669)
                                  : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
                if (idx < steps.length - 1)
                  Container(
                    width: 20,
                    height: 2,
                    color: isCompleted ? const Color(0xFF059669) : const Color(0xFFE2E8F0),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep1BasicInfo();
      case 1:
        return _buildStep2PricingTerms();
      case 2:
        return _buildStep3LegalMedia();
      case 3:
        return _buildStep4ReviewPublish();
      default:
        return const SizedBox();
    }
  }

  // ══════════════════════════════════════════════════════════════════
  // STEP 1: PROJECT TYPE & BASIC DETAILS
  // ══════════════════════════════════════════════════════════════════
  Widget _buildStep1BasicInfo() {
    final isPaySmallSmall = _projectType == 'PAY_SMALL_SMALL';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'Project Category & Location',
          subtitle: 'Choose your development model and specify the project’s geographical location.',
        ),
        const SizedBox(height: 16),

        // ── PROJECT TYPE TOGGLE ──
        const Text('DEVELOPMENT MODEL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B))),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _projectType = 'OFF_PLAN';
                      _unitNameCtrl.text = '3 Bedroom Luxury Terrace';
                      _completionCtrl.text = 'Q4 2027';
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: !isPaySmallSmall ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: !isPaySmallSmall
                          ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4, offset: const Offset(0, 2))]
                          : null,
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Text('🏗️ Off-Plan Development', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: !isPaySmallSmall ? const Color(0xFF0F172A) : const Color(0xFF64748B))),
                          const SizedBox(height: 2),
                          Text('Stage-by-stage escrow', style: TextStyle(fontSize: 10, color: !isPaySmallSmall ? const Color(0xFF0284C7) : const Color(0xFF94A3B8))),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _projectType = 'PAY_SMALL_SMALL';
                      _unitNameCtrl.text = '500 SQM Serviced Plot (or Finished Unit)';
                      _completionCtrl.text = 'Immediate / Ready';
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isPaySmallSmall ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: isPaySmallSmall
                          ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4, offset: const Offset(0, 2))]
                          : null,
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Text('💳 Pay Small Small', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: isPaySmallSmall ? const Color(0xFF059669) : const Color(0xFF64748B))),
                          const SizedBox(height: 2),
                          Text('Structured monthly plans', style: TextStyle(fontSize: 10, color: isPaySmallSmall ? const Color(0xFF059669) : const Color(0xFF94A3B8))),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Property Category
        DropdownButtonFormField<String>(
          value: _propertyCategory,
          decoration: InputDecoration(
            labelText: 'Property Classification',
            prefixIcon: const Icon(Icons.category_outlined, color: Color(0xFF0284C7), size: 20),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          ),
          items: const [
            DropdownMenuItem(value: 'TERRACE', child: Text('Terrace / Townhouse')),
            DropdownMenuItem(value: 'DUPLEX', child: Text('Semi-Detached / Fully Detached Duplex')),
            DropdownMenuItem(value: 'APARTMENT', child: Text('Apartment / Penthouse')),
            DropdownMenuItem(value: 'LAND', child: Text('Serviced Land / Residential Plots')),
            DropdownMenuItem(value: 'COMMERCIAL', child: Text('Commercial Space / Office')),
          ],
          onChanged: (val) => setState(() => _propertyCategory = val!),
        ),
        const SizedBox(height: 14),

        // Project Name
        TextField(
          controller: _nameCtrl,
          decoration: InputDecoration(
            labelText: isPaySmallSmall ? 'Package / Estate Name (e.g. Greenwood Park Plots)' : 'Project Name (e.g. Ikate Luxury Heights)',
            hintText: 'e.g. Sapphire Crest Residences',
            prefixIcon: const Icon(Icons.apartment_rounded, color: Color(0xFF0284C7), size: 20),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          ),
        ),
        const SizedBox(height: 14),

        // State & Area
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedState,
                decoration: InputDecoration(
                  labelText: 'State',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                ),
                items: ['Lagos', 'Abuja FCT', 'Rivers', 'Ogun', 'Oyo', 'Enugu', 'Anambra', 'Delta', 'Edo', 'Kaduna']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13))))
                    .toList(),
                onChanged: (val) => setState(() => _selectedState = val!),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _areaCtrl,
                decoration: InputDecoration(
                  labelText: 'Area / District',
                  hintText: 'e.g. Lekki Phase 1',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Exact Physical Address
        TextField(
          controller: _addressCtrl,
          decoration: InputDecoration(
            labelText: 'Exact Site Address',
            hintText: 'e.g. Plot 14, Freedom Way, Lekki',
            prefixIcon: const Icon(Icons.location_on_outlined, color: Color(0xFF0284C7), size: 20),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          ),
        ),
        const SizedBox(height: 14),

        // Estimated Completion
        if (!isPaySmallSmall) ...[
          TextField(
            controller: _completionCtrl,
            decoration: InputDecoration(
              labelText: 'Estimated Completion Date',
              hintText: 'e.g. Q4 2027',
              prefixIcon: const Icon(Icons.calendar_month_outlined, color: Color(0xFF0284C7), size: 20),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Project Description & Amenities
        TextField(
          controller: _descCtrl,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Project Description & Infrastructure',
            hintText: 'Describe access roads, 24/7 power, drainage, CCTV security, swimming pool, and community amenities...',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // STEP 2: PRICING, UNITS & INSTALMENT TERMS
  // ══════════════════════════════════════════════════════════════════
  Widget _buildStep2PricingTerms() {
    final isPaySmallSmall = _projectType == 'PAY_SMALL_SMALL';

    final price = double.tryParse(_unitPriceCtrl.text.replaceAll(',', '').trim()) ?? 0;
    final deposit = double.tryParse(_unitDepositCtrl.text.replaceAll(',', '').trim()) ?? 0;
    final tenor = int.tryParse(_durationMonthsCtrl.text.trim()) ?? (isPaySmallSmall ? 24 : 12);
    final balance = (price - deposit) > 0 ? (price - deposit) : 0.0;
    final monthly = tenor > 0 ? balance / tenor : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'Pricing, Inventory & Instalment Terms',
          subtitle: 'Define the selling price, required initial deposit, monthly instalment tenor, and total units.',
        ),
        const SizedBox(height: 16),

        // Live Financial Preview Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('CALCULATED MONTHLY INSTALMENT', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('$tenor Months Tenor', style: const TextStyle(color: Color(0xFF34D399), fontSize: 10, fontWeight: FontWeight.w900)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${CurrencyFormatter.format(monthly)} / month',
                style: const TextStyle(color: Color(0xFF34D399), fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const Divider(color: Color(0xFF334155), height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Price', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                      Text(CurrencyFormatter.format(price), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Initial Deposit', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                      Text(CurrencyFormatter.format(deposit), style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.w800, fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Unit / Package Name
        TextField(
          controller: _unitNameCtrl,
          decoration: InputDecoration(
            labelText: isPaySmallSmall ? 'Package / Plot Name' : 'Unit Type Name (e.g. 4 Bedroom Terrace)',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          ),
        ),
        const SizedBox(height: 14),

        // Total Price & Deposit
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _unitPriceCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Total Price (₦)',
                  prefixText: '₦ ',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _unitDepositCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Initial Deposit (₦)',
                  prefixText: '₦ ',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Tenor & Unit Count
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _durationMonthsCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Tenor (Months)',
                  hintText: isPaySmallSmall ? '24' : '12',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _unitCountCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: isPaySmallSmall ? 'Available Plots' : 'Available Units',
                  hintText: '8',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                ),
              ),
            ),
          ],
        ),

        // Pay Small Small Possession Threshold
        if (isPaySmallSmall) ...[
          const SizedBox(height: 14),
          TextField(
            controller: _possessionThresholdCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Possession / Demarcation Threshold (%)',
              hintText: '50',
              suffixText: '% paid into escrow',
              helperText: 'Buyer receives physical plot allocation or key handover once this % is cleared into escrow.',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            ),
          ),
        ],
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // STEP 3: TITLE INSTRUMENTS & MEDIA WALKTHROUGHS
  // ══════════════════════════════════════════════════════════════════
  Widget _buildStep3LegalMedia() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'Legal Title Documents & Virtual Media',
          subtitle: 'Attach title deeds and upload virtual drone walkthroughs to build instant buyer trust.',
        ),
        const SizedBox(height: 16),

        // ── MEDIA WALKTHROUGHS ──
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Virtual Walkthroughs (${_projectWalkthroughs.length})',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
            ),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _projectWalkthroughs.add({
                    'mediaType': 'Aerial Drone Walkthrough (YouTube / MP4)',
                    'titleCtrl': TextEditingController(text: 'Drone Walkthrough ${_projectWalkthroughs.length + 1}'),
                    'urlCtrl': TextEditingController(),
                  });
                });
              },
              icon: const Icon(Icons.add_circle_outline_rounded, size: 16, color: Color(0xFF0284C7)),
              label: const Text('Add Media', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0284C7))),
            ),
          ],
        ),
        const SizedBox(height: 8),

        ..._projectWalkthroughs.asMap().entries.map((entry) {
          final idx = entry.key;
          final walk = entry.value;
          final mediaType = walk['mediaType'] as String;
          final urlCtrl = walk['urlCtrl'] as TextEditingController;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('Media #${idx + 1}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF0284C7))),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: mediaType,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Aerial Drone Walkthrough (YouTube / MP4)', child: Text('Aerial Drone Video', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: 'Matterport 3D Virtual Tour / 360°', child: Text('Matterport 3D Tour', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: 'Architectural 3D Render Video', child: Text('3D Architectural Video', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: 'Live Site Progress Stream', child: Text('Live Progress Stream', style: TextStyle(fontSize: 12))),
                        ],
                        onChanged: (val) => setState(() => walk['mediaType'] = val!),
                      ),
                    ),
                    if (_projectWalkthroughs.length > 1) ...[
                      const SizedBox(width: 6),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                        onPressed: () => setState(() => _projectWalkthroughs.removeAt(idx)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: urlCtrl,
                  decoration: InputDecoration(
                    labelText: 'Media Stream / YouTube / Matterport Link',
                    hintText: 'https://...',
                    isDense: true,
                    prefixIcon: const Icon(Icons.link_rounded, size: 18, color: Color(0xFF0284C7)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          );
        }),

        const SizedBox(height: 18),

        // ── TITLE & LEGAL DOCUMENTS ──
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Title & Legal Instruments (${_projectDocuments.length})',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
            ),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _projectDocuments.add({
                    'type': 'Approved Architectural / Building Plan',
                    'numberCtrl': TextEditingController(),
                    'urlCtrl': TextEditingController(),
                  });
                });
              },
              icon: const Icon(Icons.add_circle_outline_rounded, size: 16, color: Color(0xFF059669)),
              label: const Text('Add Document', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF059669))),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Documents are encrypted in the Hometrust Vault with anti-forgery watermarking.',
          style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 10),

        ..._projectDocuments.asMap().entries.map((entry) {
          final idx = entry.key;
          final doc = entry.value;
          final docType = doc['type'] as String;
          final numCtrl = doc['numberCtrl'] as TextEditingController;
          final urlCtrl = doc['urlCtrl'] as TextEditingController;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('Doc #${idx + 1}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF059669))),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: docType,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Certificate of Occupancy (C of O)', child: Text('Certificate of Occupancy (C of O)', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: 'Governor’s Consent', child: Text('Governor’s Consent', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: 'Registered Cadastral Survey Plan', child: Text('Registered Survey Plan', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: 'Approved Architectural / Building Plan', child: Text('Approved Building Plan', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: 'Gazette / Excision Record', child: Text('Gazette / Excision', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: 'Deed of Assignment / Conveyance', child: Text('Deed of Assignment', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: 'Layout Approval & Allocation Letter', child: Text('Layout / Allocation Letter', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: 'Environmental Impact Assessment (EIA)', child: Text('EIA Assessment', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: 'Custom Legal Title Instrument', child: Text('Custom Legal Document', style: TextStyle(fontSize: 12))),
                        ],
                        onChanged: (val) => setState(() => doc['type'] = val!),
                      ),
                    ),
                    if (_projectDocuments.length > 1) ...[
                      const SizedBox(width: 6),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                        onPressed: () => setState(() => _projectDocuments.removeAt(idx)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: numCtrl,
                  decoration: InputDecoration(
                    labelText: 'Registration / Plan / Gazette Number',
                    hintText: 'e.g. Vol 2024 Page 45 / OG/2023/118',
                    isDense: true,
                    prefixIcon: const Icon(Icons.tag_rounded, size: 18, color: Color(0xFF059669)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: urlCtrl,
                  decoration: InputDecoration(
                    labelText: 'Document Vault URL / File Reference',
                    hintText: 'https://vault.hometrust.ng/docs/...',
                    isDense: true,
                    prefixIcon: const Icon(Icons.cloud_upload_outlined, size: 18, color: Color(0xFF059669)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // STEP 4: REVIEW & PUBLISH
  // ══════════════════════════════════════════════════════════════════
  Widget _buildStep4ReviewPublish() {
    final isPaySmallSmall = _projectType == 'PAY_SMALL_SMALL';
    final price = double.tryParse(_unitPriceCtrl.text.replaceAll(',', '').trim()) ?? 0;
    final deposit = double.tryParse(_unitDepositCtrl.text.replaceAll(',', '').trim()) ?? 0;
    final tenor = int.tryParse(_durationMonthsCtrl.text.trim()) ?? (isPaySmallSmall ? 24 : 12);
    final count = int.tryParse(_unitCountCtrl.text.trim()) ?? 1;
    final monthly = tenor > 0 ? (price - deposit) / tenor : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'Review & Publish Listing',
          subtitle: 'Carefully verify your project information before publishing to the Hometrust marketplace.',
        ),
        const SizedBox(height: 16),

        // Project Summary Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isPaySmallSmall ? const Color(0xFF059669).withValues(alpha: 0.1) : const Color(0xFF0284C7).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isPaySmallSmall ? '💳 PAY SMALL SMALL' : '🏗️ OFF-PLAN MILESTONE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: isPaySmallSmall ? const Color(0xFF059669) : const Color(0xFF0284C7),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(_propertyCategory, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF475569))),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Text(
                _nameCtrl.text.trim().isNotEmpty ? _nameCtrl.text.trim() : 'Untitled Project',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, color: Color(0xFF64748B), size: 14),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${_addressCtrl.text.trim()}, ${_areaCtrl.text.trim()}, $_selectedState',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ),
                ],
              ),

              const Divider(height: 24, color: Color(0xFFF1F5F9)),

              // Key Stats Grid
              Row(
                children: [
                  Expanded(
                    child: _buildReviewStat(
                      label: 'TOTAL PRICE',
                      value: CurrencyFormatter.format(price),
                      valueColor: const Color(0xFF0F172A),
                    ),
                  ),
                  Expanded(
                    child: _buildReviewStat(
                      label: 'INITIAL DEPOSIT',
                      value: CurrencyFormatter.format(deposit),
                      valueColor: const Color(0xFF0284C7),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildReviewStat(
                      label: 'MONTHLY INSTALMENT',
                      value: '${CurrencyFormatter.format(monthly)} / mo',
                      valueColor: const Color(0xFF059669),
                    ),
                  ),
                  Expanded(
                    child: _buildReviewStat(
                      label: 'INVENTORY AVAILABLE',
                      value: '$count Units/Plots',
                      valueColor: const Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Compliance & Legal Attachments Review Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFECFDF5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFA7F3D0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.security_rounded, color: Color(0xFF059669), size: 18),
                  SizedBox(width: 8),
                  Text('Hometrust Escrow Protection Guarantee', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF065F46), fontSize: 13)),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                '• All buyer tranches will be paid directly into the dedicated Hometrust Escrow Vault.\n'
                '• Tranche disbursements are unlocked stage-by-stage only after registered engineer inspection.\n'
                '• Title documents are watermarked with active buyer identity to eliminate fraud.',
                style: TextStyle(fontSize: 11.5, color: Color(0xFF047857), height: 1.45),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewStat({required String label, required String value, required Color valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8), fontWeight: FontWeight.w800, letterSpacing: 0.5)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: valueColor)),
      ],
    );
  }

  Widget _buildSectionHeader({required String title, required String subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4)),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    final isLastStep = _currentStep == 3;
    final isPaySmallSmall = _projectType == 'PAY_SMALL_SMALL';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFF1F5F9))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_currentStep > 0) ...[
              Expanded(
                flex: 2,
                child: OutlinedButton.icon(
                  onPressed: _isSubmitting ? null : _handleBack,
                  icon: const Icon(Icons.arrow_back_rounded, size: 16),
                  label: const Text('Back', style: TextStyle(fontWeight: FontWeight.w800)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              flex: 3,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _handleNext,
                icon: _isSubmitting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Icon(isLastStep ? Icons.rocket_launch_rounded : Icons.arrow_forward_rounded, size: 18),
                label: Text(
                  _isSubmitting
                      ? 'Publishing Project...'
                      : isLastStep
                          ? (isPaySmallSmall ? 'Publish Pay-Small-Small' : 'Publish Off-Plan Project')
                          : 'Continue to Step ${_currentStep + 2}',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isLastStep
                      ? const Color(0xFF059669)
                      : const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
