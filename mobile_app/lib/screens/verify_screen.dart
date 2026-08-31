import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/constants/colors.dart';
import '../core/network/api_client.dart';
import '../core/utils/currency_formatter.dart';
import '../providers/verification_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/persistent_bottom_nav.dart';
import 'login_screen.dart';
import 'wallet_screen.dart';

class VerifyScreen extends StatefulWidget {
  const VerifyScreen({super.key});

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _propNameCtrl = TextEditingController();
  final _propAddressCtrl = TextEditingController(text: '');
  final _cityCtrl = TextEditingController(text: 'Lekki');
  final _stateCtrl = TextEditingController(text: 'Lagos');

  // Physical Delivery Controllers
  final _recipientNameCtrl = TextEditingController();
  final _recipientPhoneCtrl = TextEditingController();
  final _deliveryAddressCtrl = TextEditingController();
  final _landmarkCtrl = TextEditingController();

  String _selectedDocType = 'C_OF_O';
  String _urgency = 'STANDARD'; // STANDARD (₦25,000) or EXPRESS (₦45,000)
  String _deliveryOption = 'DIGITAL_ONLY'; // DIGITAL_ONLY, LOCAL_COURIER, INTERSTATE_COURIER, INTERNATIONAL
  bool _submitting = false;

  // Wallet info
  Map<String, dynamic>? _virtualAccount;
  bool _loadingAccount = true;

  // File picker state
  Uint8List? _pickedFileBytes;
  String? _pickedFileName;

  final List<Map<String, String>> _docTypes = [
    {'id': 'C_OF_O', 'name': 'Certificate of Occupancy (C of O)'},
    {'id': 'DEED_OF_ASSIGNMENT', 'name': 'Deed of Assignment'},
    {'id': 'SURVEY_PLAN', 'name': 'Registered Survey Plan'},
    {'id': 'GOVERNORS_CONSENT', 'name': "Governor's Consent"},
    {'id': 'GAZETTE', 'name': 'Government Gazette / Excision'},
    {'id': 'POWER_OF_ATTORNEY', 'name': 'Irrevocable Power of Attorney'},
  ];

  double get _urgencyFee => _urgency == 'EXPRESS' ? 45000.0 : 25000.0;

  double get _deliveryFee {
    switch (_deliveryOption) {
      case 'LOCAL_COURIER':
        return 4500.0;
      case 'INTERSTATE_COURIER':
        return 8500.0;
      case 'INTERNATIONAL':
        return 45000.0;
      default:
        return 0.0;
    }
  }

