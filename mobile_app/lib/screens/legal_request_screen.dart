import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/constants/colors.dart';
import '../core/network/api_client.dart';
import '../core/utils/currency_formatter.dart';
import '../providers/auth_provider.dart';
import '../widgets/persistent_bottom_nav.dart';

class LegalRequestScreen extends StatefulWidget {
  const LegalRequestScreen({super.key});

  @override
  State<LegalRequestScreen> createState() => _LegalRequestScreenState();
}

class _LegalRequestScreenState extends State<LegalRequestScreen> {
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _reqCtrl = TextEditingController();

  // Physical Delivery Controllers
  final _recipientNameCtrl = TextEditingController();
  final _recipientPhoneCtrl = TextEditingController();
  final _deliveryAddressCtrl = TextEditingController();
  final _landmarkCtrl = TextEditingController();

  String _selectedCategory = 'SALE_AGREEMENT';
  String _deliveryOption = 'DIGITAL_ONLY'; // DIGITAL_ONLY, LOCAL_COURIER, INTERSTATE_COURIER, INTERNATIONAL
  double _feePercentage = 3.0;
  double _agreedAmount = 0.0;
  double _calculatedDraftFee = 0.0;

  bool _loadingQuote = false;
  bool _submitting = false;

  Map<String, dynamic>? _virtualAccount;
  bool _loadingAccount = true;

  final List<Map<String, String>> _categories = [
    {
      'id': 'SALE_AGREEMENT',
      'name': 'Contract of Sale',
      'desc': 'Legally binding contract setting purchase price, milestones, escrow terms & covenants.'
    },
    {
      'id': 'DEED',
      'name': 'Deed of Assignment',
      'desc': 'Official conveyancing deed transferring absolute title & root of ownership to buyer.'
    },
    {
      'id': 'TENANCY_AGREEMENT',
      'name': 'Residential Tenancy Agreement',
      'desc': 'Standardized tenancy contract with rent terms, service charge & dispute clauses.'
    },
    {
      'id': 'LEASE',
      'name': 'Commercial Lease Agreement',
      'desc': 'Long-term commercial lease with indexation, fit-out covenants & sublease rules.'
    },
    {
      'id': 'DEVELOPMENT_AGREEMENT',
      'name': 'Joint Venture / Development Contract',
      'desc': 'Comprehensive developer-landowner sharing ratio, milestones & exit covenants.'
    },
    {
      'id': 'POWER_OF_ATTORNEY',
      'name': 'Irrevocable Power of Attorney',
      'desc': 'Authorized legal appointment authorizing agent or purchaser to manage/perfect title.'
    },
  ];

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

  double get _totalFee => _calculatedDraftFee + _deliveryFee;

