import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/colors.dart';
import '../core/utils/currency_formatter.dart';
import '../core/network/api_client.dart';
import '../models/project_model.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'chat_screen.dart';
import '../widgets/in_app_call_modal.dart';
import '../widgets/persistent_bottom_nav.dart';
import 'purchases_screen.dart';
import 'inspection_booking_modal.dart';

class ProjectDetailScreen extends StatefulWidget {
  final ProjectModel project;

  const ProjectDetailScreen({super.key, required this.project});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  Map<String, dynamic>? _matrixData;
  bool _loadingMatrix = false;

  @override
  void initState() {
    super.initState();
    _fetchUnitsMatrix();
  }

  Future<void> _fetchUnitsMatrix() async {
    setState(() => _loadingMatrix = true);
    try {
      final data = await ApiClient.get('/projects/${widget.project.id}/units-matrix');
      if (mounted) {
        setState(() {
          _matrixData = data;
          _loadingMatrix = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingMatrix = false);
    }
  }

  void _lockUnitModal(dynamic unit) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isAuthenticated) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }

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
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Lock In & Reserve ${unit['unitCode'] ?? unit['name']}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF059669).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF059669)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.timer_outlined, color: Color(0xFF059669), size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '30-Minute Atomic Lock: This unit will be held exclusively for you. Other buyers cannot reserve it while your transfer clears.',
                        style: TextStyle(fontSize: 11.5, color: Color(0xFF065F46), fontWeight: FontWeight.w700, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _row('Unit Type', unit['unitType'] ?? unit['name']),
              _row('Total Purchase Price', CurrencyFormatter.format((unit['price'] as num?)?.toDouble() ?? 0)),
              _row('Initial Commitment Deposit', CurrencyFormatter.format((unit['initialDeposit'] as num?)?.toDouble() ?? 0)),
              _row('Monthly Instalment', '${CurrencyFormatter.format((unit['monthlyInstalment'] as num?)?.toDouble() ?? 0)}/mo (${unit['durationMonths'] ?? 12} mos)'),
              const Divider(height: 24),
              const Text(
                'Instant Provisional Allocation Letter & Tri-Partite Contract of Sale are automatically generated upon deposit receipt.',
                style: TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.3),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    try {
                      await ApiClient.post('/purchases', {
                        'projectUnitId': unit['id'],
                      });
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('🎉 Unit reserved! Proceeding to your Purchases & Escrow portal.'),
                            backgroundColor: Color(0xFF059669),
                          ),
                        );
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const PurchasesScreen()));
                      }
                    } catch (e) {
                      if (mounted) {
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
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Confirm 30-Min Lock & Reserve Unit',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          Text(value, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
        ],
      ),
    );
  }

  void _bookProjectInspection(BuildContext context) {
    InspectionBookingModal.show(
      context,
      projectId: widget.project.id,
      title: widget.project.name,
      location: '${widget.project.area}, ${widget.project.city}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final project = widget.project;
    final units = (_matrixData?['units'] as List?) ?? [];
    final availableCount = _matrixData?['availableUnits'] ?? project.availableUnits;
    final totalCount = _matrixData?['totalUnits'] ?? project.totalUnits;
    final subscribedCount = _matrixData?['subscribedUnits'] ?? (totalCount - availableCount);

    return Scaffold(
      bottomNavigationBar: const PersistentBottomNav(),
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Text(
          project.name,
          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchUnitsMatrix,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Project Hero Image
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(
                  image: NetworkImage(project.firstImage),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title & Location
            Text(
              project.name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 16, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  '${project.area}, ${project.city}, ${project.state}',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── LIVE INVENTORY & CONCURRENCY COUNTER ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'LIVE INVENTORY MATRIX',
                        style: TextStyle(color: Color(0xFF38BDF8), fontSize: 10.5, fontWeight: FontWeight.w900, letterSpacing: 0.6),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '$availableCount / $totalCount AVAILABLE',
                          style: const TextStyle(color: Color(0xFF34D399), fontSize: 9.5, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _kpiItem('Total Plots/Units', '$totalCount Units'),
                      _kpiItem('Active Subscribed', '$subscribedCount Units', color: const Color(0xFFF87171)),
                      _kpiItem('Open for Lock-in', '$availableCount Units', color: const Color(0xFF34D399)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── INTERACTIVE UNIT SELECTOR GRID ──
            const Text(
              'Select Plot / Unit to Reserve',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 4),
            const Text(
              'Tap any available unit (green) to place an atomic 30-minute reservation lock.',
              style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 12),

            if (_loadingMatrix)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: AppColors.primary)))
            else if (units.isNotEmpty)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 1.1,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: units.length,
                itemBuilder: (context, idx) {
                  final u = units[idx];
                  final isAvail = u['status'] == 'AVAILABLE';
                  final isSubscribed = u['status'] == 'SUBSCRIBED';

                  return GestureDetector(
                    onTap: isAvail ? () => _lockUnitModal(u) : null,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isAvail
                            ? const Color(0xFF059669).withValues(alpha: 0.12)
                            : isSubscribed
                                ? const Color(0xFFEF4444).withValues(alpha: 0.12)
                                : const Color(0xFF64748B).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isAvail
                              ? const Color(0xFF059669)
                              : isSubscribed
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFF94A3B8),
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isAvail
                                ? Icons.check_circle_outline_rounded
                                : isSubscribed
                                    ? Icons.lock_rounded
                                    : Icons.block_rounded,
                            size: 16,
                            color: isAvail
                                ? const Color(0xFF059669)
                                : isSubscribed
                                    ? const Color(0xFFDC2626)
                                    : const Color(0xFF64748B),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            u['unitCode'] ?? '#${idx + 1}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: isAvail
                                  ? const Color(0xFF059669)
                                  : isSubscribed
                                      ? const Color(0xFFDC2626)
                                      : const Color(0xFF64748B),
                            ),
                          ),
                          Text(
                            isAvail ? 'OPEN' : (isSubscribed ? 'SOLD' : 'LOCKED'),
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              color: isAvail ? const Color(0xFF059669) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              )
            else
              ...project.units.map((unit) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(unit.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                          Text(
                            'Deposit: ${CurrencyFormatter.format(unit.initialDeposit)} • ${unit.durationMonths} Mos',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () => _lockUnitModal({
                          'id': unit.id,
                          'name': unit.name,
                          'price': unit.price,
                          'initialDeposit': unit.initialDeposit,
                          'monthlyInstalment': unit.monthlyInstalment,
                          'durationMonths': unit.durationMonths,
                        }),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Lock In', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
                      ),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 20),

            // ── VERIFIED PROJECT DOSSIER ──
            const Text(
              'Verified Project Dossier & Title Root',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                children: [
                  _dossierItem(Icons.verified_rounded, 'Governor’s Consent / C of O', 'Verified in State Lands Bureau Registry'),
                  const Divider(height: 18),
                  _dossierItem(Icons.architecture_rounded, 'State Planning Approval (LASPPPA)', 'Approved Architectural & Structural Drawings'),
                  const Divider(height: 18),
                  _dossierItem(Icons.radar_rounded, 'Registered Cadastral Survey Plan', 'Coordinates mapped on Hometrust Land Radar'),
                  const Divider(height: 18),
                  _dossierItem(Icons.shield_outlined, 'Milestone Escrow Undertaking', 'Tri-Partite Contract of Sale & Price Lock Active'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── DEVELOPER PAYMENT RULES & PENALTY TERMS ──
            const Text(
              'Developer Payment Rules & Protections',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFCD34D)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('• 14-Day Mandatory Grace Period: No late fees charged for instalments paid within 14 days of due date.', style: TextStyle(fontSize: 11, color: Color(0xFF78350F), height: 1.4)),
                  SizedBox(height: 6),
                  Text('• Price-Lock Covenant: Agreed purchase price is fixed and cannot be escalated due to building material inflation.', style: TextStyle(fontSize: 11, color: Color(0xFF78350F), height: 1.4)),
                  SizedBox(height: 6),
                  Text('• 90-Day Construction Delay Penalty: Developer is subject to penalties if milestone targets miss deadlines without verified Force Majeure.', style: TextStyle(fontSize: 11, color: Color(0xFF78350F), height: 1.4)),
                  SizedBox(height: 6),
                  Text('• Dispute Arbitration: Governed under the Nigerian Arbitration and Mediation Act 2023.', style: TextStyle(fontSize: 11, color: Color(0xFF78350F), height: 1.4)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Escrow Milestone Progress
            const Text(
              'Escrow Construction Milestones',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            ...project.milestones.map((m) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(m.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: m.status == 'COMPLETED' ? AppColors.emeraldBg : AppColors.background,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            m.status,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: m.status == 'COMPLETED' ? AppColors.emeraldText : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: m.percentage / 100,
                      backgroundColor: AppColors.background,
                      valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.cardBorder)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              // In-App Chat / Call Modal Trigger
              InkWell(
                onTap: () {
                  final devName = project.developer?.companyName ?? 'Verified Developer';
                  showModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (ctx) => Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            devName,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Encrypted In-App Communication • Phone Numbers Masked',
                            style: TextStyle(fontSize: 11, color: Color(0xFF059669), fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 20),
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primary),
                            ),
                            title: const Text('Chat In-App', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                            subtitle: const Text('Send instant messages to developer rep', style: TextStyle(fontSize: 12)),
                            onTap: () {
                              Navigator.pop(ctx);
                              final auth = Provider.of<AuthProvider>(context, listen: false);
                              if (!auth.isAuthenticated) {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                                return;
                              }
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatScreen(
                                    developerId: project.developer?.id,
                                    recipientName: devName,
                                    propertyTitle: project.name,
                                    projectId: project.id,
                                  ),
                                ),
                              );
                            },
                          ),
                          const Divider(),
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.phone_in_talk_rounded, color: Color(0xFF059669)),
                            ),
                            title: const Text('Call In-App', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                            subtitle: const Text('Encrypted audio relay (no phone number required)', style: TextStyle(fontSize: 12)),
                            onTap: () {
                              Navigator.pop(ctx);
                              final auth = Provider.of<AuthProvider>(context, listen: false);
                              if (!auth.isAuthenticated) {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                                return;
                              }
                              InAppCallModal.show(
                                context,
                                entityName: devName,
                                developerId: project.developer?.id,
                                projectId: project.id,
                                propertyTitle: project.name,
                              );
                            },
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.forum_rounded, color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _bookProjectInspection(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Book Site Visit Inspection', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kpiItem(String label, String value, {Color color = Colors.white}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }

  Widget _dossierItem(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF059669), size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
              Text(subtitle, style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
            ],
          ),
        ),
        const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 16),
      ],
    );
  }
}