  double get _totalFee => _urgencyFee + _deliveryFee;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.isAuthenticated) {
        // 1. Hydrate immediately from auth.user
        if (auth.user != null) {
          _recipientNameCtrl.text = auth.user!.fullName;
          _recipientPhoneCtrl.text = auth.user!.phone ?? '';
          if (auth.user!.virtualAccountNumber != null) {
            _virtualAccount = {
              'accountNumber': auth.user!.virtualAccountNumber,
              'bankName': auth.user!.virtualBankName ?? 'Providus Bank / Wema Bank',
              'accountName': auth.user!.virtualAccountName ?? 'Hometrust / ${auth.user!.fullName}',
              'balance': auth.user!.virtualAccountBalance,
            };
          }
        }
        Provider.of<VerificationProvider>(context, listen: false).fetchMyRequests();
        _fetchUserVirtualAccount();
      }
    });
  }

  Future<void> _fetchUserVirtualAccount() async {
    setState(() => _loadingAccount = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      final res = await ApiClient.get('/banking/my-account');
      if (mounted && res != null) {
        final Map<String, dynamic>? data = (res is Map<String, dynamic> && res.containsKey('data'))
            ? (res['data'] as Map<String, dynamic>?)
            : (res is Map<String, dynamic> ? res : null);

        setState(() {
          _virtualAccount = data ?? _virtualAccount;
          _loadingAccount = false;
        });
        auth.refreshUser();
      } else {
        if (mounted) setState(() => _loadingAccount = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loadingAccount = false);
    }
  }

  @override
  void dispose() {
    _propNameCtrl.dispose();
    _propAddressCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _recipientNameCtrl.dispose();
    _recipientPhoneCtrl.dispose();
    _deliveryAddressCtrl.dispose();
    _landmarkCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        withData: true,
      );
      if (result != null && result.files.single.bytes != null) {
        setState(() {
          _pickedFileBytes = result.files.single.bytes;
          _pickedFileName = result.files.single.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not pick file: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final verifProvider = Provider.of<VerificationProvider>(context);
    final walletBalance = (_virtualAccount?['balance'] as num?)?.toDouble() ?? 0.0;
    final isSufficient = walletBalance >= _totalFee;

    return Scaffold(
      bottomNavigationBar: const PersistentBottomNav(),
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Document Verification Vault',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 17),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Trust Header Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.shield_outlined, color: AppColors.accentGoldLight, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'HOMETRUST LEGAL & REGISTRY CHECK',
                        style: TextStyle(color: AppColors.accentGoldLight, fontWeight: FontWeight.w800, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Verify Title & Land Documents Before Paying',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Cadastral registry searches, beacon coordinate checks, and certified physical delivery right to your doorstep.',
                    style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // New Verification Request Form
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Submit New Document for Verification',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 16),

                    // Document Type Dropdown
                    const Text('Document Type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedDocType,
                          isExpanded: true,
                          items: _docTypes.map((d) {
                            return DropdownMenuItem(
                              value: d['id'],
                              child: Text(d['name']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedDocType = val);
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),
                    const Text('Property Name / Plot ID', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _propNameCtrl,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      decoration: InputDecoration(
                        hintText: 'e.g. Plot 42, Block B, Lekki Phase 1',
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.cardBorder)),
                        isDense: true,
                      ),
                    ),

                    const SizedBox(height: 14),
                    const Text('Property Address', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _propAddressCtrl,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      decoration: InputDecoration(
                        hintText: 'e.g. Admiralty Way, Lekki',
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.cardBorder)),
                        isDense: true,
                      ),
                    ),

                    const SizedBox(height: 18),
                    // URGENCY TIER SELECTOR
                    const Text('Verification Urgency Tier', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Standard Tier
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _urgency = 'STANDARD'),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _urgency == 'STANDARD' ? const Color(0xFFECFDF5) : AppColors.background,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _urgency == 'STANDARD' ? AppColors.primary : AppColors.cardBorder,
                                  width: _urgency == 'STANDARD' ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Standard', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                                      if (_urgency == 'STANDARD')
                                        const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 16),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  const Text('3–5 Days', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                  const SizedBox(height: 6),
                                  const Text('₦25,000', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.primary)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Express Tier
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _urgency = 'EXPRESS'),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _urgency == 'EXPRESS' ? const Color(0xFFFEF3C7) : AppColors.background,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _urgency == 'EXPRESS' ? const Color(0xFFD97706) : AppColors.cardBorder,
                                  width: _urgency == 'EXPRESS' ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Express ⚡', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF92400E))),
                                      if (_urgency == 'EXPRESS')
                                        const Icon(Icons.check_circle_rounded, color: Color(0xFFD97706), size: 16),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  const Text('24–48 Hours', style: TextStyle(fontSize: 11, color: Color(0xFF78350F))),
                                  const SizedBox(height: 6),
                                  const Text('₦45,000', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFFB45309))),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),
                    // DELIVERY METHOD SELECTOR
                    const Text('Delivery & Fulfillment Format', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Column(
                      children: [
                        _buildDeliveryRadioTile(
                          id: 'DIGITAL_ONLY',
                          title: 'Digital Vault Only (Instant & Free)',
                          subtitle: 'Download signed & stamped PDF report directly in-app.',
                          price: '₦0',
                          icon: Icons.picture_as_pdf_rounded,
                        ),
                        const SizedBox(height: 8),
                        _buildDeliveryRadioTile(
                          id: 'LOCAL_COURIER',
                          title: 'Local Doorstep Delivery (Lagos / Abuja)',
                          subtitle: 'Sealed tamper-evident pouch + wet-stamped hard copies (24hr dispatch).',
                          price: '+₦4,500',
                          icon: Icons.local_shipping_rounded,
                        ),
                        const SizedBox(height: 8),
                        _buildDeliveryRadioTile(
                          id: 'INTERSTATE_COURIER',
                          title: 'Nationwide Inter-State Delivery (36 States)',
                          subtitle: 'Tracked ground/air courier with OTP handover (48–72 hrs).',
                          price: '+₦8,500',
                          icon: Icons.markunread_mailbox_rounded,
                        ),
                        const SizedBox(height: 8),
                        _buildDeliveryRadioTile(
                          id: 'INTERNATIONAL',
                          title: 'International Diaspora Delivery (UK / US / CA / UAE)',
                          subtitle: 'DHL Express Worldwide priority courier (3–5 business days).',
                          price: '+₦45,000',
                          icon: Icons.flight_takeoff_rounded,
                        ),
                      ],
                    ),

                    if (_deliveryOption != 'DIGITAL_ONLY') ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.location_on_rounded, size: 16, color: AppColors.primary),
                                SizedBox(width: 6),
                                Text(
                                  'Doorstep Delivery Address & Contact',
                                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppColors.primary),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _recipientNameCtrl,
                              validator: (v) => (_deliveryOption != 'DIGITAL_ONLY' && (v == null || v.trim().isEmpty)) ? 'Recipient name required' : null,
                              decoration: InputDecoration(
                                labelText: 'Recipient Full Name',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                isDense: true,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _recipientPhoneCtrl,
                              validator: (v) => (_deliveryOption != 'DIGITAL_ONLY' && (v == null || v.trim().isEmpty)) ? 'Phone number required' : null,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                labelText: 'Recipient Phone Number (For Rider Handover)',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                isDense: true,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _deliveryAddressCtrl,
                              validator: (v) => (_deliveryOption != 'DIGITAL_ONLY' && (v == null || v.trim().isEmpty)) ? 'Delivery address required' : null,
                              maxLines: 2,
                              decoration: InputDecoration(
                                labelText: 'Complete Delivery Street Address & City',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                isDense: true,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _landmarkCtrl,
                              decoration: InputDecoration(
                                labelText: 'Nearest Landmark / Gate Description (Optional)',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                isDense: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 18),
                    // File Upload
                    const Text('Attach Title Document', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: _pickFile,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _pickedFileName != null ? AppColors.emeraldBg : AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _pickedFileName != null ? AppColors.emeraldBorder : AppColors.primary.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              _pickedFileName != null ? Icons.check_circle_rounded : Icons.upload_file_rounded,
                              color: _pickedFileName != null ? AppColors.emeraldText : AppColors.primary,
                              size: 28,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _pickedFileName ?? 'Tap to Select Document File',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _pickedFileName != null ? AppColors.emeraldText : AppColors.textPrimary,
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _pickedFileName != null ? 'Tap to change file' : 'PDF, JPG, PNG — Max 50MB — Encrypted vault',
                              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),
                    // Dedicated Wallet Balance Preview
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.account_balance_wallet_rounded, size: 18, color: Color(0xFF64748B)),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Dedicated Wallet Balance', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                                  Text(
                                    _loadingAccount ? 'Loading...' : CurrencyFormatter.format(walletBalance),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                      color: isSufficient ? const Color(0xFF059669) : const Color(0xFFDC2626),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isSufficient ? const Color(0xFFECFDF5) : const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isSufficient ? 'Sufficient' : 'Top-Up Needed',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: isSufficient ? const Color(0xFF059669) : const Color(0xFFDC2626),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),
                    // Pay & Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : () => _handleSubmit(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: _submitting
                            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text(
                                'Pay & Submit (${CurrencyFormatter.format(_totalFee)})',
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Previous Verification Requests
            if (verifProvider.userRequests.isNotEmpty) ...[
              const SizedBox(height: 28),
              const Text(
                'My Verification Requests',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 12),
              ...verifProvider.userRequests.map((req) {
                final isVerified = req.status == 'VERIFIED' || req.status == 'COMPLETED';
                final isPaid = req.isPaid;
                final isPhysical = req.deliveryOption != 'DIGITAL_ONLY';

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(req.verificationCode, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary, fontSize: 13)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: req.urgency == 'EXPRESS' ? const Color(0xFFFEF3C7) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  req.urgency == 'EXPRESS' ? '⚡ EXPRESS' : 'STANDARD',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: req.urgency == 'EXPRESS' ? const Color(0xFF92400E) : const Color(0xFF475569),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isVerified ? AppColors.emeraldBg : AppColors.amberBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              req.status.replaceAll('_', ' '),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: isVerified ? AppColors.emeraldText : AppColors.amberText,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(req.propertyName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      Text('${req.propertyAddress}, ${req.city}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Fee: ${CurrencyFormatter.format(req.feeAmount.toDouble())}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isPaid ? const Color(0xFFECFDF5) : const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isPaid ? 'PAID ✅' : 'PAYMENT REQUIRED',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: isPaid ? const Color(0xFF059669) : const Color(0xFFDC2626)),
                            ),
                          ),
                        ],
                      ),

                      // Physical Delivery Badge & PIN Card
                      if (isPhysical) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFBBF7D0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.local_shipping_rounded, size: 15, color: Color(0xFF15803D)),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Doorstep Delivery: ${req.deliveryStatus}',
                                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Color(0xFF15803D)),
                                      ),
                                    ],
                                  ),
                                  if (req.deliveryOtp != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF15803D),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'PIN: ${req.deliveryOtp}',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10),
                                      ),
                                    ),
                                ],
                              ),
                              if (req.waybillNumber != null && req.waybillNumber!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Courier: ${req.courierPartner ?? 'Dispatch Partner'} | Waybill: ${req.waybillNumber}',
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF166534)),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],

                      if (req.finalFindings != null && req.finalFindings!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text('Findings: ${req.finalFindings}', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textSecondary)),
                      ],

                      if (!isPaid) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _handlePayUnpaidRequest(req.id),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF059669),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text('Pay Fee from Wallet (${CurrencyFormatter.format(req.feeAmount.toDouble())})', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ],

                      if (req.reportUrl != null && req.reportUrl!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final uri = Uri.parse(req.reportUrl!);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                              }
                            },
                            icon: const Icon(Icons.picture_as_pdf_rounded, size: 16, color: AppColors.primary),
                            label: const Text('Download Official Report PDF', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primary)),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryRadioTile({
    required String id,
    required String title,
    required String subtitle,
    required String price,
    required IconData icon,
  }) {
    final isSelected = _deliveryOption == id;
    return GestureDetector(
      onTap: () => setState(() => _deliveryOption = id),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0FDF4) : AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.cardBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : const Color(0xFF64748B), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: isSelected ? AppColors.primary : const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        price,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: isSelected ? AppColors.primary : const Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInsufficientFundsModal() {
    final walletBalance = (_virtualAccount?['balance'] as num?)?.toDouble() ?? 0.0;
    final accNum = _virtualAccount?['accountNumber'] ?? 'Generate via Profile';
    final bankName = _virtualAccount?['bankName'] ?? 'Providus Bank / Wema Bank';
    final accName = _virtualAccount?['accountName'] ?? 'Hometrust Dedicated Account';
    final needed = _totalFee - walletBalance;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: const [
                Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 24),
                SizedBox(width: 8),
                Text(
                  'Insufficient Dedicated Balance',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Your Hometrust dedicated wallet has ${CurrencyFormatter.format(walletBalance)}, but this verification fee is ${CurrencyFormatter.format(_totalFee)} (${CurrencyFormatter.format(needed)} top-up needed).\n\nTransfer to your dedicated account below to fund your wallet instantly:',
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569), height: 1.4),
            ),
            const SizedBox(height: 16),

            // Top-up Bank Account Details Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('TRANSFER TO YOUR DEDICATED ACCOUNT', style: TextStyle(color: Color(0xFF34D399), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        accNum,
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 2),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, color: Color(0xFF34D399), size: 20),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: accNum));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Account number copied to clipboard!')),
                          );
                        },
                      ),
                    ],
                  ),
                  Text(
                    bankName,
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    accName,
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen()));
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Go to Wallet', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await _fetchUserVirtualAccount();
                      _handleSubmit(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Refresh & Pay', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handlePayUnpaidRequest(String requestId) async {
    final verifProvider = Provider.of<VerificationProvider>(context, listen: false);
    final success = await verifProvider.payVerificationWithWallet(requestId);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment confirmed! Request is now in Legal Review.'), backgroundColor: AppColors.emeraldText),
        );
        _fetchUserVirtualAccount();
      } else {
        _showInsufficientFundsModal();
      }
    }
  }

  void _handleSubmit(BuildContext context) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isAuthenticated) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }

    if (_formKey.currentState?.validate() != true) return;

    if (_pickedFileBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please attach a title document file before submitting.'),
          backgroundColor: AppColors.roseText,
        ),
      );
      return;
    }

    final walletBalance = (_virtualAccount?['balance'] as num?)?.toDouble() ?? 0.0;
    if (walletBalance < _totalFee) {
      _showInsufficientFundsModal();
      return;
    }

    String? deliveryAddressJson;
    if (_deliveryOption != 'DIGITAL_ONLY') {
      deliveryAddressJson = jsonEncode({
        'recipientName': _recipientNameCtrl.text.trim(),
        'recipientPhone': _recipientPhoneCtrl.text.trim(),
        'streetAddress': _deliveryAddressCtrl.text.trim(),
        'landmark': _landmarkCtrl.text.trim(),
      });
    }

    setState(() => _submitting = true);
    final verifProvider = Provider.of<VerificationProvider>(context, listen: false);

    final req = await verifProvider.submitVerification(
      propertyName: _propNameCtrl.text.trim(),
      propertyAddress: _propAddressCtrl.text.trim(),
      state: _stateCtrl.text.trim(),
      city: _cityCtrl.text.trim(),
      documentType: _selectedDocType,
      urgency: _urgency,
      deliveryOption: _deliveryOption,
      deliveryAddress: deliveryAddressJson,
      deliveryFee: _deliveryFee,
      fileName: _pickedFileName ?? 'document.pdf',
      fileBytes: _pickedFileBytes,
    );

    if (req != null) {
      // Auto-pay with wallet
      final paid = await verifProvider.payVerificationWithWallet(req.id);
      await _fetchUserVirtualAccount();
      setState(() => _submitting = false);

      if (paid && mounted) {
        _showSuccessDialog(req);
        _propNameCtrl.clear();
        _propAddressCtrl.clear();
        setState(() {
          _pickedFileBytes = null;
          _pickedFileName = null;
        });
      } else if (!paid && mounted) {
        _showInsufficientFundsModal();
      }
    } else {
      setState(() => _submitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(verifProvider.errorMessage ?? 'Failed to submit verification request. Please check inputs.'),
            backgroundColor: AppColors.roseText,
          ),
        );
      }
    }
  }

  void _showSuccessDialog(dynamic req) {
    final isPhysical = _deliveryOption != 'DIGITAL_ONLY';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 24),
            SizedBox(width: 8),
            Text('Verification Order Placed', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Request Code: ${req.verificationCode}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.primary)),
            const SizedBox(height: 8),
            Text(
              isPhysical
                  ? 'Your verification fee of ${CurrencyFormatter.format(_totalFee)} was successfully paid from your dedicated wallet.\n\nOur legal team is conducting cadastral registry searches. Once complete, your certified report will be dispatched to your doorstep with OTP PIN protection.'
                  : 'Your verification fee of ${CurrencyFormatter.format(_totalFee)} was successfully paid from your dedicated wallet.\n\nOur legal team is conducting cadastral searches. Your certified report will be available in your Digital Vault within ${_urgency == "EXPRESS" ? "24–48 hours" : "3–5 days"}.',
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569), height: 1.4),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}
