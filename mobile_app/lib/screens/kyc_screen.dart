import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/constants/colors.dart';
import '../core/network/api_client.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';

class KycScreen extends StatefulWidget {
  const KycScreen({super.key});

  @override
  State<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends State<KycScreen> {
  int _currentStepIndex = 0; // 0: Identity, 1: Address, 2: Review

  // Individual KYC Form Keys & Controllers
  final _step1FormKey = GlobalKey<FormState>();
  final _step2FormKey = GlobalKey<FormState>();

  final _ninCtrl = TextEditingController();
  final _bvnCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  DateTime? _selectedDob;
  String _selectedGender = 'Male';
  String _selectedIdType = 'NIN Slip / Card';

  // Structured Residential Address Controllers
  final _streetCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  String _selectedState = 'Lagos';

  // Corporate KYB Controllers
  final _companyNameCtrl = TextEditingController();
  final _cacCtrl = TextEditingController();
  final _tinCtrl = TextEditingController();
  final _officeAddressCtrl = TextEditingController();
  final _directorBvnCtrl = TextEditingController();

  bool _agreeToTerms = true;
  bool _isLoading = false;
  String? _error;
  bool _isSuccess = false;
  Map<String, dynamic>? _generatedAccount;
  String _loadingMessage = '';

  static const List<String> _nigerianStates = [
    'Abia', 'Adamawa', 'Akwa Ibom', 'Anambra', 'Bauchi', 'Bayelsa', 'Benue', 'Borno',
    'Cross River', 'Delta', 'Ebonyi', 'Edo', 'Ekiti', 'Enugu', 'Federal Capital Territory (FCT)',
    'Gombe', 'Imo', 'Jigawa', 'Kaduna', 'Kano', 'Katsina', 'Kebbi', 'Kogi', 'Kwara',
    'Lagos', 'Nasarawa', 'Niger', 'Ogun', 'Ondo', 'Osun', 'Oyo', 'Plateau', 'Rivers',
    'Sokoto', 'Taraba', 'Yobe', 'Zamfara'
  ];

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;
    if (user != null) {
      if (user.role == 'DEVELOPER') {
        _companyNameCtrl.text = user.developerCompanyName?.isNotEmpty == true
            ? user.developerCompanyName!
            : '${user.firstName} ${user.lastName} Developments Ltd';
      }
    }
  }

