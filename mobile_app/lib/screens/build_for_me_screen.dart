import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/colors.dart';
import '../core/network/api_client.dart';
import '../core/utils/currency_formatter.dart';
import '../providers/auth_provider.dart';
import 'create_build_request_screen.dart';
import 'chat_screen.dart';
import 'wallet_screen.dart';

class BuildForMeScreen extends StatefulWidget {
  const BuildForMeScreen({super.key});

  @override
  State<BuildForMeScreen> createState() => _BuildForMeScreenState();
}

class _BuildForMeScreenState extends State<BuildForMeScreen> {
  List<dynamic> _builds = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchBuilds();
  }

  Future<void> _fetchBuilds() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isAuthenticated) return;

    setState(() => _loading = true);
    try {
      final res = await ApiClient.get('/build/my-builds');
      if (mounted) {
        setState(() {
          _builds = (res != null && res is List) ? res : [];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _payConsultation(String requestId) async {
    showDialog(
      context: context,
      builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );

    try {
      final res = await ApiClient.post('/build/requests/$requestId/pay-consultation', {});
      if (mounted) {
        Navigator.pop(context); // close loader
        if (res['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('₦50,000 consultation paid! A vetted COREN structural engineer has been assigned to your project ✅'),
              backgroundColor: Color(0xFF059669),
            ),
          );
          _fetchBuilds();
        } else if (res['code'] == 'INSUFFICIENT_FUNDS') {
          final reqAmt = (res['requiredAmount'] as num?)?.toDouble() ?? 50000.0;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Insufficient wallet balance. You need ${CurrencyFormatter.format(reqAmt)} in your Escrow account.'),
              backgroundColor: const Color(0xFFEF4444),
              action: SnackBarAction(
                label: 'Fund Wallet',
                textColor: Colors.white,
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen())),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: const Color(0xFFEF4444)),
        );
      }
    }
  }

  Future<void> _fundMilestone(String milestoneId, double amount) async {
    showDialog(
      context: context,
      builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );

    try {
      final res = await ApiClient.post('/build/milestones/$milestoneId/fund', {});
      if (mounted) {
        Navigator.pop(context);
        if (res['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${CurrencyFormatter.format(amount)} funded & locked in Escrow! Contractor authorized to build ✅'),
              backgroundColor: const Color(0xFF059669),
            ),
          );
          _fetchBuilds();
        } else if (res['code'] == 'INSUFFICIENT_FUNDS') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Insufficient wallet balance to fund this milestone (${CurrencyFormatter.format(amount)} needed).'),
              backgroundColor: const Color(0xFFEF4444),
              action: SnackBarAction(
                label: 'Fund Wallet',
                textColor: Colors.white,
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen())),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: const Color(0xFFEF4444)),
        );
      }
    }
  }

  Future<void> _authorizeDisbursement(String milestoneId, String stageTitle, double amount) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Authorize Milestone Payout', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        content: Text(
          'Are you satisfied with the independent structural inspection and video walkthrough for "$stageTitle"?\n\nAuthorizing will release ${CurrencyFormatter.format(amount)} from escrow to the builder.',
          style: const TextStyle(fontSize: 12.5, height: 1.4),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Authorize Payout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ApiClient.post('/build/milestones/$milestoneId/authorize-disbursement', {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Milestone funds disbursed to builder successfully ✅'), backgroundColor: Color(0xFF059669)),
        );
        _fetchBuilds();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: const Color(0xFFEF4444)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Charter A Builder', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Color(0xFF0F172A))),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: _fetchBuilds,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchBuilds,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Value Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 12, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.apartment_rounded, color: Color(0xFF34D399), size: 22),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Hometrust Build-For-Me™', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                              Text('Managed Construction • Escrow Custody', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Don’t risk your life savings with unverified contractors. We assign an accredited COREN engineer, audit materials, and hold every milestone payment in secure escrow until verified by independent structural surveyors.',
                      style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 11.5, height: 1.5),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final res = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CreateBuildRequestScreen()),
                          );
                          if (res != null) _fetchBuilds();
                        },
                        icon: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                        label: const Text('Start New Building Project', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Active Projects Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('My Building Projects', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                  Text('${_builds.length} Active', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                ],
              ),
              const SizedBox(height: 12),

              if (_loading)
                const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)))
              else if (_builds.isEmpty)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    margin: const EdgeInsets.only(top: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.architecture_rounded, size: 48, color: Color(0xFF94A3B8)),
                        const SizedBox(height: 12),
                        const Text('No Custom Projects Yet', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                        const SizedBox(height: 6),
                        const Text(
                          'Have a plot of land or want to build in Nigeria? Click above to charter a vetted engineer and manage your construction safely in escrow.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _builds.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final b = _builds[index];
                    final title = b['projectTitle'] ?? 'Custom Build';
                    final code = b['requestCode'] ?? '';
                    final budget = (b['estimatedBudget'] as num?)?.toDouble() ?? 0.0;
                    final progress = (b['progressPercentage'] as num?)?.toInt() ?? 0;
                    final status = b['status'] ?? 'REQUESTED';
                    final isConsultationPaid = b['isConsultationPaid'] == true;
                    final milestones = (b['milestones'] as List?) ?? [];
                    final engineer = b['assignedEngineer'];

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2)),
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
                                  color: const Color(0xFF0F172A),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(code, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isConsultationPaid ? const Color(0xFF10B981).withValues(alpha: 0.12) : const Color(0xFFF59E0B).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  status.replaceAll('_', ' '),
                                  style: TextStyle(
                                    color: isConsultationPaid ? const Color(0xFF059669) : const Color(0xFFD97706),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                          const SizedBox(height: 4),
                          Text(
                            '${b['buildingType']?.replaceAll('_', ' ')} • ${b['city']}, ${b['state']}',
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 12),

                          // Budget & Progress
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Estimated Budget', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w700)),
                                  Text(
                                    CurrencyFormatter.format(budget),
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text('Milestones Done', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w700)),
                                  Text(
                                    '$progress% Complete',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF059669)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: progress / 100,
                              minHeight: 6,
                              backgroundColor: const Color(0xFFE2E8F0),
                              color: const Color(0xFF059669),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Assigned Engineer Card or Pay Consultation
                          if (!isConsultationPaid) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFBEB),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFFCD34D)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.engineering_rounded, color: Color(0xFFD97706), size: 20),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text(
                                      'Pay ₦50,000 Consultation fee to match with a vetted COREN Engineer.',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF92400E)),
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => _payConsultation(b['id']),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFD97706),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      elevation: 0,
                                    ),
                                    child: const Text('Pay ₦50k', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            // Assigned Engineer Card with Live Chat & Call
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: const BoxDecoration(color: Color(0xFF0F172A), shape: BoxShape.circle),
                                    child: const Center(child: Icon(Icons.person_rounded, color: Colors.white, size: 18)),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          engineer != null ? '${engineer['firstName']} ${engineer['lastName']}' : 'Engr. Adeyemi (COREN Reg.)',
                                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                                        ),
                                        const Text('Assigned Project Engineer', style: TextStyle(fontSize: 10, color: Color(0xFF059669), fontWeight: FontWeight.w700)),
                                      ],
                                    ),
                                  ),
                                  // Chat Button
                                  IconButton(
                                    icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primary, size: 20),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ChatScreen(
                                            recipientId: engineer?['id'],
                                            recipientName: engineer != null ? '${engineer['firstName']} ${engineer['lastName']}' : 'Project Engineer',
                                            recipientRole: 'COREN Engineer',
                                            propertyTitle: title,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 16),
                          const Divider(height: 1, color: Color(0xFFE2E8F0)),
                          const SizedBox(height: 12),

                          // Milestone List
                          const Text('Construction Milestones & Escrow Phases', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                          const SizedBox(height: 8),

                          ...milestones.map((m) {
                            final mStage = m['stageNumber'] ?? 1;
                            final mTitle = m['title'] ?? 'Phase';
                            final mAmount = (m['amount'] as num?)?.toDouble() ?? 0.0;
                            final mStatus = m['status'] ?? 'PENDING_DEPOSIT';

                            final isFunded = mStatus == 'FUNDED_IN_ESCROW';
                            final isAuditReady = mStatus == 'AUDIT_SUBMITTED';
                            final isDisbursed = mStatus == 'DISBURSED';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isDisbursed
                                    ? const Color(0xFFECFDF5)
                                    : (isAuditReady ? const Color(0xFFEFF6FF) : const Color(0xFFFAFAFA)),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isDisbursed
                                      ? const Color(0xFF34D399)
                                      : (isAuditReady ? const Color(0xFF38BDF8) : const Color(0xFFE2E8F0)),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: isDisbursed ? const Color(0xFF10B981) : const Color(0xFF64748B),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text('$mStage', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(mTitle, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                                        Text('${CurrencyFormatter.format(mAmount)} • ${mStatus.replaceAll('_', ' ')}',
                                            style: TextStyle(
                                                fontSize: 10,
                                                color: isDisbursed
                                                    ? const Color(0xFF059669)
                                                    : (isFunded ? const Color(0xFF0284C7) : const Color(0xFF64748B)),
                                                fontWeight: FontWeight.w700)),
                                      ],
                                    ),
                                  ),
                                  if (mStatus == 'PENDING_DEPOSIT' && isConsultationPaid)
                                    ElevatedButton(
                                      onPressed: () => _fundMilestone(m['id'], mAmount),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                        elevation: 0,
                                      ),
                                      child: const Text('Fund Escrow', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                                    )
                                  else if (isAuditReady)
                                    ElevatedButton(
                                      onPressed: () => _authorizeDisbursement(m['id'], mTitle, mAmount),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF059669),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                        elevation: 0,
                                      ),
                                      child: const Text('Authorize Payout', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                                    )
                                  else if (isDisbursed)
                                    const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 18),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
