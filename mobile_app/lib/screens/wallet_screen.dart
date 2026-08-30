import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../core/constants/api_constants.dart';
import '../core/constants/colors.dart';
import '../core/network/api_client.dart';
import '../core/utils/currency_formatter.dart';
import '../providers/auth_provider.dart';
import '../widgets/persistent_bottom_nav.dart';
import 'kyc_screen.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  Map<String, dynamic>? _virtualAccount;
  List<dynamic> _transactions = [];
  bool _loadingAccount = false;
  bool _loadingTransactions = false;
  bool _hideBalance = false;
  String _selectedFilter = 'ALL'; // ALL, CREDIT, DEBIT

  // Withdrawal form controllers
  final _amountController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _accountNameController = TextEditingController();
  String _selectedBankCode = '044';
  String _selectedBankName = 'Access Bank';
  bool _isProcessingWithdrawal = false;

  final List<Map<String, String>> _nigerianBanks = [
    {'name': 'Access Bank', 'code': '044'},
    {'name': 'Guaranty Trust Bank (GTB)', 'code': '058'},
    {'name': 'Zenith Bank', 'code': '057'},
    {'name': 'United Bank for Africa (UBA)', 'code': '033'},
    {'name': 'First Bank of Nigeria', 'code': '011'},
    {'name': 'Wema Bank', 'code': '035'},
    {'name': 'FCMB (First City Monument Bank)', 'code': '214'},
    {'name': 'Fidelity Bank', 'code': '070'},
    {'name': 'Stanbic IBTC Bank', 'code': '221'},
    {'name': 'Sterling Bank', 'code': '232'},
    {'name': 'Union Bank of Nigeria', 'code': '032'},
    {'name': 'Providus Bank', 'code': '101'},
    {'name': 'Polaris Bank', 'code': '076'},
    {'name': 'Ecobank Nigeria', 'code': '050'},
    {'name': 'Keystone Bank', 'code': '082'},
    {'name': 'Jaiz Bank', 'code': '301'},
    {'name': 'Taj Bank', 'code': '302'},
    {'name': 'Lotus Bank', 'code': '303'},
    {'name': 'Parallex Bank', 'code': '526'},
    {'name': 'Premium Trust Bank', 'code': '105'},
    {'name': 'Signature Bank', 'code': '106'},
    {'name': 'Titan Trust Bank', 'code': '102'},
    {'name': 'Unity Bank', 'code': '215'},
    {'name': 'Kuda Microfinance Bank', 'code': '50211'},
    {'name': 'OPay (Paycom)', 'code': '999992'},
    {'name': 'PalmPay', 'code': '999991'},
    {'name': 'Moniepoint MFB', 'code': '50515'},
    {'name': 'FairMoney MFB', 'code': '51318'},
    {'name': 'Rubies MFB', 'code': '125'},
    {'name': 'Dot MFB', 'code': '50163'},
    {'name': 'Carbon MFB', 'code': '565'},
    {'name': 'VFD Microfinance Bank', 'code': '566'},
  ];

  @override
  void initState() {
    super.initState();
    _initWalletData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _accountNumberController.dispose();
    _accountNameController.dispose();
    super.dispose();
  }

  void _initWalletData() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isAuthenticated) return;

    // Instant local hydration from UserModel
    if (auth.user?.virtualAccountNumber != null) {
      _virtualAccount = {
        'accountNumber': auth.user!.virtualAccountNumber,
        'bankName': auth.user!.virtualBankName ?? 'Dedicated Escrow Bank',
        'accountName': auth.user!.virtualAccountName ?? 'Hometrust / ${auth.user!.fullName}',
        'balance': auth.user!.virtualAccountBalance,
      };
    }

    _fetchAccountAndTransactions();
  }

  Future<void> _fetchAccountAndTransactions() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isAuthenticated) return;

    setState(() {
      _loadingAccount = true;
      _loadingTransactions = true;
    });

    // 1. Fetch Account
    try {
      final accRes = await ApiClient.get('/banking/my-account');
      if (mounted && accRes != null) {
        setState(() {
          _virtualAccount = accRes;
          _loadingAccount = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingAccount = false);
    }

    // 2. Fetch Transactions
    try {
      final txRes = await ApiClient.get('/banking/my-transactions');
      if (mounted && txRes != null && txRes is List) {
        setState(() {
          _transactions = txRes;
          _loadingTransactions = false;
        });
      } else {
        if (mounted) setState(() => _loadingTransactions = false);
      }
    } catch (e) {
      if (mounted) setState(() => _loadingTransactions = false);
    }
  }

  void _copyToClipboard(String text, String label) {
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('$label copied to clipboard!'),
          ],
        ),
        backgroundColor: const Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showReceiveModal() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final accNum = _virtualAccount?['accountNumber'] ?? auth.user?.virtualAccountNumber ?? '';
    final bankName = _virtualAccount?['bankName'] ?? auth.user?.virtualBankName ?? 'Dedicated Escrow Bank';
    final accName = _virtualAccount?['accountName'] ?? auth.user?.virtualAccountName ?? 'Hometrust / ${auth.user?.fullName ?? 'Customer'}';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary, size: 20),
                    SizedBox(width: 8),
                    Text('Fund Escrow Wallet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                  ],
                ),
                IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            Text(
              'Transfer directly from any Nigerian banking app or USSD to your dedicated $bankName account number. Funds are automatically captured and credited within seconds.',
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.5),
            ),
            const SizedBox(height: 12),

            // Anti-Fraud Notice
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFF59E0B), width: 0.8),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFB45309)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Anti-Fraud Compliance: Only transfers originating from your personal bank account matching your name are accepted. 3rd-party transfers are reversed automatically.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF92400E), fontWeight: FontWeight.w600, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Bank Details Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('BANK NAME', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w700)),
                      InkWell(
                        onTap: () => _copyToClipboard(bankName, 'Bank Name'),
                        child: Row(
                          children: [
                            Text(bankName, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
                            const SizedBox(width: 6),
                            const Icon(Icons.copy_rounded, color: Color(0xFF34D399), size: 14),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Color(0xFF334155), height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('ACCOUNT NUMBER', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w700)),
                      InkWell(
                        onTap: () => _copyToClipboard(accNum, 'Account Number'),
                        child: Row(
                          children: [
                            Text(accNum, style: const TextStyle(color: Color(0xFF34D399), fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                            const SizedBox(width: 6),
                            const Icon(Icons.copy_rounded, color: Color(0xFF34D399), size: 14),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Color(0xFF334155), height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('ACCOUNT NAME', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w700)),
                      Flexible(
                        child: InkWell(
                          onTap: () => _copyToClipboard(accName, 'Account Name'),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(accName, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.copy_rounded, color: Color(0xFF34D399), size: 14),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  final full = 'Bank: $bankName\nAccount Number: $accNum\nAccount Name: $accName';
                  _copyToClipboard(full, 'All Bank Details');
                  Navigator.pop(ctx);
                },
                icon: const Icon(Icons.copy_all_rounded, size: 18),
                label: const Text('Copy All Details & Open Bank App', style: TextStyle(fontWeight: FontWeight.w800)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
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

  void _showWithdrawModal() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final double balance = (_virtualAccount?['balance'] as num?)?.toDouble() ?? auth.user?.virtualAccountBalance ?? 0.0;
    _amountController.clear();
    _accountNumberController.clear();
    _accountNameController.clear();

    bool isResolving = false;
    bool isWithdrawing = false;
    String? resolvedAccountName;
    String? modalError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          void resolveAccount() async {
            final accNum = _accountNumberController.text.trim();
            if (accNum.length != 10) return;
            setModalState(() {
              isResolving = true;
              modalError = null;
            });
            try {
              final res = await ApiClient.post('/banking/resolve-account', {
                'bankCode': _selectedBankCode,
                'accountNumber': accNum,
              });
              if (res != null) {
                final name = res['account_name'] ?? res['accountName'] ?? '';
                if (name.isNotEmpty) {
                  _accountNameController.text = name;
                  setModalState(() {
                    resolvedAccountName = name;
                    isResolving = false;
                  });
                  return;
                }
              }
              setModalState(() => isResolving = false);
            } catch (e) {
              setModalState(() {
                isResolving = false;
                resolvedAccountName = null;
              });
            }
          }

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              top: 24,
              left: 24,
              right: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.arrow_upward_rounded, color: AppColors.primary, size: 20),
                          SizedBox(width: 8),
                          Text('Withdraw from Escrow', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                        ],
                      ),
                      IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  Text(
                    'Available Escrow Balance: ${CurrencyFormatter.format(balance)}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF059669), fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),

                  // Amount
                  const Text('Amount to Withdraw (₦)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) {
                      if (modalError != null) setModalState(() => modalError = null);
                    },
                    decoration: InputDecoration(
                      prefixText: '₦ ',
                      hintText: 'e.g. 50,000',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Destination Bank Dropdown
                  const Text('Destination Commercial Bank', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: _selectedBankCode,
                    items: _nigerianBanks.map((b) {
                      return DropdownMenuItem<String>(
                        value: b['code'],
                        child: Text(b['name']!, style: const TextStyle(fontSize: 12.5)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() {
                          _selectedBankCode = val;
                          final matched = _nigerianBanks.firstWhere((b) => b['code'] == val, orElse: () => {'name': 'Bank', 'code': val});
                          _selectedBankName = matched['name']!;
                          modalError = null;
                        });
                        resolveAccount();
                      }
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Account Number
                  const Text('NUBAN Account Number (10 Digits)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _accountNumberController,
                    keyboardType: TextInputType.number,
                    maxLength: 10,
                    onChanged: (val) {
                      if (modalError != null) setModalState(() => modalError = null);
                      if (val.trim().length == 10) {
                        resolveAccount();
                      } else if (resolvedAccountName != null) {
                        setModalState(() => resolvedAccountName = null);
                      }
                    },
                    decoration: InputDecoration(
                      hintText: '0123456789',
                      counterText: '',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Account Name
                  const Text('Account Holder Name', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _accountNameController,
                    decoration: InputDecoration(
                      hintText: isResolving ? 'Detecting account holder...' : 'e.g. Chiroma Adeleke',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),

                  if (isResolving) ...[
                    const SizedBox(height: 8),
                    const Row(
                      children: [
                        SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF059669))),
                        SizedBox(width: 8),
                        Text('Verifying beneficiary account with bank...', style: TextStyle(fontSize: 11, color: Color(0xFF059669), fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ] else if (resolvedAccountName != null && resolvedAccountName!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF6EE7B7)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Verified Receiver: $resolvedAccountName',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF065F46)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (modalError != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              modalError!,
                              style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 11.5, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isWithdrawing
                          ? null
                          : () async {
                              final rawText = _amountController.text.replaceAll(',', '').replaceAll('₦', '').replaceAll(' ', '').trim();
                              final rawAmount = double.tryParse(rawText) ?? 0.0;
                              final accNum = _accountNumberController.text.trim();
                              final accName = _accountNameController.text.trim().isNotEmpty
                                  ? _accountNameController.text.trim()
                                  : (resolvedAccountName ?? 'Account Holder');

                              if (rawAmount < 1000) {
                                setModalState(() => modalError = 'Minimum withdrawal amount is ₦1,000');
                                return;
                              }
                              if (rawAmount > balance) {
                                setModalState(() => modalError = 'Insufficient escrow wallet balance (Available: ${CurrencyFormatter.format(balance)})');
                                return;
                              }
                              if (accNum.length != 10) {
                                setModalState(() => modalError = 'Please enter a valid 10-digit NUBAN account number');
                                return;
                              }

                              setModalState(() {
                                isWithdrawing = true;
                                modalError = null;
                              });

                              try {
                                await ApiClient.post('/banking/withdraw', {
                                  'amount': rawAmount,
                                  'bankCode': _selectedBankCode,
                                  'bankName': _selectedBankName,
                                  'accountNumber': accNum,
                                  'accountName': accName,
                                });

                                if (ctx.mounted) Navigator.pop(ctx);
                                _fetchAccountAndTransactions();

                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('💸 Withdrawal of ${CurrencyFormatter.format(rawAmount)} processed successfully. Push and email alerts dispatched.'),
                                      backgroundColor: const Color(0xFF059669),
                                      duration: const Duration(seconds: 4),
                                    ),
                                  );
                                }
                              } catch (err) {
                                setModalState(() {
                                  isWithdrawing = false;
                                  modalError = err.toString().replaceFirst('Exception: ', '');
                                });
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: isWithdrawing
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Confirm Withdrawal', style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _downloadStatementPdf() async {
    final token = await ApiClient.getToken();
    final url = Uri.parse('${ApiConstants.baseUrl}/banking/statement/pdf?type=$_selectedFilter&token=$token');
    try {
      final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!launched) {
        await launchUrl(url, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Downloading statement PDF...')),
        );
      }
    }
  }

  void _shareStatementPdf() async {
    final token = await ApiClient.getToken();
    final url = '${ApiConstants.baseUrl}/banking/statement/pdf?type=$_selectedFilter&token=$token';

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
              SizedBox(width: 10),
              Text('Preparing branded PDF statement for sharing...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );
    }

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/Hometrust_Statement_${_selectedFilter}_${DateTime.now().millisecondsSinceEpoch}.pdf');
        await file.writeAsBytes(response.bodyBytes);

        await Share.shareXFiles(
          [XFile(file.path, mimeType: 'application/pdf')],
          text: 'Official Hometrust Escrow Account Statement (₦ Nigerian Naira)',
          subject: 'Hometrust Escrow Statement',
        );
        return;
      }
    } catch (e) {
      debugPrint('Error sharing statement PDF: $e');
    }
  }

  void _downloadReceiptPdf(String ref) async {
    final token = await ApiClient.getToken();
    final url = Uri.parse('${ApiConstants.baseUrl}/banking/receipt/$ref/pdf?token=$token');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Opening receipt PDF...')),
        );
      }
    }
  }

  void _shareReceipt(Map<String, dynamic> tx) async {
    final String ref = tx['reference'] ?? tx['id'] ?? 'N/A';
    final token = await ApiClient.getToken();
    final url = '${ApiConstants.baseUrl}/banking/receipt/$ref/pdf?token=$token';

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
              SizedBox(width: 10),
              Text('Preparing branded PDF receipt for sharing...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );
    }

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        final tempDir = await getTemporaryDirectory();
        final sanitizedRef = ref.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
        final file = File('${tempDir.path}/Hometrust_Receipt_$sanitizedRef.pdf');
        await file.writeAsBytes(response.bodyBytes);

        await Share.shareXFiles(
          [XFile(file.path, mimeType: 'application/pdf')],
          text: 'Official Hometrust Escrow Receipt for Ref: $ref (₦ Nigerian Naira)',
          subject: 'Official Hometrust Receipt - $ref',
        );
        return;
      }
    } catch (e) {
      debugPrint('Error sharing receipt PDF: $e');
    }

    // Fallback if network stream fails
    final bool isCredit = tx['type'] == 'CREDIT';
    final double amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;
    final String status = (tx['status'] ?? 'SUCCESS').toString().toUpperCase();
    final String desc = tx['description'] ?? tx['purpose'] ?? 'Escrow Transaction';
    final String date = tx['createdAt'] != null
        ? DateTime.parse(tx['createdAt']).toLocal().toString().substring(0, 16)
        : 'Recent';

    final receiptText = '''
═══════════════════════════════════
🏛️ HOMETRUST OFFICIAL ESCROW RECEIPT
═══════════════════════════════════
Amount: ${CurrencyFormatter.format(amount)} (NGN / ₦)
Currency: Nigerian Naira (₦)
Type: ${isCredit ? 'INFLOW / DEPOSIT' : 'OUTFLOW / WITHDRAWAL'}
Status: $status (VERIFIED)
Reference: $ref
Description: $desc
Date: $date
Security: Guaranteed by CBN Licensed Escrow Banking
═══════════════════════════════════
Official Web Verification: https://hometrustng.com
''';

    Share.share(
      receiptText.trim(),
      subject: 'Official Hometrust Receipt - $ref',
    );
  }

  void _showTransactionDetails(Map<String, dynamic> tx) {
    final bool isCredit = tx['type'] == 'CREDIT';
    final double amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;
    final String status = (tx['status'] ?? 'SUCCESS').toString().toUpperCase();
    final String ref = tx['reference'] ?? tx['id'] ?? 'N/A';
    final String dateStr = tx['createdAt'] != null
        ? DateTime.parse(tx['createdAt']).toLocal().toString().substring(0, 16)
        : 'Recent';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Transaction Receipt', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 12),

            // Amount Header
            Center(
              child: Column(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: isCredit ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                      color: isCredit ? const Color(0xFF059669) : const Color(0xFFDC2626),
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${isCredit ? '+' : '-'}${CurrencyFormatter.format(amount)}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: isCredit ? const Color(0xFF059669) : const Color(0xFFDC2626),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: status == 'SUCCESS' || status == 'CONFIRMED'
                          ? const Color(0xFFECFDF5)
                          : const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: status == 'SUCCESS' || status == 'CONFIRMED'
                            ? const Color(0xFF059669)
                            : const Color(0xFFD97706),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Details Table
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _receiptRow('Description', tx['description'] ?? tx['purpose'] ?? 'Escrow Transaction'),
                  const Divider(height: 16),
                  _receiptRow('Date & Time', dateStr),
                  const Divider(height: 16),
                  _receiptRow('Reference', ref, isRef: true),
                  const Divider(height: 16),
                  _receiptRow('Payment Channel', tx['channel'] ?? 'Direct Bank Transfer'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Action Buttons: Download PDF Receipt & Share Receipt
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _shareReceipt(tx);
                    },
                    icon: const Icon(Icons.share_rounded, size: 16, color: Color(0xFF0F172A)),
                    label: const Text('Share Receipt', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _downloadReceiptPdf(ref);
                    },
                    icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                    label: const Text('Download PDF', style: TextStyle(fontWeight: FontWeight.w800)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _receiptRow(String label, String value, {bool isRef = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
        const SizedBox(width: 12),
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: isRef ? AppColors.primary : const Color(0xFF0F172A),
                    fontFamily: isRef ? 'monospace' : null,
                  ),
                ),
              ),
              if (isRef) ...[
                const SizedBox(width: 4),
                const Icon(Icons.copy_rounded, size: 12, color: AppColors.primary),
              ],
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;
    final bool isVerified = user?.isVerified ?? false;

    final effectiveAcc = _virtualAccount ?? {
      'accountNumber': user?.virtualAccountNumber ?? '',
      'bankName': user?.virtualBankName ?? 'Dedicated Escrow Bank',
      'accountName': user?.virtualAccountName ?? 'Hometrust / ${user?.fullName ?? 'Customer'}',
      'balance': user?.virtualAccountBalance ?? 0.0,
    };

    final double balance = (effectiveAcc['balance'] as num?)?.toDouble() ?? 0.0;
    final String accNum = effectiveAcc['accountNumber']?.toString() ?? '';
    final String bankName = effectiveAcc['bankName']?.toString() ?? 'Dedicated Escrow Bank';
    final String accName = effectiveAcc['accountName']?.toString() ?? 'Hometrust Customer';

    // Filter transactions
    final filteredTxs = _transactions.where((tx) {
      if (_selectedFilter == 'ALL') return true;
      if (_selectedFilter == 'CREDIT') return tx['type'] == 'CREDIT';
      if (_selectedFilter == 'DEBIT') return tx['type'] == 'DEBIT';
      return true;
    }).toList();

    return Scaffold(
      bottomNavigationBar: const PersistentBottomNav(),
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'My Escrow Wallet',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Color(0xFF0F172A)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            tooltip: 'Refresh',
            onPressed: _fetchAccountAndTransactions,
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primary),
            tooltip: 'Download Statement (PDF)',
            onPressed: _downloadStatementPdf,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchAccountAndTransactions,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. DEDICATED ESCROW WALLET CARD
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0D5C3A), Color(0xFF083C25)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFC9A227).withValues(alpha: 0.35)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0D5C3A).withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row: Badge + Verification Status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF064E3B),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.shield_rounded, color: Color(0xFF34D399), size: 12),
                              SizedBox(width: 4),
                              Text('DEDICATED ESCROW ACCOUNT', style: TextStyle(color: Color(0xFF34D399), fontSize: 9.5, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: isVerified
                                ? const Color(0xFF10B981).withValues(alpha: 0.2)
                                : const Color(0xFFEF4444).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isVerified ? 'VERIFIED' : 'UNVERIFIED',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: isVerified ? const Color(0xFF34D399) : const Color(0xFFF87171),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Balance Display with Eye Toggle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('AVAILABLE ESCROW BALANCE', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                            const SizedBox(height: 4),
                            Text(
                              _hideBalance ? '₦ ••••••••' : CurrencyFormatter.format(balance),
                              style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(
                            _hideBalance ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                            color: const Color(0xFF34D399),
                            size: 22,
                          ),
                          onPressed: () => setState(() => _hideBalance = !_hideBalance),
                        ),
                      ],
                    ),

                    const Divider(height: 24, color: Color(0xFF334155)),

                    if (accNum.isNotEmpty) ...[
                      // Account Number Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('NUBAN ACCOUNT NUMBER', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 2),
                              Text(
                                accNum,
                                style: const TextStyle(color: Color(0xFF34D399), fontSize: 19, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                              ),
                            ],
                          ),
                          InkWell(
                            onTap: () => _copyToClipboard(accNum, 'Account Number'),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF059669).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.copy_rounded, color: Color(0xFF34D399), size: 14),
                                  SizedBox(width: 4),
                                  Text('Copy', style: TextStyle(color: Color(0xFF34D399), fontSize: 11, fontWeight: FontWeight.w800)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Stacked Bank & Account Info Container (Never overflows)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      const Icon(Icons.account_balance_rounded, color: Color(0xFF34D399), size: 14),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          bankName,
                                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                InkWell(
                                  onTap: () => _copyToClipboard(bankName, 'Bank Name'),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    child: Icon(Icons.copy_rounded, color: Color(0xFF94A3B8), size: 13),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      const Icon(Icons.person_rounded, color: Color(0xFF94A3B8), size: 14),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          accName,
                                          style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 11, fontWeight: FontWeight.w600),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                InkWell(
                                  onTap: () => _copyToClipboard(accName, 'Account Name'),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    child: Icon(Icons.copy_rounded, color: Color(0xFF94A3B8), size: 13),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: _showReceiveModal,
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('View Complete Bank Details & Guide', style: TextStyle(color: Color(0xFF34D399), fontSize: 10.5, fontWeight: FontWeight.w800)),
                                  SizedBox(width: 4),
                                  Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF34D399), size: 9),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      const Text(
                        'Virtual NUBAN Inactive. Complete KYC to activate your account.',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Quick Action Buttons: Receive/Fund & Withdraw
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.arrow_downward_rounded, size: 16),
                            label: const Text('Fund Wallet', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                            onPressed: _showReceiveModal,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF059669),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.arrow_upward_rounded, size: 16, color: Colors.white),
                            label: const Text('Withdraw', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)),
                            onPressed: _showWithdrawModal,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF475569)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // 2. ANTI-FRAUD NOTICE CARD
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF59E0B), width: 0.8),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.shield_rounded, size: 16, color: Color(0xFFB45309)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Anti-Fraud Compliance Rule: Only deposits from your own personal bank account matching your name are credited. 3rd-party deposits will be automatically reversed.',
                        style: TextStyle(fontSize: 10.5, color: Color(0xFF92400E), fontWeight: FontWeight.w600, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 3. TRANSACTIONS LEDGER SECTION
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Transaction History',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                  ),
                  Row(
                    children: [
                      InkWell(
                        onTap: _shareStatementPdf,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.share_rounded, size: 12, color: Color(0xFF334155)),
                              SizedBox(width: 4),
                              Text('Share PDF', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF334155))),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: _downloadStatementPdf,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF6EE7B7)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.picture_as_pdf_rounded, size: 12, color: Color(0xFF059669)),
                              SizedBox(width: 4),
                              Text('Download PDF', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF065F46))),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Filter Chips: ALL, CREDITS, DEBITS
              Row(
                children: [
                  _filterChip('ALL', 'All'),
                  const SizedBox(width: 8),
                  _filterChip('CREDIT', 'Inflow / Deposits'),
                  const SizedBox(width: 8),
                  _filterChip('DEBIT', 'Outflow / Payouts'),
                ],
              ),
              const SizedBox(height: 14),

              // Transactions List
              if (_loadingTransactions)
                const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)))
              else if (filteredTxs.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.receipt_long_outlined, size: 36, color: Color(0xFF94A3B8)),
                      const SizedBox(height: 8),
                      const Text(
                        'No transactions recorded yet',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF475569)),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Deposits and withdrawals through your dedicated account will appear here instantly.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredTxs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final tx = filteredTxs[index];
                    final bool isCredit = tx['type'] == 'CREDIT';
                    final double amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;
                    final String status = (tx['status'] ?? 'SUCCESS').toString().toUpperCase();
                    final String dateStr = tx['createdAt'] != null
                        ? DateTime.parse(tx['createdAt']).toLocal().toString().substring(0, 10)
                        : 'Recent';

                    return InkWell(
                      onTap: () => _showTransactionDetails(tx),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isCredit ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                                color: isCredit ? const Color(0xFF059669) : const Color(0xFFDC2626),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tx['description'] ?? tx['purpose'] ?? 'Escrow Transaction',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Text(
                                        dateStr,
                                        style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: status == 'SUCCESS' || status == 'CONFIRMED'
                                              ? const Color(0xFFECFDF5)
                                              : const Color(0xFFFEF3C7),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          status,
                                          style: TextStyle(
                                            fontSize: 8.5,
                                            fontWeight: FontWeight.w800,
                                            color: status == 'SUCCESS' || status == 'CONFIRMED'
                                                ? const Color(0xFF059669)
                                                : const Color(0xFFD97706),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${isCredit ? '+' : '-'}${CurrencyFormatter.format(amount)}',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w900,
                                color: isCredit ? const Color(0xFF059669) : const Color(0xFFDC2626),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterChip(String key, String label) {
    final bool isSelected = _selectedFilter == key;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = key),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}
