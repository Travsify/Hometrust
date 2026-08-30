import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/constants/colors.dart';
import '../core/network/api_client.dart';
import '../core/utils/currency_formatter.dart';
import '../providers/auth_provider.dart';
import '../providers/purchase_provider.dart';
import 'become_developer_screen.dart';
import 'login_screen.dart';
import 'legal_request_screen.dart';
import 'kyc_screen.dart';
import 'wallet_screen.dart';
import 'chat_screen.dart';
import 'inbox_screen.dart';
import 'build_for_me_screen.dart';
import 'support_tickets_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _virtualAccount;
  bool _loadingAccount = false;
  bool _hideBalance = false;

  @override
  void initState() {
    super.initState();
    _fetchAccount();
  }

  void _fetchAccount() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isAuthenticated) return;

    // Instant local hydration from UserModel so balance and NUBAN appear without delay
    if (_virtualAccount == null && auth.user?.virtualAccountNumber != null) {
      _virtualAccount = {
        'accountNumber': auth.user!.virtualAccountNumber,
        'bankName': auth.user!.virtualBankName ?? 'Dedicated Escrow Bank',
        'accountName': auth.user!.virtualAccountName ?? 'Hometrust / ${auth.user!.fullName}',
        'balance': auth.user!.virtualAccountBalance,
      };
    }

    try {
      final res = await ApiClient.get('/banking/my-account');
      if (mounted && res != null) {
        setState(() {
          _virtualAccount = res;
          _loadingAccount = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingAccount = false);
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

  void _syncLiveAccount() async {
    setState(() => _loadingAccount = true);
    try {
      final res = await ApiClient.post('/banking/sync-live-account', {});
      if (mounted) {
        setState(() {
          _virtualAccount = res['virtualAccount'];
          _loadingAccount = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Dedicated Escrow Account synced successfully!'),
            backgroundColor: Color(0xFF059669),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingAccount = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to sync live account: $e'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
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
                const Text('Fund Escrow Wallet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            Text(
              'Transfer directly from any Nigerian banking app or USSD to your dedicated $bankName account number. Funds are automatically captured and credited within seconds.',
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.5),
            ),
            const SizedBox(height: 12),
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
                      'Anti-Fraud Compliance: Only transfers originating from your own personal bank account (matching your name) are accepted. 3rd-party transfers are reversed automatically.',
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
                            Text(accNum, style: const TextStyle(color: Color(0xFF34D399), fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                            const SizedBox(width: 6),
                            const Icon(Icons.copy_rounded, color: Color(0xFF34D399), size: 16),
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
                      InkWell(
                        onTap: () => _copyToClipboard(accName, 'Account Name'),
                        child: Row(
                          children: [
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 180),
                              child: Text(accName, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.copy_rounded, color: Color(0xFF34D399), size: 14),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.copy_all_rounded, size: 18),
                label: const Text('Copy All Account Details', style: TextStyle(fontWeight: FontWeight.w800)),
                onPressed: () {
                  final fullText = 'Bank: $bankName\nAccount Number: $accNum\nAccount Name: $accName';
                  _copyToClipboard(fullText, 'Bank Details');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _showWithdrawModal() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final balance = (_virtualAccount?['balance'] as num?)?.toDouble() ?? auth.user?.virtualAccountBalance ?? 0.0;

    final amountCtrl = TextEditingController();
    final accNumCtrl = TextEditingController();
    final accNameCtrl = TextEditingController();
    String selectedBankCode = '044'; // Access Bank default
    String selectedBankName = 'Access Bank';
    String? resolvedAccountName;
    String? modalError;
    bool isResolving = false;
    bool isWithdrawing = false;

    final banks = [
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          void resolveAccount() async {
            final accNum = accNumCtrl.text.trim();
            if (accNum.length != 10) return;
            setModalState(() => isResolving = true);
            try {
              final res = await ApiClient.post('/banking/resolve-account', {
                'bankCode': selectedBankCode,
                'accountNumber': accNum,
              });
              if (res != null) {
                final name = res['account_name'] ?? res['accountName'] ?? '';
                if (name.isNotEmpty) {
                  accNameCtrl.text = name;
                  setModalState(() {
                    resolvedAccountName = name;
                    isResolving = false;
                  });
                  return;
                }
              }
              setModalState(() => isResolving = false);
            } catch (e) {
              setModalState(() => isResolving = false);
            }
          }

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Available Balance:', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      Text(CurrencyFormatter.format(balance), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF059669))),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Amount Field
                  const Text('Amount to Withdraw (₦)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
                  const SizedBox(height: 6),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      prefixText: '₦ ',
                      hintText: 'e.g. 50000',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Destination Bank Dropdown
                  const Text('Destination Commercial Bank', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: selectedBankCode,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: banks.map((b) => DropdownMenuItem(value: b['code'], child: Text(b['name']!, style: const TextStyle(fontSize: 13)))).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() {
                          selectedBankCode = val;
                          selectedBankName = banks.firstWhere((b) => b['code'] == val)['name']!;
                        });
                        resolveAccount();
                      }
                    },
                  ),
                  const SizedBox(height: 14),

                  // Account Number Field
                  const Text('NUBAN Account Number (10 Digits)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
                  const SizedBox(height: 6),
                  TextField(
                    controller: accNumCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 10,
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '0123456789',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    onChanged: (v) {
                      if (v.trim().length == 10) {
                        resolveAccount();
                      } else if (resolvedAccountName != null) {
                        setModalState(() => resolvedAccountName = null);
                      }
                    },
                  ),

                  // Account Name Field
                  const SizedBox(height: 14),
                  const Text('Account Holder Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
                  const SizedBox(height: 6),
                  TextField(
                    controller: accNameCtrl,
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Receiver: $resolvedAccountName',
                              style: const TextStyle(color: Color(0xFF065F46), fontWeight: FontWeight.w800, fontSize: 12),
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

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isWithdrawing
                          ? null
                          : () async {
                              final rawText = amountCtrl.text.replaceAll(',', '').replaceAll('₦', '').replaceAll(' ', '').trim();
                              final rawAmount = double.tryParse(rawText) ?? 0.0;
                              final accNum = accNumCtrl.text.trim();
                              final accName = accNameCtrl.text.trim().isNotEmpty ? accNameCtrl.text.trim() : (resolvedAccountName ?? 'Account Holder');

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
                                  'bankCode': selectedBankCode,
                                  'bankName': selectedBankName,
                                  'accountNumber': accNum,
                                  'accountName': accName,
                                });

                                if (context.mounted) {
                                  Navigator.pop(ctx);
                                  _fetchAccount();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('💸 Withdrawal of ${CurrencyFormatter.format(rawAmount)} initiated successfully! Email and Push notifications sent.'),
                                      backgroundColor: const Color(0xFF059669),
                                      duration: const Duration(seconds: 4),
                                    ),
                                  );
                                }
                              } catch (e) {
                                setModalState(() {
                                  isWithdrawing = false;
                                  modalError = e.toString().replaceFirst('Exception: ', '');
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
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
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

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'My Account & Security',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 17),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // User Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        auth.isAuthenticated ? user?.firstName[0] ?? 'U' : '?',
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.isAuthenticated ? user?.fullName ?? 'Valued Customer' : 'Guest User',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          auth.isAuthenticated ? user?.email ?? '' : 'Sign in to access your vault',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        if (auth.isAuthenticated) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.emeraldBg,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'ROLE: ${user?.role}',
                                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.emeraldText),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  if (!auth.isAuthenticated) {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                                  } else if (user?.isVerified != true) {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => const KycScreen()));
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (user?.isVerified == true)
                                        ? const Color(0xFF10B981).withValues(alpha: 0.12)
                                        : const Color(0xFFEF4444).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: (user?.isVerified == true)
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFFEF4444),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Text(
                                    (user?.isVerified == true)
                                        ? 'VERIFIED 🛡️'
                                        : 'UNVERIFIED ⚠️',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      color: (user?.isVerified == true)
                                          ? const Color(0xFF059669)
                                          : const Color(0xFFDC2626),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Dedicated Virtual Account & Escrow Wallet Card
            if (auth.isAuthenticated) ...[
              const SizedBox(height: 20),
              if (_virtualAccount != null || (user != null && user.virtualAccountNumber != null))
                Builder(
                  builder: (context) {
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

                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0D5C3A), Color(0xFF083C25)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFC9A227).withValues(alpha: 0.3)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0D5C3A).withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Row: Badge + Sync Button
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                              IconButton(
                                icon: const Icon(Icons.refresh_rounded, color: Color(0xFF94A3B8), size: 18),
                                tooltip: 'Sync Live Account',
                                onPressed: _syncLiveAccount,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Escrow Wallet Balance with Privacy Eye Toggle
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('ESCROW WALLET BALANCE', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                                  const SizedBox(height: 4),
                                  Text(
                                    _hideBalance ? '₦ ••••••••' : CurrencyFormatter.format(balance),
                                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 0.5),
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

                          const Divider(height: 20, color: Color(0xFF1E3A2B)),

                          if (accNum.isNotEmpty) ...[
                            // Account Number with One-Tap Copy
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('NUBAN ACCOUNT NUMBER', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5, fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 2),
                                    Text(
                                      accNum,
                                      style: const TextStyle(color: Color(0xFF34D399), fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.5),
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
                          ],

                          const SizedBox(height: 20),

                          // Action Buttons: Send/Receive/Withdraw
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
                          const SizedBox(height: 12),

                          // Full Wallet & Transactions Ledger Link
                          InkWell(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen())),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.receipt_long_rounded, size: 14, color: Color(0xFFFDE047)),
                                  SizedBox(width: 6),
                                  Text(
                                    'View Full Wallet & Transactions Ledger →',
                                    style: TextStyle(color: Color(0xFFFDE047), fontSize: 11, fontWeight: FontWeight.w800),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.blueBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.blueBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.account_balance, color: AppColors.blueText, size: 28),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('Generate Dedicated Bank Account', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.blueText)),
                            SizedBox(height: 2),
                            Text('Complete KYC to receive your dedicated account number.', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const KycScreen()),
                          ).then((_) => _fetchAccount());
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                        child: const Text('Start KYC', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
            ],


            // ── MODE / UPGRADE CARD (role-aware) ─────────────────────────────
            if (auth.isAuthenticated) ...[

              // ── FOR DEVELOPER-ROLE USERS in buyer mode: show Switch Back button ──
              if (user?.role == 'DEVELOPER' && !auth.isDeveloperMode) ...[
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    auth.toggleDeveloperMode();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Switched back to Developer Mode'),
                        backgroundColor: Color(0xFF059669),
                        duration: Duration(seconds: 3),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF059669), Color(0xFF047857)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF059669).withValues(alpha: 0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.business_center_rounded, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'You are in Buyer Mode',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Tap here to switch back to your Developer Dashboard.',
                                style: TextStyle(fontSize: 11, color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Dev Mode',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF059669)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // ── FOR BUYER-ROLE USERS: show Become a Developer CTA ──
              if (user?.role == 'BUYER') ...[
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const BecomeDeveloperScreen()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFCD34D), width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDE68A),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.business_center_outlined, color: Color(0xFFD97706), size: 22),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Become a Developer',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF92400E)),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'List properties, manage escrow, and access developer tools.',
                                style: TextStyle(fontSize: 11, color: Color(0xFF78350F), height: 1.4),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.chevron_right_rounded, color: Color(0xFFD97706)),
                      ],
                    ),
                  ),
                ),
              ],
            ],


            const SizedBox(height: 24),
            // Menu Items
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                children: [
                  _buildMenuItem(
                    icon: Icons.gavel_rounded,
                    title: 'Request Legal Document Preparation',
                    subtitle: 'Deeds, Contracts of Sale, Tenancy & Leases',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LegalRequestScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1, color: AppColors.cardBorder),
                  _buildMenuItem(
                    icon: Icons.shield_outlined,
                    title: 'KYC & Identity Verification',
                    subtitle: user?.isVerified == true
                        ? 'Identity Verified ✅'
                        : 'NIN & BVN verification badge',
                    trailing: user?.isVerified == true
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFF10B981), width: 0.8),
                            ),
                            child: const Text(
                              'VERIFIED',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF059669)),
                            ),
                          )
                        : null,
                    onTap: () {
                      if (user?.isVerified == true) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Your identity is already verified ✅'),
                            backgroundColor: Color(0xFF059669),
                          ),
                        );
                        return;
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const KycScreen()),
                      ).then((_) => _fetchAccount());
                    },
                  ),
                  const Divider(height: 1, color: AppColors.cardBorder),
                  _buildMenuItem(
                    icon: Icons.architecture_rounded,
                    title: 'Charter A Builder 🏗️',
                    subtitle: 'Managed construction with vetted COREN engineers & escrow',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const BuildForMeScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1, color: AppColors.cardBorder),
                  _buildMenuItem(
                    icon: Icons.folder_shared_outlined,
                    title: 'Document Vault',
                    subtitle: 'All title deeds, C of O, and payment receipts',
                    onTap: () => _showDocumentVault(context),
                  ),
                  const Divider(height: 1, color: AppColors.cardBorder),
                  _buildMenuItem(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'Direct Messages',
                    subtitle: 'Chat directly with verified developers & project team experts',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const InboxScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1, color: AppColors.cardBorder),
                  _buildMenuItem(
                    icon: Icons.confirmation_number_outlined,
                    title: 'Support Tickets',
                    subtitle: 'Open urgent, high, or medium priority tickets & track resolution',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SupportTicketsScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1, color: AppColors.cardBorder),
                  _buildMenuItem(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy & Terms of Service',
                    subtitle: 'Legal framework, escrow terms & data security',
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          title: const Row(
                            children: [
                              Icon(Icons.privacy_tip_rounded, color: AppColors.primary, size: 22),
                              SizedBox(width: 8),
                              Text('Privacy & Terms', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
                            ],
                          ),
                          content: SizedBox(
                            width: double.maxFinite,
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    '1. ESCROW PROTOCOL & PROTECTION',
                                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11.5, color: Color(0xFF0F172A)),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'All financial transactions are secured through CBN-licensed banking partners in dedicated Escrow Accounts. Funds are disbursed strictly upon milestone completion verified by certified surveyors.',
                                    style: TextStyle(fontSize: 11, color: Color(0xFF475569), height: 1.45),
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    '2. NDPR DATA PRIVACY COMPLIANCE',
                                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11.5, color: Color(0xFF0F172A)),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Hometrust processes personal identity data (NIN, BVN, Phone, Email) solely for KYC verification, anti-money laundering (AML) checks, and virtual bank account generation in accordance with the Nigeria Data Protection Act.',
                                    style: TextStyle(fontSize: 11, color: Color(0xFF475569), height: 1.45),
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    '3. TITLE DEED VERIFICATION & LEGAL PROTOCOLS',
                                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11.5, color: Color(0xFF0F172A)),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Property verifications and legal contracts are conducted with official state land registries (e.g. Lands Bureau, Alausa) by licensed solicitors under the Nigerian Bar Association.',
                                    style: TextStyle(fontSize: 11, color: Color(0xFF475569), height: 1.45),
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    '4. FULL LEGAL POLICY ON WEBSITE',
                                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11.5, color: Color(0xFF0F172A)),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'You can access our comprehensive Privacy Policy, Terms of Service, and Escrow Warranty agreements directly on our official website at https://hometrustng.com/privacy',
                                    style: TextStyle(fontSize: 11, color: Color(0xFF059669), height: 1.45, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            if (auth.isAuthenticated)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Provider.of<PurchaseProvider>(context, listen: false).clear();
                    auth.logout();
                  },
                  icon: const Icon(Icons.logout, color: AppColors.roseText, size: 18),
                  label: const Text('Log Out', style: TextStyle(color: AppColors.roseText, fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.roseText),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()))
                        .then((_) => _fetchAccount());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Sign In / Register', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      trailing: trailing ?? const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 18),
    );
  }

  // ── Document Vault ──────────────────────────────────────────────────────────
  void _showDocumentVault(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.folder_shared_outlined, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Document Vault', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                          Text('Your title deeds, C of O & payment receipts', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 24),
              Expanded(
                child: FutureBuilder<List<dynamic>>(
                  future: ApiClient.get('/purchases/my').then((r) => r as List? ?? []),
                  builder: (ctx, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final purchases = snap.data ?? [];
                    if (purchases.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.folder_open_outlined, size: 56, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            const Text('No documents yet', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                            const SizedBox(height: 4),
                            const Text('Documents from your purchases will appear here.', style: TextStyle(fontSize: 11, color: AppColors.textMuted), textAlign: TextAlign.center),
                          ],
                        ),
                      );
                    }
                    return ListView.separated(
                      controller: controller,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: purchases.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.cardBorder),
                      itemBuilder: (ctx, i) {
                        final p = purchases[i] as Map<String, dynamic>;
                        return ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.description_outlined, color: AppColors.primary, size: 20),
                          ),
                          title: Text(
                            p['property']?['title'] ?? p['project']?['name'] ?? 'Purchase Document',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                          subtitle: Text(
                            'Ref: ${p['purchaseCode'] ?? p['id']?.toString().substring(0, 8) ?? 'N/A'} • ${p['status'] ?? 'ACTIVE'}',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                          trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 18),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Support Ticket Sheet ────────────────────────────────────────────────────
  void _showSupportTicketSheet(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isAuthenticated) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SupportTicketSheet(userId: auth.user?.id ?? ''),
    );
  }
}

