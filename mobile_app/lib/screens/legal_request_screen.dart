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
  
  String _selectedCategory = 'SALE_AGREEMENT';
  double _feePercentage = 3.0;
  double _agreedAmount = 0.0;
  double _calculatedFee = 0.0;
  
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

  @override
  void initState() {
    super.initState();
    _fetchFeeSettings();
    _fetchUserVirtualAccount();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _reqCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchFeeSettings() async {
    try {
      final res = await ApiClient.get('/legal/fee-quote?agreedAmount=0');
      if (res['data'] != null && res['data']['feePercentage'] != null) {
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
    try {
      final res = await ApiClient.get('/banking/virtual-account');
      if (res['data'] != null) {
        setState(() {
          _virtualAccount = res['data'];
          _loadingAccount = false;
        });
      } else {
        setState(() => _loadingAccount = false);
      }
    } catch (_) {
      setState(() => _loadingAccount = false);
    }
  }

  void _onAmountChanged(String val) {
    final clean = val.replaceAll(',', '').replaceAll('₦', '').trim();
    final amount = double.tryParse(clean) ?? 0.0;
    setState(() {
      _agreedAmount = amount;
      _calculatedFee = (_agreedAmount * _feePercentage) / 100.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;
    final walletBalance = (_virtualAccount?['balance'] as num?)?.toDouble() ?? 0.0;
    final isSufficient = walletBalance >= _calculatedFee && _calculatedFee > 0;

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
                    color: Colors.black.withValues(alpha: 0.05),
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
                          color: const Color(0xFF10B981).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          '${_feePercentage.toStringAsFixed(1)}% STATUTORY LEGAL FEE',
                          style: const TextStyle(color: Color(0xFF34D399), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.gavel_rounded, color: Color(0xFF38BDF8), size: 18),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Certified Property Conveyancing & Title Drafting',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, height: 1.2),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'All agreements are drafted by licensed Nigerian real estate solicitors (NBA certified), incorporating full root-of-title vetting, indemnity clauses, and Governor\'s Consent covenants.',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5, height: 1.4),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 2. FORM FIELDS
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // A. Document Category
                  const Text('1. SELECT DOCUMENT CATEGORY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5)),
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
                        icon: const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF0F172A)),
                        items: _categories.map((c) {
                          return DropdownMenuItem(
                            value: c['id'],
                            child: Text(
                              c['name']!,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedCategory = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _categories.firstWhere((c) => c['id'] == _selectedCategory)['desc']!,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.3),
                  ),

                  const SizedBox(height: 20),

                  // B. Document / Property Title
                  const Text('2. PROPERTY OR AGREEMENT TITLE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _titleCtrl,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: 'e.g. 4-Bedroom Semi-Detached Duplex in Lekki Phase 1',
                      hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5)),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // C. Agreed Property Transaction Value (The Core Calculator!)
                  const Text('3. TOTAL AGREED TRANSACTION AMOUNT (₦)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5)),
                  const SizedBox(height: 4),
                  const Text('Enter the total property sale or contract price agreed upon between buyer and seller.', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _amountCtrl,
                    keyboardType: TextInputType.number,
                    onChanged: _onAmountChanged,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: 0.5),
                    decoration: InputDecoration(
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(left: 14, right: 8),
                        child: Center(
                          widthFactor: 0.0,
                          child: Text('₦', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF10B981))),
                        ),
                      ),
                      hintText: 'e.g. 30,000,000',
                      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5)),
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
                            Text('Hometrust Legal Fee (${_feePercentage.toStringAsFixed(1)}%):', style: const TextStyle(fontSize: 13, color: Color(0xFF065F46), fontWeight: FontWeight.w700)),
                            Text(
                              _calculatedFee > 0 ? CurrencyFormatter.format(_calculatedFee) : '₦0.00',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF059669)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // E. Instructions & Specific Clauses
                  const Text('4. PARTIES DETAILS & SPECIFIC CLAUSES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5)),
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
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5)),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // F. DEDICATED WALLET BALANCE PREVIEW
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
                        if (!isSufficient && _calculatedFee > 0)
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
                            : _calculatedFee > 0
                                ? 'Pay & Submit Order (${CurrencyFormatter.format(_calculatedFee)})'
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

    setState(() => _submitting = true);

    try {
      // 1. Create Legal Request
      final res = await ApiClient.post('/legal', {
        'documentCategory': _selectedCategory,
        'title': _titleCtrl.text.trim(),
        'requirements': _reqCtrl.text.trim(),
        'agreedAmount': _agreedAmount,
      });

      final requestId = res['data']?['id'] ?? res['id'];
      if (requestId == null) {
        throw Exception('Failed to initialize legal request');
      }

      // 2. Pay via Dedicated Wallet
      final payRes = await ApiClient.post('/legal/$requestId/pay-wallet', {});

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
              'Your Hometrust dedicated wallet has ${CurrencyFormatter.format(walletBalance)}, but this 3% legal drafting order requires ${CurrencyFormatter.format(_calculatedFee)}.',
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
              'Your legal drafting fee of ${CurrencyFormatter.format(_calculatedFee)} (3% of ${CurrencyFormatter.format(_agreedAmount)}) was successfully paid from your dedicated wallet.\n\nOur certified conveyancing solicitors are currently preparing your execution documents.',
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