  @override
  void initState() {
    super.initState();
    _fetchFeeSettings();
    final auth = Provider.of<AuthProvider>(context, listen: false);
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
    _fetchUserVirtualAccount();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _reqCtrl.dispose();
    _recipientNameCtrl.dispose();
    _recipientPhoneCtrl.dispose();
    _deliveryAddressCtrl.dispose();
    _landmarkCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchFeeSettings() async {
    try {
      final res = await ApiClient.get('/legal/fee-quote?agreedAmount=0');
      if (res != null && res is Map<String, dynamic> && res['data'] != null && res['data']['feePercentage'] != null) {
        setState(() {
          _feePercentage = (res['data']['feePercentage'] as num).toDouble();
        });
      }
    } catch (_) {
      // Default to 3.0%
    }
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

  void _onAmountChanged(String val) {
    final clean = val.replaceAll(',', '').replaceAll('₦', '').trim();
    final amount = double.tryParse(clean) ?? 0.0;
    setState(() {
      _agreedAmount = amount;
      _calculatedDraftFee = (_agreedAmount * _feePercentage) / 100.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final walletBalance = (_virtualAccount?['balance'] as num?)?.toDouble() ?? 0.0;
    final isSufficient = walletBalance >= _totalFee && _totalFee > 0;

    return Scaffold(
      bottomNavigationBar: const PersistentBottomNav(),
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        title: const Text(
          'Legal Document Preparation',
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 16),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. BANNER: 3% STATUTORY LEGAL DRAFTING FEE
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF10B981).withOpacity(0.5)),
                        ),
                        child: Text(
                          '${_feePercentage.toStringAsFixed(1)}% STATUTORY LEGAL FEE',
                          style: const TextStyle(color: Color(0xFF34D399), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.gavel_rounded, color: Color(0xFF34D399), size: 18),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Certified Solicitor Drafting & Sealed Deeds',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Statutory 3% conveyancing drafting fee paid atomically via your Hometrust Dedicated Wallet. Receive digital PDF and embossed hard copies.',
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12, height: 1.4),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 2. FORM CONTAINER
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // A. Select Agreement Category
                  const Text('1. SELECT AGREEMENT CATEGORY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCategory,
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF475569)),
                        items: _categories.map((cat) {
                          return DropdownMenuItem<String>(
                            value: cat['id'],
                            child: Text(cat['name']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedCategory = val);
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // B. Title / Subject of Agreement
                  const Text('2. AGREEMENT TITLE / PROPERTY DESCRIPTION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _titleCtrl,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      hintText: 'e.g. Deed of Assignment for Plot 14, Oceanview Estate',
                      hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // C. Agreed Transaction Consideration Amount
                  const Text('3. TOTAL TRANSACTION AMOUNT (₦)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _amountCtrl,
                    keyboardType: TextInputType.number,
                    onChanged: _onAmountChanged,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      prefixText: '₦ ',
                      prefixStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF059669)),
                      hintText: 'e.g. 50,000,000',
                      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // D. LIVE CALCULATION SUMMARY CARD
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Agreed Transaction Value:', style: TextStyle(fontSize: 12, color: Color(0xFF065F46), fontWeight: FontWeight.w600)),
                            Text(
                              _agreedAmount > 0 ? CurrencyFormatter.format(_agreedAmount) : '₦0.00',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF065F46)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Hometrust Legal Drafting (${_feePercentage.toStringAsFixed(1)}%):', style: const TextStyle(fontSize: 13, color: Color(0xFF065F46), fontWeight: FontWeight.w700)),
                            Text(
                              _calculatedDraftFee > 0 ? CurrencyFormatter.format(_calculatedDraftFee) : '₦0.00',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF059669)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // E. DELIVERY METHOD SELECTOR
                  const Text('4. DELIVERY & FULFILLMENT FORMAT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5)),
                  const SizedBox(height: 8),
                  Column(
                    children: [
                      _buildDeliveryRadioTile(
                        id: 'DIGITAL_ONLY',
                        title: 'Digital Vault Only (Instant & Free)',
                        subtitle: 'Download high-res execution PDF directly in-app.',
                        price: '₦0',
                        icon: Icons.picture_as_pdf_rounded,
                      ),
                      const SizedBox(height: 8),
                      _buildDeliveryRadioTile(
                        id: 'LOCAL_COURIER',
                        title: 'Local Doorstep Delivery (Lagos / Abuja)',
                        subtitle: 'Sealed tamper-evident pouch + wet-signed deeds (24hr dispatch).',
                        price: '+₦4,500',
                        icon: Icons.local_shipping_rounded,
                      ),
                      const SizedBox(height: 8),
                      _buildDeliveryRadioTile(
                        id: 'INTERSTATE_COURIER',
                        title: 'Nationwide Inter-State Delivery (36 States)',
                        subtitle: 'Tracked courier with OTP handover (48–72 hrs).',
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
                              Icon(Icons.location_on_rounded, size: 16, color: Color(0xFF059669)),
                              SizedBox(width: 6),
                              Text(
                                'Delivery Address for Sealed Hard Copies',
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF059669)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _recipientNameCtrl,
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
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: 'Recipient Phone Number (For Dispatch Rider)',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              isDense: true,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _deliveryAddressCtrl,
                            maxLines: 2,
                            decoration: InputDecoration(
                              labelText: 'Complete Street Address, Area & City',
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
                              labelText: 'Nearest Landmark / Building Gate (Optional)',
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

                  const SizedBox(height: 20),

                  // F. Instructions & Specific Clauses
                  const Text('5. PARTIES DETAILS & SPECIFIC CLAUSES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _reqCtrl,
                    maxLines: 4,
                    style: const TextStyle(fontSize: 12.5, color: Color(0xFF1E293B)),
                    decoration: InputDecoration(
                      hintText: 'Include names of buyer & seller, payment installment terms, possession handover dates, covenants, boundary beacon numbers...',
                      hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.all(14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // G. DEDICATED WALLET BALANCE PREVIEW
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF475569), size: 18),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Dedicated Wallet Balance', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                                Text(
                                  _loadingAccount ? 'Loading...' : CurrencyFormatter.format(walletBalance),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: isSufficient ? const Color(0xFF059669) : const Color(0xFFDC2626),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (!isSufficient && _totalFee > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Low Balance',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFFDC2626)),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // SUBMIT & PAY BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _handlePaymentAndSubmission,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Text(
                        _submitting
                            ? 'Processing Legal Order...'
                            : _totalFee > 0
                                ? 'Pay & Submit Order (${CurrencyFormatter.format(_totalFee)})'
                                : 'Enter Transaction Amount to Proceed',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
          color: isSelected ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF059669) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: isSelected ? const Color(0xFF059669) : const Color(0xFF64748B), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: isSelected ? const Color(0xFF059669) : const Color(0xFF0F172A),
                          ),
                          overflow: TextOverflow.visible,
                          softWrap: true,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF059669) : const Color(0xFF475569),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          price,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(subtitle, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handlePaymentAndSubmission() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a property or agreement title')),
      );
      return;
    }

    if (_agreedAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the agreed transaction amount in Naira')),
      );
      return;
    }

    if (_reqCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide parties details or instructions')),
      );
      return;
    }

    if (_deliveryOption != 'DIGITAL_ONLY' && _deliveryAddressCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a complete physical delivery address')),
      );
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

    try {
      // 1. Create Legal Request
      final res = await ApiClient.post('/legal', {
        'documentCategory': _selectedCategory,
        'title': _titleCtrl.text.trim(),
        'requirements': _reqCtrl.text.trim(),
        'agreedAmount': _agreedAmount,
        'deliveryOption': _deliveryOption,
        'deliveryAddress': deliveryAddressJson,
        'deliveryFee': _deliveryFee,
      });

      final requestId = res['data']?['id'] ?? res['id'];
      if (requestId == null) {
        throw Exception('Failed to initialize legal request');
      }

      // 2. Pay via Dedicated Wallet
      await ApiClient.post('/legal/$requestId/pay-wallet', {});

      setState(() => _submitting = false);

      if (mounted) {
        _showSuccessDialog(res['data'] ?? res);
      }
    } catch (e) {
      setState(() => _submitting = false);
      
      final errStr = e.toString();
      if (errStr.contains('INSUFFICIENT_FUNDS') || errStr.contains('402')) {
        _showInsufficientFundsModal();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Notice: $e')),
        );
      }
    }
  }

  void _showInsufficientFundsModal() {
    final walletBalance = (_virtualAccount?['balance'] as num?)?.toDouble() ?? 0.0;
    final accNum = _virtualAccount?['accountNumber'] ?? 'Generate via Profile';
    final bankName = _virtualAccount?['bankName'] ?? 'Providus Bank / Wema Bank';
    final accName = _virtualAccount?['accountName'] ?? 'Hometrust Dedicated Account';

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
              'Your Hometrust dedicated wallet has ${CurrencyFormatter.format(walletBalance)}, but this legal drafting & delivery order requires ${CurrencyFormatter.format(_totalFee)}.',
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
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await _fetchUserVirtualAccount();
                      _handlePaymentAndSubmission();
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

  void _showSuccessDialog(Map<String, dynamic> req) {
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
            Text('Legal Order Placed', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order Reference: ${req['requestCode'] ?? 'HT-LEG-ORD'}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              isPhysical
                  ? 'Your legal drafting fee of ${CurrencyFormatter.format(_totalFee)} was successfully paid from your dedicated wallet.\n\nOnce signed and sealed, hard copies will be dispatched to your doorstep with courier PIN verification.'
                  : 'Your legal drafting fee of ${CurrencyFormatter.format(_totalFee)} was successfully paid from your dedicated wallet.\n\nOur certified solicitors are drafting your documents.',
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569), height: 1.4),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
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