  @override
  void dispose() {
    _ninCtrl.dispose();
    _bvnCtrl.dispose();
    _dobCtrl.dispose();
    _streetCtrl.dispose();
    _cityCtrl.dispose();
    _companyNameCtrl.dispose();
    _cacCtrl.dispose();
    _tinCtrl.dispose();
    _officeAddressCtrl.dispose();
    _directorBvnCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final eighteenYearsAgo = DateTime(now.year - 18, now.month, now.day);
    final initial = _selectedDob ?? DateTime(1995, 6, 15);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(eighteenYearsAgo) ? eighteenYearsAgo : initial,
      firstDate: DateTime(1940, 1, 1),
      lastDate: eighteenYearsAgo,
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'SELECT YOUR DATE OF BIRTH',
      cancelText: 'CANCEL',
      confirmText: 'SET DATE',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF059669),
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDob = picked;
        _dobCtrl.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  void _nextStep(bool isDeveloper) {
    if (_currentStepIndex == 0) {
      if (!_step1FormKey.currentState!.validate()) return;
      if (!isDeveloper && _selectedDob == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select your Date of Birth'),
            backgroundColor: Color(0xFFDC2626),
          ),
        );
        return;
      }
      setState(() => _currentStepIndex = 1);
    } else if (_currentStepIndex == 1) {
      if (!_step2FormKey.currentState!.validate()) return;
      setState(() => _currentStepIndex = 2);
    }
  }

  void _prevStep() {
    if (_currentStepIndex > 0) {
      setState(() => _currentStepIndex -= 1);
    }
  }

  Future<void> _submitVerification(bool isDeveloper) async {
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the verification terms to proceed'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _loadingMessage = 'Connecting to National Identity & CAC Gateway...';
    });

    try {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        setState(() {
          _loadingMessage = isDeveloper
              ? 'Verifying CAC Registration (${_cacCtrl.text.trim()}) & Director Records...'
              : 'Verifying National Identity (NIN & BVN) via Prembly IdentityPass...';
        });
      }

      final fullAddress = '${_streetCtrl.text.trim()}, ${_cityCtrl.text.trim()}, $_selectedState'.trim();

      final payload = isDeveloper
          ? {
              'verificationType': 'CORPORATE_KYB',
              'companyName': _companyNameCtrl.text.trim(),
              'cacNumber': _cacCtrl.text.trim(),
              'tinNumber': _tinCtrl.text.trim(),
              'officeAddress': _officeAddressCtrl.text.trim().isNotEmpty ? _officeAddressCtrl.text.trim() : fullAddress,
              'streetAddress': _streetCtrl.text.trim(),
              'city': _cityCtrl.text.trim(),
              'state': _selectedState,
              'directorBvn': _directorBvnCtrl.text.trim(),
            }
          : {
              'verificationType': 'INDIVIDUAL_KYC',
              'idType': _selectedIdType,
              'nin': _ninCtrl.text.trim(),
              'bvn': _bvnCtrl.text.trim(),
              'dob': _dobCtrl.text.trim(),
              'gender': _selectedGender,
              'streetAddress': _streetCtrl.text.trim(),
              'city': _cityCtrl.text.trim(),
              'state': _selectedState,
              'residentialAddress': fullAddress,
            };

      final res = await ApiClient.post('/banking/kyc/auto-verify', payload);

      if (mounted) {
        setState(() {
          _loadingMessage = 'Activating Dedicated Escrow NUBAN Account...';
        });
      }

      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        final auth = Provider.of<AuthProvider>(context, listen: false);
        await auth.refreshUser();
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isSuccess = true;
          _generatedAccount = res != null && res is Map ? (res['virtualAccount'] ?? res) : null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;
    final isDeveloper = user?.role == 'DEVELOPER';

    // 1. MUST SIGN IN FIRST GATE
    if (!auth.isAuthenticated || user == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text(
            'Identity Verification',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Color(0xFF0F172A)),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF0F172A)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.lock_person_rounded, color: Color(0xFF059669), size: 36),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Account Required',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please sign in or register an account before proceeding with identity verification (KYC/KYB).',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text(
                      'Sign In / Register',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          isDeveloper ? 'Corporate Verification (KYB)' : 'Identity Verification (KYC)',
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Color(0xFF0F172A)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isSuccess
          ? _buildSuccessView(user)
          : _isLoading
              ? _buildLoadingView()
              : Column(
                  children: [
                    // Step Progress Header
                    _buildStepProgressHeader(isDeveloper),

                    // Scrollable Step Content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_error != null) ...[
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFFCA5A5)),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _error!,
                                        style: const TextStyle(fontSize: 12, color: Color(0xFF991B1B), fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            if (_currentStepIndex == 0)
                              _buildStep1Identity(isDeveloper, user)
                            else if (_currentStepIndex == 1)
                              _buildStep2Address(isDeveloper)
                            else
                              _buildStep3Review(isDeveloper, user),
                          ],
                        ),
                      ),
                    ),

                    // Bottom Navigation Buttons
                    _buildBottomButtons(isDeveloper),
                  ],
                ),
    );
  }

  // ── STEP PROGRESS HEADER ──
  Widget _buildStepProgressHeader(bool isDeveloper) {
    final steps = [
      {'title': isDeveloper ? 'KYB Info' : 'Identity', 'icon': Icons.badge_outlined},
      {'title': 'Address', 'icon': Icons.home_outlined},
      {'title': 'Review', 'icon': Icons.verified_user_outlined},
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Column(
        children: [
          Row(
            children: List.generate(steps.length * 2 - 1, (index) {
              if (index.isOdd) {
                final stepBefore = index ~/ 2;
                final isCompleted = _currentStepIndex > stepBefore;
                return Expanded(
                  child: Container(
                    height: 2.5,
                    color: isCompleted ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
                  ),
                );
              }

              final stepIdx = index ~/ 2;
              final isActive = _currentStepIndex == stepIdx;
              final isPassed = _currentStepIndex > stepIdx;

              return Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isPassed
                      ? const Color(0xFF10B981)
                      : isActive
                          ? const Color(0xFF0F172A)
                          : const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isActive ? const Color(0xFF10B981) : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: isPassed
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                      : Text(
                          '${stepIdx + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: isActive ? Colors.white : const Color(0xFF94A3B8),
                          ),
                        ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Step ${_currentStepIndex + 1} of 3: ${steps[_currentStepIndex]['title']}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
              Text(
                '${((_currentStepIndex + 1) / 3 * 100).toInt()}% Complete',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF10B981)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── STEP 1: PERSONAL & IDENTITY ──
  Widget _buildStep1Identity(bool isDeveloper, dynamic user) {
    return Form(
      key: _step1FormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.security_rounded, color: Color(0xFF059669), size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isDeveloper
                        ? 'Corporate verification certifies your development entity and unlocks escrow milestone withdrawals.'
                        : 'Official verification generates your Dedicated Hometrust NUBAN for secure property purchases.',
                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF065F46), fontWeight: FontWeight.w600, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          if (!isDeveloper) ...[
            // Full Name (Pre-filled / display)
            const Text('Full Legal Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_outline_rounded, size: 18, color: Color(0xFF64748B)),
                  const SizedBox(width: 8),
                  Text(
                    '${user.firstName} ${user.lastName}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Date of Birth with Calendar Picker
            const Text('Date of Birth', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
            const SizedBox(height: 6),
            InkWell(
              onTap: _pickDateOfBirth,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_month_rounded, size: 18, color: Color(0xFF059669)),
                        const SizedBox(width: 10),
                        Text(
                          _selectedDob != null
                              ? '${_selectedDob!.day.toString().padLeft(2, '0')}/${_selectedDob!.month.toString().padLeft(2, '0')}/${_selectedDob!.year}'
                              : 'Tap to select Year, Month & Day',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: _selectedDob != null ? FontWeight.w700 : FontWeight.w500,
                            color: _selectedDob != null ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                    const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF64748B)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Gender Selector
            const Text('Gender', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
            const SizedBox(height: 6),
            Row(
              children: ['Male', 'Female'].map((gender) {
                final isSelected = _selectedGender == gender;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedGender = gender),
                    child: Container(
                      margin: EdgeInsets.only(right: gender == 'Male' ? 8 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFECFDF5) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF059669) : const Color(0xFFCBD5E1),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          gender,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected ? const Color(0xFF059669) : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // ID Document Type
            const Text('Primary ID Document', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _selectedIdType,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
              ),
              items: ['NIN Slip / Card', 'Bank Verification Number (BVN)', "International Passport", "Driver's License", "Voter's Card"]
                  .map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 13))))
                  .toList(),
              onChanged: (val) => setState(() => _selectedIdType = val!),
            ),
            const SizedBox(height: 16),

            // 11-digit NIN
            const Text('National Identity Number (NIN)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
            const SizedBox(height: 6),
            TextFormField(
              controller: _ninCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(11)],
              validator: (val) {
                if (val == null || val.trim().length != 11) return 'NIN must be exactly 11 digits';
                return null;
              },
              decoration: InputDecoration(
                hintText: 'Enter 11-digit NIN (e.g. 12345678901)',
                hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.badge_outlined, size: 20, color: Color(0xFF059669)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
              ),
            ),
            const SizedBox(height: 16),

            // 11-digit BVN
            const Text('Bank Verification Number (BVN)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
            const SizedBox(height: 6),
            TextFormField(
              controller: _bvnCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(11)],
              validator: (val) {
                if (val == null || val.trim().length != 11) return 'BVN must be exactly 11 digits';
                return null;
              },
              decoration: InputDecoration(
                hintText: 'Enter 11-digit BVN (e.g. 22234567890)',
                hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.account_balance_outlined, size: 20, color: Color(0xFF0284C7)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
              ),
            ),
          ] else ...[
            // Corporate Developer KYB Fields
            const Text('Registered Company Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
            const SizedBox(height: 6),
            TextFormField(
              controller: _companyNameCtrl,
              validator: (val) => val == null || val.trim().isEmpty ? 'Company name is required' : null,
              decoration: InputDecoration(
                hintText: 'e.g. Landmark Real Estate Developments Ltd',
                hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.business_rounded, size: 20, color: Color(0xFF059669)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
              ),
            ),
            const SizedBox(height: 16),

            const Text('CAC Registration / RC Number', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
            const SizedBox(height: 6),
            TextFormField(
              controller: _cacCtrl,
              validator: (val) => val == null || val.trim().isEmpty ? 'CAC RC Number is required' : null,
              decoration: InputDecoration(
                hintText: 'e.g. RC-1849204 or BN-392819',
                hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.fact_check_outlined, size: 20, color: Color(0xFF059669)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
              ),
            ),
            const SizedBox(height: 16),

            const Text('Tax Identification Number (TIN) (Optional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
            const SizedBox(height: 6),
            TextFormField(
              controller: _tinCtrl,
              decoration: InputDecoration(
                hintText: 'e.g. 23819204-0001',
                hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.receipt_long_outlined, size: 20, color: Color(0xFF64748B)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
              ),
            ),
            const SizedBox(height: 16),

            const Text('Managing Director BVN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
            const SizedBox(height: 6),
            TextFormField(
              controller: _directorBvnCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(11)],
              validator: (val) => val == null || val.trim().length != 11 ? 'Director BVN must be 11 digits' : null,
              decoration: InputDecoration(
                hintText: 'Enter Director 11-digit BVN',
                hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.person_pin_rounded, size: 20, color: Color(0xFF0284C7)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── STEP 2: STRUCTURED RESIDENTIAL / OFFICE ADDRESS ──
  Widget _buildStep2Address(bool isDeveloper) {
    return Form(
      key: _step2FormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F9FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFBAE6FD)),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on_rounded, color: Color(0xFF0284C7), size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isDeveloper
                        ? 'Enter your registered corporate office address for verification and statutory records.'
                        : 'Structured address verification ensures regulatory compliance and delivery of legal deeds.',
                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF075985), fontWeight: FontWeight.w600, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Street Address
          Text(
            isDeveloper ? 'Corporate Office Street Address' : 'Street Address',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _streetCtrl,
            maxLines: 2,
            validator: (val) {
              if (val == null || val.trim().length < 5) return 'Please enter your street address and house number';
              return null;
            },
            decoration: InputDecoration(
              hintText: 'e.g. No 4, Ehomes Close, Zartech Area, Oluyole',
              hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              filled: true,
              fillColor: Colors.white,
              prefixIcon: const Icon(Icons.home_work_outlined, size: 20, color: Color(0xFF059669)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
            ),
          ),
          const SizedBox(height: 16),

          // City / LGA / Landmark
          const Text('City / LGA / Landmark', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
          const SizedBox(height: 6),
          TextFormField(
            controller: _cityCtrl,
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'City or LGA is required';
              return null;
            },
            decoration: InputDecoration(
              hintText: 'e.g. Ibadan, Lekki Phase 1, Ikeja, or Port Harcourt',
              hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              filled: true,
              fillColor: Colors.white,
              prefixIcon: const Icon(Icons.location_city_outlined, size: 20, color: Color(0xFF64748B)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
            ),
          ),
          const SizedBox(height: 16),

          // State of Residence Dropdown
          const Text('State of Residence', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _selectedState,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
              prefixIcon: const Icon(Icons.map_outlined, size: 20, color: Color(0xFF059669)),
            ),
            items: _nigerianStates
                .map((state) => DropdownMenuItem(value: state, child: Text(state, style: const TextStyle(fontSize: 13))))
                .toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedState = val);
            },
          ),
          const SizedBox(height: 20),

          // Address Summary preview
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF64748B)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This structured address will be used to calibrate your Dedicated NUBAN account profile.',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── STEP 3: REVIEW & LIVE VERIFICATION ──
  Widget _buildStep3Review(bool isDeveloper, dynamic user) {
    final fullAddress = '${_streetCtrl.text.trim()}, ${_cityCtrl.text.trim()}, $_selectedState';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Verification Summary',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 4),
        const Text(
          'Please review your details before initiating live verification.',
          style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 16),

        // Summary Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            children: [
              if (!isDeveloper) ...[
                _buildSummaryRow('Legal Name', '${user.firstName} ${user.lastName}'),
                _buildSummaryRow('Date of Birth', _selectedDob != null ? '${_selectedDob!.day}/${_selectedDob!.month}/${_selectedDob!.year}' : 'Not set'),
                _buildSummaryRow('Gender', _selectedGender),
                _buildSummaryRow('NIN', _ninCtrl.text.trim().isNotEmpty ? '${_ninCtrl.text.trim().substring(0, 3)}•••••${_ninCtrl.text.trim().substring(8)}' : 'N/A'),
                _buildSummaryRow('BVN', _bvnCtrl.text.trim().isNotEmpty ? '${_bvnCtrl.text.trim().substring(0, 3)}•••••${_bvnCtrl.text.trim().substring(8)}' : 'N/A'),
              ] else ...[
                _buildSummaryRow('Company', _companyNameCtrl.text.trim()),
                _buildSummaryRow('CAC / RC', _cacCtrl.text.trim()),
                _buildSummaryRow('Director BVN', _directorBvnCtrl.text.trim().isNotEmpty ? '${_directorBvnCtrl.text.trim().substring(0, 3)}•••••' : 'N/A'),
              ],
              const Divider(height: 20),
              _buildSummaryRow('Address', fullAddress),
              _buildSummaryRow('Account To Issue', 'Hometrust Dedicated Escrow NUBAN'),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Terms & Disclaimer
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: _agreeToTerms,
                activeColor: const Color(0xFF059669),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                onChanged: (val) => setState(() => _agreeToTerms = val ?? false),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _agreeToTerms = !_agreeToTerms),
                  child: const Text(
                    'I certify that the identity information and address provided are accurate and authorize Hometrust to verify these details via national verification gateways and issue my Dedicated Escrow Account.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF475569), height: 1.4),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
            ),
          ),
        ],
      ),
    );
  }

  // ── BOTTOM BUTTONS ──
  Widget _buildBottomButtons(bool isDeveloper) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Row(
        children: [
          if (_currentStepIndex > 0) ...[
            Expanded(
              flex: 1,
              child: OutlinedButton(
                onPressed: _prevStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Back', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF475569))),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () {
                if (_currentStepIndex < 2) {
                  _nextStep(isDeveloper);
                } else {
                  _submitVerification(isDeveloper);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text(
                _currentStepIndex < 2
                    ? 'Continue to ${_currentStepIndex == 0 ? "Address" : "Review"}'
                    : isDeveloper
                        ? 'Submit & Verify KYB'
                        : 'Submit & Verify Identity (KYC)',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── LOADING STATE ──
  Widget _buildLoadingView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Color(0xFF059669), strokeWidth: 3),
            const SizedBox(height: 24),
            Text(
              _loadingMessage.isNotEmpty ? _loadingMessage : 'Processing Live Verification...',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A), height: 1.4),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please hold on while we validate your credentials and configure your Dedicated Escrow Account.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }

  // ── SUCCESS STATE ──
  Widget _buildSuccessView(dynamic user) {
    final accountNum = _generatedAccount?['accountNumber'] ?? user.virtualAccountNumber ?? '---';
    final bankName = _generatedAccount?['bankName'] ?? user.virtualBankName ?? 'Providus Bank';
    final accountName = _generatedAccount?['accountName'] ?? user.virtualAccountName ?? '${user.firstName} ${user.lastName}';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF10B981), width: 2),
              ),
              child: const Center(
                child: Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 42),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Verification Successful! 🛡️',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 6),
            const Text(
              'Your identity has been verified. Your dedicated Hometrust Virtual Escrow Account is now active and ready for secure property transactions.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
            ),
            const SizedBox(height: 24),

            // Virtual Account Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'HOMETRUST DEDICATED NUBAN',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.8),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'ACTIVE & VERIFIED',
                          style: TextStyle(color: Color(0xFF34D399), fontSize: 9, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        accountNum,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, color: Color(0xFF38BDF8), size: 20),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: accountNum));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Account number copied to clipboard!')),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        bankName,
                        style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      Expanded(
                        child: Text(
                          accountName,
                          textAlign: TextAlign.end,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text(
                  'Proceed to Home Screen',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
