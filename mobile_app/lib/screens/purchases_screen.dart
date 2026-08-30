import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/constants/colors.dart';
import '../core/utils/currency_formatter.dart';
import '../core/network/api_client.dart';
import '../providers/purchase_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/persistent_bottom_nav.dart';
import 'login_screen.dart';
import 'provisional_allocation_screen.dart';
import 'contract_of_sale_screen.dart';
import 'receipts_ledger_screen.dart';
import 'subscriber_milestone_review_modal.dart';

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

  void _showPaymentOptions(BuildContext context, dynamic purchase) {
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
      final res = await ApiClient.get('/banking/my-account');
      if (!mounted) return;
      Navigator.pop(context); // Close loading

      if (res == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You do not have a dedicated account yet. Please complete KYC from your Profile first.'),
            backgroundColor: AppColors.roseText,
          ),
        );
        return;
      }

      final bankName = res['bankName'] ?? res['bank']?['name'] ?? user?.virtualBankName ?? 'Dedicated Escrow Bank';
      final accountNumber = res['accountNumber'] ?? res['account_number'] ?? user?.virtualAccountNumber ?? '';
      final accountName = res['accountName'] ?? res['account_name'] ?? user?.fullName ?? 'Hometrust Customer';

      if (!mounted) return;
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
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not load account details: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: AppColors.roseText,
        ),
      );
    }
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
        bottomNavigationBar: const PersistentBottomNav(activeIndex: 3),
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
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ESCROW PROTECTION BANNER
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.shield_outlined, color: Color(0xFFDC2626), size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'ESCROW PROTECTION PROTOCOL',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF991B1B)),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'All payments must be made strictly via your dedicated Hometrust virtual bank account. Direct payments to developers void all escrow warranties and cannot be refunded.',
                          style: TextStyle(fontSize: 11, color: Color(0xFFB91C1C), height: 1.35, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (purchaseProvider.userPurchases.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text('No active purchases yet. Explore properties to start.', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                ),
              )
            else
              ...purchaseProvider.userPurchases.map((p) {
                final propTitle = p.property?.title ?? p.projectUnit?.name ?? 'Property Unit';

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
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
                              p.status,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 10,
                                color: p.status == 'COMPLETED' ? AppColors.emeraldText : AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(propTitle, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textPrimary)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Payment Progress: ${(p.progressPercentage * 100).toInt()}%',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          ),
                          Text(
                            '${p.payments.length} Payments Recorded',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: p.progressPercentage,
                          minHeight: 6,
                          backgroundColor: AppColors.background,
                          valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                        ),
                      ),
                      const SizedBox(height: 14),
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
                      // Document & Legal Assurance Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProvisionalAllocationScreen(
                                      purchaseId: p.id,
                                      purchaseCode: p.purchaseCode,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.verified_outlined, size: 14, color: Color(0xFF059669)),
                              label: const Text('Allocation', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFF059669))),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF34D399)),
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ContractOfSaleScreen(
                                      purchaseId: p.id,
                                      purchaseCode: p.purchaseCode,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.gavel_rounded, size: 14, color: Color(0xFF0284C7)),
                              label: const Text('Contract', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFF0284C7))),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF38BDF8)),
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ReceiptsLedgerScreen(
                                      purchaseId: p.id,
                                      purchaseCode: p.purchaseCode,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.receipt_long_rounded, size: 14, color: Color(0xFFD97706)),
                              label: const Text('Ledger', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFFD97706))),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFFBBF24)),
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Construction Milestone Review & Consensus Action
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _showMilestonesReviewModal(p),
                          icon: const Icon(Icons.foundation_rounded, size: 16, color: Color(0xFF059669)),
                          label: const Text(
                            'Review Construction Milestones & Tranches',
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF059669)),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFA7F3D0)),
                            backgroundColor: const Color(0xFFECFDF5),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),

                      if (p.outstandingBalance > 0 && p.nextPaymentAmount != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _showPaymentOptions(context, p),
                                icon: const Icon(Icons.payment_rounded, size: 16, color: Colors.white),
                                label: Text(
                                  'Pay Next Tranche (${CurrencyFormatter.format(p.nextPaymentAmount)})',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
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
              }).toList(),
          ],
        ),
      ),
      bottomNavigationBar: const PersistentBottomNav(activeIndex: 3),
    );
  }

  void _showMilestonesReviewModal(dynamic purchase) async {
    final projectId = purchase.projectUnit?.projectId ?? purchase.propertyId ?? '';
    final propTitle = purchase.property?.title ?? purchase.projectUnit?.name ?? purchase.purchaseCode;

    if (projectId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active off-plan project link found for this unit')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFF059669))),
    );

    try {
      final milestones = await ApiClient.get('/purchases/projects/$projectId/milestones');
      if (!mounted) return;
      Navigator.pop(context); // close loader

      final list = milestones is List ? milestones : [];

      if (list.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No construction milestones registered for this project yet.')),
        );
        return;
      }

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Project Milestone Proof & Reviews',
                            style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            propTitle,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF059669), fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.2)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.verified_user_rounded, color: Color(0xFF059669), size: 18),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Your funds remain securely locked in Hometrust escrow. Review live 360° site videos and certified engineer sign-offs before approving tranche releases.',
                          style: TextStyle(fontSize: 11, color: Color(0xFF065F46), height: 1.35),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                Expanded(
                  child: ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, idx) {
                      final m = list[idx] as Map<String, dynamic>;
                      final status = m['status'] ?? 'PENDING';
                      final isInReview = status == 'IN_REVIEW';
                      final isDisbursed = status == 'DISBURSED' || status == 'COMPLETED';

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isInReview
                              ? const Color(0xFFFFFBEB)
                              : (isDisbursed ? const Color(0xFFECFDF5) : const Color(0xFFF8FAFC)),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isInReview
                                ? const Color(0xFFFDE68A)
                                : (isDisbursed ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0)),
                            width: isInReview ? 1.5 : 1.0,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '${idx + 1}. ${m['title'] ?? 'Milestone'}',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isInReview
                                        ? const Color(0xFFD97706)
                                        : (isDisbursed ? const Color(0xFF059669) : const Color(0xFF64748B)),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isInReview ? '5-DAY REVIEW OPEN' : (isDisbursed ? 'ESCROW DISBURSED' : status),
                                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            if (m['corenEngineerName'] != null)
                              Text(
                                'Certified by: ${m['corenEngineerName']} (${m['corenLicenseNumber'] ?? 'COREN'})',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF475569), fontWeight: FontWeight.w600),
                              ),
                            const SizedBox(height: 10),

                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (_) => SubscriberMilestoneReviewModal(
                                      milestone: m,
                                      projectName: propTitle,
                                      onVoted: () {
                                        Provider.of<PurchaseProvider>(context, listen: false).fetchMyPurchases();
                                      },
                                    ),
                                  );
                                },
                                icon: Icon(
                                  isInReview ? Icons.how_to_vote_rounded : Icons.visibility_outlined,
                                  size: 16,
                                ),
                                label: Text(
                                  isInReview ? 'Review Proof & Cast Vote' : 'View Milestone Details & Reports',
                                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isInReview ? const Color(0xFF059669) : const Color(0xFF0F172A),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }
}