// ─── Support Ticket Bottom Sheet Widget ──────────────────────────────────────
class _SupportTicketSheet extends StatefulWidget {
  final String userId;
  const _SupportTicketSheet({required this.userId});

  @override
  State<_SupportTicketSheet> createState() => _SupportTicketSheetState();
}

class _SupportTicketSheetState extends State<_SupportTicketSheet> {
  bool _showNewTicket = false;
  bool _isSubmitting = false;
  List<dynamic> _tickets = [];
  bool _loadingTickets = true;

  final _subjectCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  String _selectedCategory = 'GENERAL';

  final _categories = {
    'GENERAL': 'General Enquiry',
    'PAYMENT': 'Payment Issue',
    'KYC': 'KYC / Verification',
    'ACCOUNT': 'Account Access',
    'TECHNICAL': 'Technical Issue',
  };

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTickets() async {
    try {
      final res = await ApiClient.get('/support/tickets');
      if (mounted) setState(() { _tickets = res as List? ?? []; _loadingTickets = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingTickets = false);
    }
  }

  Future<void> _submitTicket() async {
    final subject = _subjectCtrl.text.trim();
    final message = _messageCtrl.text.trim();
    if (subject.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in subject and message.')));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ApiClient.post('/support/tickets', {
        'subject': subject,
        'category': _selectedCategory,
        'message': message,
      });
      _subjectCtrl.clear();
      _messageCtrl.clear();
      setState(() { _showNewTicket = false; _isSubmitting = false; _loadingTickets = true; });
      await _loadTickets();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Support ticket submitted! We\'ll get back to you shortly.'), backgroundColor: AppColors.primary),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))));
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'OPEN': return const Color(0xFF2563EB);
      case 'IN_PROGRESS': return const Color(0xFFD97706);
      case 'RESOLVED': return const Color(0xFF059669);
      case 'CLOSED': return const Color(0xFF64748B);
      default: return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (ctx, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.support_agent_outlined, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Support Tickets', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                        Text('Get help from Hometrust support team', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => setState(() => _showNewTicket = !_showNewTicket),
                    icon: Icon(_showNewTicket ? Icons.close : Icons.add, size: 16, color: AppColors.primary),
                    label: Text(_showNewTicket ? 'Cancel' : 'New Ticket', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                  ),
                ],
              ),
            ),
            const Divider(height: 20),

            if (_showNewTicket) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 36,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: _categories.entries.map((e) => GestureDetector(
                          onTap: () => setState(() => _selectedCategory = e.key),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _selectedCategory == e.key ? AppColors.primary : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(e.value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _selectedCategory == e.key ? Colors.white : AppColors.textSecondary)),
                          ),
                        )).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _subjectCtrl,
                      decoration: InputDecoration(
                        labelText: 'Subject',
                        hintText: 'Brief description of your issue',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                        filled: true, fillColor: const Color(0xFFF8FAFC),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _messageCtrl,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Message',
                        hintText: 'Describe your issue in detail...',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                        filled: true, fillColor: const Color(0xFFF8FAFC),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitTicket,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Submit Ticket', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                  ],
                ),
              ),
            ],

            Expanded(
              child: _loadingTickets
                  ? const Center(child: CircularProgressIndicator())
                  : _tickets.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.inbox_outlined, size: 56, color: Colors.grey.shade300),
                              const SizedBox(height: 12),
                              const Text('No tickets yet', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                              const SizedBox(height: 4),
                              const Text('Tap "New Ticket" to get support.', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                            ],
                          ),
                        )
                      : ListView.separated(
                          controller: scrollCtrl,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _tickets.length,
                          separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.cardBorder),
                          itemBuilder: (ctx, i) {
                            final t = _tickets[i] as Map<String, dynamic>;
                            final status = t['status'] ?? 'OPEN';
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _statusColor(status).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.confirmation_number_outlined, color: _statusColor(status), size: 18),
                              ),
                              title: Text(t['subject'] ?? 'Support Ticket', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 2),
                                  Text(t['message'] ?? '', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  if (t['adminReply'] != null) ...[
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(6)),
                                      child: Text('Reply: ${t['adminReply']}', style: const TextStyle(fontSize: 10, color: Color(0xFF059669), fontStyle: FontStyle.italic), maxLines: 2, overflow: TextOverflow.ellipsis),
                                    ),
                                  ],
                                ],
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _statusColor(status).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(status.replaceAll('_', ' '), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: _statusColor(status))),
                              ),
                              isThreeLine: t['adminReply'] != null,
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
