import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/network/api_client.dart';
import '../core/utils/currency_formatter.dart';
import '../providers/auth_provider.dart';
import 'kyc_screen.dart';
import 'login_screen.dart';

class DeveloperProfileScreen extends StatefulWidget {
  const DeveloperProfileScreen({super.key});

  @override
  State<DeveloperProfileScreen> createState() => _DeveloperProfileScreenState();
}

class _DeveloperProfileScreenState extends State<DeveloperProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _stats;
  Map<String, dynamic>? _virtualAccount;
  bool _loadingAccount = false;
  bool _hideBalance = false;

  @override
  void initState() {
    super.initState();
    _fetchProfileStats();
    _fetchAccount();
  }

  Future<void> _fetchProfileStats() async {
    try {
      final data = await ApiClient.get('/developers/my-stats');
      if (mounted) {
        setState(() {
          _stats = data;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchAccount() async {
    setState(() => _loadingAccount = true);
    try {
      final res = await ApiClient.get('/banking/my-account');
      if (mounted) {
        setState(() {
          _virtualAccount = res;
          _loadingAccount = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingAccount = false);
    }
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
            content: Text('✅ Dedicated Corporate Account synced successfully!'),
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
    if (_virtualAccount == null) return;
    final accNum = _virtualAccount!['accountNumber'] ?? '';
    final bankName = _virtualAccount!['bankName'] ?? 'Providus Bank';
    final accName = _virtualAccount!['accountName'] ?? 'Hometrust Corporate';

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
                const Text('Fund Corporate Escrow Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const Text(
              'Transfer directly from your corporate banking app or commercial bank to your dedicated Providus Bank escrow account. Funds are auto-captured immediately.',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.5),
            ),
            const SizedBox(height: 20),

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
                label: const Text('Copy All Corporate Bank Details', style: TextStyle(fontWeight: FontWeight.w800)),
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
    if (_virtualAccount == null) return;
    final balance = (_virtualAccount!['balance'] ?? 0).toDouble();

    final amountCtrl = TextEditingController();
    final accNumCtrl = TextEditingController();
    String selectedBankCode = '000014'; // Access Bank default
    String selectedBankName = 'Access Bank';
    String resolvedAccountName = '';
    bool isResolving = false;
    bool isWithdrawing = false;

    final banks = [
      {'name': 'Access Bank', 'code': '000014'},
      {'name': 'GTBank (Guaranty Trust)', 'code': '000013'},
      {'name': 'Zenith Bank', 'code': '000015'},
      {'name': 'First Bank of Nigeria', 'code': '000016'},
      {'name': 'United Bank for Africa (UBA)', 'code': '000004'},
      {'name': 'Kuda Microfinance Bank', 'code': '090267'},
      {'name': 'OPay (PayCom)', 'code': '090325'},
      {'name': 'Palmpay', 'code': '090405'},
      {'name': 'Providus Bank', 'code': '000023'},
      {'name': 'Stanbic IBTC Bank', 'code': '000012'},
      {'name': 'Sterling Bank', 'code': '000001'},
      {'name': 'Wema Bank', 'code': '000017'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          void resolveAccount() async {
            if (accNumCtrl.text.trim().length != 10) return;
            setModalState(() => isResolving = true);
            try {
              final res = await ApiClient.post('/banking/resolve-account', {
                'bankCode': selectedBankCode,
                'accountNumber': accNumCtrl.text.trim(),
              });
              setModalState(() {
                resolvedAccountName = res['account_name'] ?? res['accountName'] ?? 'Verified Account';
                isResolving = false;
              });
            } catch (e) {
              setModalState(() {
                resolvedAccountName = '';
                isResolving = false;
              });
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
                      const Text('Disburse Milestone Funds to Bank', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                      IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Available Escrow Balance:', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      Text(CurrencyFormatter.format(balance), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF059669))),
                    ],
                  ),
                  const SizedBox(height: 16),

                  const Text('Select Corporate Commercial Bank', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: selectedBankCode,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: banks.map((b) => DropdownMenuItem(value: b['code'], child: Text(b['name']!, style: const TextStyle(fontSize: 13)))).toList(),
                    onChanged: (val) {
                      setModalState(() {
                        selectedBankCode = val!;
                        selectedBankName = banks.firstWhere((b) => b['code'] == val)['name']!;
                      });
                      if (accNumCtrl.text.length == 10) resolveAccount();
                    },
                  ),
                  const SizedBox(height: 14),

                  const Text('10-Digit Corporate Account Number', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
                  const SizedBox(height: 6),
                  TextField(
                    controller: accNumCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 10,
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '0123456789',
                      suffixIcon: isResolving
                          ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)))
                          : const Icon(Icons.account_balance_wallet_outlined, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (v) {
                      if (v.length == 10) resolveAccount();
                    },
                  ),

                  if (resolvedAccountName.isNotEmpty) ...[
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
                            child: Text(resolvedAccountName, style: const TextStyle(color: Color(0xFF065F46), fontWeight: FontWeight.w800, fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),

                  const Text('Disbursement Amount (₦)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
                  const SizedBox(height: 6),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      prefixText: '₦ ',
                      hintText: '500,000',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isWithdrawing
                          ? null
                          : () async {
                              final amount = double.tryParse(amountCtrl.text.replaceAll(',', '').trim()) ?? 0;
                              if (amount < 1000) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Minimum withdrawal is ₦1,000')));
                                return;
                              }
                              if (amount > balance) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Insufficient escrow balance')));
                                return;
                              }
                              if (accNumCtrl.text.trim().length != 10) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid 10-digit account number')));
                                return;
                              }

                              setModalState(() => isWithdrawing = true);
                              try {
                                await ApiClient.post('/banking/withdraw', {
                                  'amount': amount,
                                  'bankCode': selectedBankCode,
                                  'bankName': selectedBankName,
                                  'accountNumber': accNumCtrl.text.trim(),
                                  'accountName': resolvedAccountName.isNotEmpty ? resolvedAccountName : 'Corporate Partner',
                                });

                                if (context.mounted) {
                                  Navigator.pop(ctx);
                                  _fetchAccount();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('💸 Milestone Payout of ${CurrencyFormatter.format(amount)} dispatched successfully!'),
                                      backgroundColor: const Color(0xFF059669),
                                    ),
                                  );
                                }
                              } catch (e) {
                                setModalState(() => isWithdrawing = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Withdrawal error: $e'),
                                    backgroundColor: const Color(0xFFDC2626),
                                  ),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: isWithdrawing
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Confirm & Disburse to Bank', style: TextStyle(fontWeight: FontWeight.w800)),
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

  void _showEditProfileModal(BuildContext context, Map<String, dynamic>? dev, String currentPhone) {
    final companyCtrl = TextEditingController(text: dev?['companyName'] ?? '');
    final addressCtrl = TextEditingController(text: dev?['officeAddress'] ?? '');
    final websiteCtrl = TextEditingController(text: dev?['website'] ?? '');
    final aboutCtrl = TextEditingController(text: dev?['about'] ?? '');
    final phoneCtrl = TextEditingController(text: currentPhone);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
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
                    const Text('Edit Corporate Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                    IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const Text('Update your registered corporate details and official contact addresses.', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                const SizedBox(height: 16),

                TextField(
                  controller: companyCtrl,
                  decoration: InputDecoration(
                    labelText: 'Company / Developer Name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: addressCtrl,
                  decoration: InputDecoration(
                    labelText: 'Head Office / Business Address',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Corporate Contact Phone',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: websiteCtrl,
                  keyboardType: TextInputType.url,
                  decoration: InputDecoration(
                    labelText: 'Official Website',
                    hintText: 'https://...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: aboutCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Company Overview / Track Record',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        await ApiClient.put('/users/profile', {
                          'companyName': companyCtrl.text.trim(),
                          'businessAddress': addressCtrl.text.trim(),
                          'officeAddress': addressCtrl.text.trim(),
                          'phone': phoneCtrl.text.trim(),
                          'website': websiteCtrl.text.trim(),
                          'about': aboutCtrl.text.trim(),
                        });
                        if (context.mounted) {
                          final authProvider = Provider.of<AuthProvider>(context, listen: false);
                          await authProvider.refreshUser();
                          Navigator.pop(ctx);
                          _fetchProfileStats();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('🎉 Corporate profile updated successfully!'),
                              backgroundColor: Color(0xFF059669),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(e.toString().replaceAll('Exception: ', '')),
                              backgroundColor: const Color(0xFFDC2626),
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Save Corporate Changes', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showChangePasswordModal(BuildContext context) {
    final currentPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Change Account Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                      IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const Text('Enter your current password and set a new secure password.', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                  const SizedBox(height: 16),

                  TextField(
                    controller: currentPassCtrl,
                    obscureText: obscureCurrent,
                    decoration: InputDecoration(
                      labelText: 'Current Password',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      suffixIcon: IconButton(
                        icon: Icon(obscureCurrent ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                        onPressed: () => setModalState(() => obscureCurrent = !obscureCurrent),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: newPassCtrl,
                    obscureText: obscureNew,
                    decoration: InputDecoration(
                      labelText: 'New Password (min 6 chars)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      suffixIcon: IconButton(
                        icon: Icon(obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                        onPressed: () => setModalState(() => obscureNew = !obscureNew),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: confirmPassCtrl,
                    obscureText: obscureNew,
                    decoration: InputDecoration(
                      labelText: 'Confirm New Password',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (currentPassCtrl.text.isEmpty || newPassCtrl.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please fill all password fields')),
                          );
                          return;
                        }
                        if (newPassCtrl.text != confirmPassCtrl.text) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('New passwords do not match')),
                          );
                          return;
                        }

                        try {
                          await ApiClient.post('/auth/change-password', {
                            'currentPassword': currentPassCtrl.text.trim(),
                            'newPassword': newPassCtrl.text.trim(),
                          });
                          if (context.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('🔒 Password changed successfully!'),
                                backgroundColor: Color(0xFF059669),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(e.toString().replaceAll('Exception: ', '')),
                                backgroundColor: const Color(0xFFDC2626),
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Update Password', style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showFactsFaqModal(BuildContext context) {
    final faqs = [
      {
        'q': 'How are construction milestone payouts disbursed?',
        'a': 'When you submit a milestone completion request with site photos, a certified Hometrust engineer audits the site. Upon verification, the escrow funds for that specific tranche are unlocked directly to your designated corporate bank account.',
      },
      {
        'q': 'What is the subscriber 3-day inspection window?',
        'a': 'After Hometrust certifies a construction milestone, verified subscribers have a 3-day window to view progress updates before the funds are released from the arbiter vault.',
      },
      {
        'q': 'How do Pay-Small-Small projects work for developers?',
        'a': 'You can list fully titled land plots or residential units for installment sales. Buyers pay initial deposits and monthly installments into the dedicated escrow ledger. You receive structured scheduled tranches.',
      },
      {
        'q': 'How are my title and survey documents protected from forgery?',
        'a': 'All documents uploaded to Hometrust are rendered in a secure read-only cloud container with dynamic buyer watermarks and encrypted viewing tokens. Buyers cannot download or replicate raw source documents.',
      },
      {
        'q': 'What are the criteria for Full Developer KYB Certification?',
        'a': 'Full verification requires: (1) Valid CAC Incorporation Certificate (RC Number), (2) Director National Identity (NIN/BVN), (3) Verified Corporate Head Office Address, and (4) Clean land title track record.',
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.help_center_rounded, color: Color(0xFF0284C7)),
                      SizedBox(width: 8),
                      Text('Developer Facts & Operating Rules', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                    ],
                  ),
                  IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const Text('Frequently Asked Questions regarding Hometrust Escrow, KYB, and Milestone payouts.', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
              const SizedBox(height: 16),

              Expanded(
                child: ListView.separated(
                  itemCount: faqs.length,
                  separatorBuilder: (_, __) => const Divider(height: 16, color: Color(0xFFF1F5F9)),
                  itemBuilder: (context, idx) {
                    final item = faqs[idx];
                    return ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: Text(item['q']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            item['a']!,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.45),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPrivacyPolicyModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.privacy_tip_outlined, color: Color(0xFF059669)),
              SizedBox(width: 8),
              Text('Developer Privacy & NDPR', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
            ],
          ),
          content: const SingleChildScrollView(
            child: Text(
              'Hometrust is strictly compliant with the Nigeria Data Protection Act (NDPA) and NDPR regulations.\n\n'
              '1. Corporate Data Protection: Your uploaded corporate incorporation instruments, director identities, and banking details are encrypted with AES-256 bank-grade cryptography.\n\n'
              '2. Anti-Forgery Watermarking: All property titles and architectural plans you provide are rendered strictly through secure read-only streams with active buyer identity watermarking to eliminate forgery risks.\n\n'
              '3. Arbiter Confidentiality: Payout requests, milestone escrow releases, and banking virtual account ledgers are strictly accessible only to your authorized directors and the designated Hometrust escrow trustees.',
              style: TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.5),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('I Understand', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF059669))),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    final dev = _stats?['developer'] as Map<String, dynamic>?;
    final vba = _stats?['virtualAccount'] as Map<String, dynamic>?;

    final companyName = dev?['companyName'] ?? user?.developerCompanyName ?? (user != null ? '${user.firstName} ${user.lastName} Developments' : 'Developer Account');
    final cacNumber = dev?['cacNumber'] ?? 'Not registered';
    final contactPerson = dev?['contactPerson'] ?? user?.fullName ?? 'Lead Director';
    final officeAddress = dev?['officeAddress'] ?? 'Corporate Head Office';
    final phone = user?.phone ?? dev?['phone'] ?? 'Not provided';
    final isVerified = dev?['isVerified'] ?? user?.isVerified ?? false;

    final acctNum = vba?['accountNumber']?.toString() ?? user?.virtualAccountNumber;
    final bankName = vba?['bankName']?.toString() ?? user?.virtualBankName ?? 'Providus Bank';
    final acctName = vba?['accountName']?.toString() ?? user?.virtualAccountName ?? 'Hometrust / $companyName';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Corporate Profile & Settings', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 18)),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchProfileStats,
        color: const Color(0xFF059669),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 1. CORPORATE HEADER CARD
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Icon(Icons.apartment_rounded, color: Colors.white, size: 28),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              companyName,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'CAC RC: $cacNumber',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isVerified
                                    ? const Color(0xFF059669).withValues(alpha: 0.1)
                                    : const Color(0xFFEF4444).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isVerified ? Icons.verified_rounded : Icons.warning_amber_rounded,
                                    size: 12,
                                    color: isVerified ? const Color(0xFF059669) : const Color(0xFFDC2626),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isVerified ? 'VERIFIED DEVELOPER' : 'KYB PENDING',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: isVerified ? const Color(0xFF059669) : const Color(0xFFDC2626),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24, color: Color(0xFFF1F5F9)),
                  _buildInfoRow('Contact Person', contactPerson),
                  const SizedBox(height: 8),
                  _buildInfoRow('Official Email', user?.email ?? 'developer@company.ng'),
                  const SizedBox(height: 8),
                  _buildInfoRow('Phone', phone),
                  const SizedBox(height: 8),
                  _buildInfoRow('Head Office', officeAddress),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showEditProfileModal(context, dev, phone),
                      icon: const Icon(Icons.edit_note_rounded, size: 18),
                      label: const Text('Edit Corporate Profile & Address', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 1.5. CORPORATE ESCROW WALLET & PROVISIONED MAPLERAD BANK ACCOUNT
            if (_loadingAccount)
              const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(strokeWidth: 2)))
            else if (_virtualAccount != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0B132B), Color(0xFF1C2541)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF064E3B),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.apartment_rounded, color: Color(0xFF34D399), size: 12),
                              SizedBox(width: 4),
                              Text('CORPORATE ESCROW VAULT', style: TextStyle(color: Color(0xFF34D399), fontSize: 9.5, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
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

                    // Corporate Escrow Balance
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('CORPORATE ESCROW BALANCE', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                            const SizedBox(height: 4),
                            Text(
                              _hideBalance ? '₦ ••••••••' : CurrencyFormatter.format(_virtualAccount!['balance'] ?? 0),
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

                    const Divider(height: 24, color: Color(0xFF334155)),

                    // Account Number with Copy
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('NUBAN ACCOUNT NUMBER', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text(
                              _virtualAccount!['accountNumber'] ?? '0281928391',
                              style: const TextStyle(color: Color(0xFF34D399), fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: () => _copyToClipboard(_virtualAccount!['accountNumber'] ?? '', 'Account Number'),
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

                    // Bank Name & Account Name
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          onTap: () => _copyToClipboard(_virtualAccount!['bankName'] ?? 'Providus Bank', 'Bank Name'),
                          child: Row(
                            children: [
                              const Icon(Icons.account_balance_rounded, color: Color(0xFF94A3B8), size: 13),
                              const SizedBox(width: 4),
                              Text(
                                _virtualAccount!['bankName'] ?? 'Providus Bank',
                                style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.copy_rounded, color: Color(0xFF64748B), size: 12),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () => _copyToClipboard(_virtualAccount!['accountName'] ?? companyName, 'Account Name'),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 150),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    _virtualAccount!['accountName'] ?? companyName,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 11, fontWeight: FontWeight.w600),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.copy_rounded, color: Color(0xFF64748B), size: 12),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.arrow_downward_rounded, size: 16),
                            label: const Text('Fund Account', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
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
                            label: const Text('Disburse / Payout', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)),
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
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.account_balance, color: Color(0xFF0284C7), size: 28),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Corporate Escrow Vault', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0284C7))),
                          SizedBox(height: 2),
                          Text('Complete KYB verification to activate your corporate virtual account.', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const KycScreen())).then((_) => _fetchAccount());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      child: const Text('Start KYB', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),

            // 2. SWITCH TO BUYER MODE TOGGLE
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0284C7).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.swap_horiz_rounded, color: Color(0xFF0284C7), size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Switch to Buyer Mode', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                        SizedBox(height: 2),
                        Text('Browse properties and explore investments as a verified buyer.', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      authProvider.toggleDeveloperMode();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Switched to Buyer Mode — you can switch back in Profile anytime.'),
                          backgroundColor: Color(0xFF0F172A),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: const Text('Switch', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 3. SETTLEMENT BANK ACCOUNT & NUBAN
            const Text('Settlement Banking & Payouts', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Dedicated Escrow Virtual Account', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF059669))),
                      Icon(Icons.shield_outlined, color: Color(0xFF059669), size: 16),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (acctNum != null && acctNum.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Account Number', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                            const SizedBox(height: 2),
                            Text(acctNum, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: 1.2)),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, color: Color(0xFF059669), size: 18),
                          onPressed: () => _copyToClipboard(acctNum, 'Account Number'),
                        ),
                      ],
                    ),
                    const Divider(height: 16, color: Color(0xFFF1F5F9)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('$bankName • $acctName', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, color: Color(0xFF059669), size: 16),
                          onPressed: () => _copyToClipboard('$bankName\n$acctNum\n$acctName', 'All Account Details'),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ] else
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text(
                              'Virtual NUBAN will be assigned upon KYB compliance approval.',
                              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const KycScreen()));
                            },
                            child: const Text('Verify KYB', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF059669))),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 4. ACCOUNT SECURITY & CORPORATE COMPLIANCE MENU
            const Text('Security, Governance & Facts', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _buildMenuTile(
                    icon: Icons.lock_outline_rounded,
                    color: const Color(0xFF475569),
                    title: 'Change Password',
                    subtitle: 'Update your corporate account login credentials',
                    onTap: () => _showChangePasswordModal(context),
                  ),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  _buildMenuTile(
                    icon: Icons.verified_user_outlined,
                    color: const Color(0xFF059669),
                    title: 'Corporate KYB & Director Verification',
                    subtitle: isVerified ? 'Verified Active Corporate Account' : 'Upload CAC & Director Documents',
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const KycScreen()));
                    },
                  ),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  _buildMenuTile(
                    icon: Icons.help_outline_rounded,
                    color: const Color(0xFF0284C7),
                    title: 'Developer Facts & Operating FAQs',
                    subtitle: 'Escrow release schedules, milestone audits & payouts',
                    onTap: () => _showFactsFaqModal(context),
                  ),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  _buildMenuTile(
                    icon: Icons.privacy_tip_outlined,
                    color: const Color(0xFFD97706),
                    title: 'Privacy Policy & NDPR Terms',
                    subtitle: 'Data governance and anti-forgery vault security',
                    onTap: () => _showPrivacyPolicyModal(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 5. LOGOUT BUTTON
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await authProvider.logout();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                },
                icon: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 18),
                label: const Text('Log Out of Developer Account', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w800)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFCA5A5)),
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

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
      trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF94A3B8)),
      onTap: onTap,
    );
  }
}

