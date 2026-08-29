import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/constants/colors.dart';
import '../core/utils/currency_formatter.dart';
import '../core/network/api_client.dart';
import '../providers/purchase_provider.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';

class PurchasesScreen extends StatefulWidget {
  const PurchasesScreen({super.key});

  @override
  State<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.isAuthenticated) {
        Provider.of<PurchaseProvider>(context, listen: false).fetchMyPurchases();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final purchaseProvider = Provider.of<PurchaseProvider>(context);

    if (!auth.isAuthenticated) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text('My Purchases & Instalments', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 17)),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline_rounded, size: 56, color: AppColors.primary),
                const SizedBox(height: 16),
                const Text('Sign In to View Purchases', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                const Text('Access your payment schedule, receipts, and agreement records.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: const Text('Sign In / Register', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('My Purchases & Instalments', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 17)),
      ),
      body: RefreshIndicator(
        onRefresh: () => purchaseProvider.fetchMyPurchases(),
        child: purchaseProvider.userPurchases.isEmpty
            ? const Center(
                child: Text('No active purchases yet. Explore properties to start.', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: purchaseProvider.userPurchases.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final p = purchaseProvider.userPurchases[index];
                  final propTitle = p.property?.title ?? p.projectUnit?.name ?? 'Property Unit';

                  return Container(
                    padding: const EdgeInsets.all(18),
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
                            Text(p.purchaseCode, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.primary)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: p.status == 'COMPLETED' ? AppColors.emeraldBg : AppColors.blueBg,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                p.status.replaceAll('_', ' '),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: p.status == 'COMPLETED' ? AppColors.emeraldText : AppColors.blueText,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(propTitle, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textPrimary)),
                        const SizedBox(height: 14),

                        // Progress Bar
                        LinearProgressIndicator(
                          value: p.progressPercentage,
                          backgroundColor: AppColors.background,
                          valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                          borderRadius: BorderRadius.circular(4),
                          minHeight: 8,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${(p.progressPercentage * 100).toInt()}% Paid', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.emeraldText)),
                            Text('Total: ${CurrencyFormatter.format(p.totalPrice)}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          ],
                        ),

                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('AMOUNT PAID', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                                  Text(CurrencyFormatter.format(p.amountPaid), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.emeraldText)),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text('OUTSTANDING BALANCE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                                  Text(CurrencyFormatter.format(p.outstandingBalance), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),
                        // Pay Next Instalment CTA
                        if (p.outstandingBalance > 0 && p.nextPaymentAmount != null) ...[
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _showPaymentOptions(context, p),
                                  icon: const Icon(Icons.payment_rounded, size: 16, color: Colors.white),
                                  label: Text(
                                    'Pay (${CurrencyFormatter.format(p.nextPaymentAmount)})',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  void _showPaymentOptions(BuildContext context, dynamic purchase) {
    // HomeVerify uses Fincra Dedicated Virtual Accounts only.
    // Show DVA bank details directly without any card option.
    _showVirtualAccountDialog(context, purchase);
  }

  void _showVirtualAccountDialog(BuildContext context, dynamic purchase) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Fetch the user's existing Fincra dedicated virtual account
      final res = await ApiClient.get('/banking/my-account');
      if (mounted) Navigator.pop(context); // Close loading

      if (res == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You do not have a dedicated account yet. Please complete KYC from your Profile first.'),
              backgroundColor: AppColors.roseText,
            ),
          );
        }
        return;
      }

      final bankName = res['bankName'] ?? res['bank']?['name'] ?? 'Providus Bank';
      final accountNumber = res['accountNumber'] ?? res['account_number'] ?? '';
      final accountName = res['accountName'] ?? res['account_name'] ?? user?.fullName ?? 'HomeVerify Customer';

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: const [
                Icon(Icons.account_balance, color: AppColors.primary),
                SizedBox(width: 8),
                Text('Pay via Bank Transfer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Transfer exactly ${CurrencyFormatter.format(purchase.nextPaymentAmount)} to your dedicated account:',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF1E293B)]),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('BANK', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8))),
                      Text(bankName, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 10),
                      const Text('ACCOUNT NUMBER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8))),
                      Row(
                        children: [
                          Text(
                            accountNumber,
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 2),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: accountNumber));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Account number copied!')),
                              );
                            },
                            child: const Icon(Icons.copy_rounded, color: Color(0xFF34D399), size: 20),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text('ACCOUNT NAME', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8))),
                      Text(accountName, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Your instalment ledger updates automatically once your transfer is confirmed by our system.',
                  style: TextStyle(fontSize: 11, color: AppColors.emeraldText, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not load account details: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: AppColors.roseText,
        ),
      );
    }
  }
}
