import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/colors.dart';
import '../core/utils/currency_formatter.dart';
import '../providers/property_provider.dart';
import '../providers/purchase_provider.dart';
import 'verify_screen.dart';
import 'land_radar_screen.dart';
import 'material_index_screen.dart';

class HomeScreen extends StatelessWidget {
  final Function(int)? onNavigateTab;

  const HomeScreen({super.key, this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    final propProvider = Provider.of<PropertyProvider>(context);
    final purchaseProvider = Provider.of<PurchaseProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.shield_rounded, color: Color(0xFF059669), size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'HomeVerify',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w900,
                fontSize: 19,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_none_rounded, color: Color(0xFF334155), size: 24),
                Positioned(
                  right: 2,
                  top: 2,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            onPressed: () {
              propProvider.fetchAll();
              purchaseProvider.fetchMyPurchases();
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            propProvider.fetchAll(),
            purchaseProvider.fetchMyPurchases(),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // SPOTLIGHT FEATURED HERO BANNER: 1. VERIFY DOCUMENTS
              _buildSpotlightHeroCard(context),
              const SizedBox(height: 16),

              // 2x2 BENTO BOX GRID: 2. Explore Properties, 3. Land Radar, 4. Material Index, 5. Off-Plan Projects
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // LEFT COLUMN
                  Expanded(
                    child: Column(
                      children: [
                        // 2. Explore Properties
                        _buildExploreBentoCard(context, propProvider),
                        const SizedBox(height: 14),
                        // 4. Material Index (with live chart sparkline)
                        _buildMaterialIndexBentoCard(context),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  // RIGHT COLUMN
                  Expanded(
                    child: Column(
                      children: [
                        // 3. Land Radar (with 3D concentric radar scan graphic)
                        _buildLandRadarBentoCard(context),
                        const SizedBox(height: 14),
                        // 5. Off-Plan Projects (with Escrow Shield Lock)
                        _buildOffPlanBentoCard(context, propProvider),
                      ],
                    ),
                  ),
                ],
              ),

              // ACTIVE PURCHASES SNAPSHOT (If user has ongoing purchases)
              if (purchaseProvider.userPurchases.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text(
                  'My Active Purchases & Instalments',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 135,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: purchaseProvider.userPurchases.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final p = purchaseProvider.userPurchases[index];
                      return Container(
                        width: 280,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  p.purchaseCode,
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppColors.primary),
                                ),
                                Text(
                                  '${(p.progressPercentage * 100).toInt()}% Paid',
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Color(0xFF059669)),
                                ),
                              ],
                            ),
                            Text(
                              p.property?.title ?? p.projectUnit?.name ?? 'Property Purchase',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            LinearProgressIndicator(
                              value: p.progressPercentage,
                              backgroundColor: const Color(0xFFF1F5F9),
                              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Paid: ${CurrencyFormatter.format(p.amountPaid)}',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                ),
                                Text(
                                  'Bal: ${CurrencyFormatter.format(p.outstandingBalance)}',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // 1. SPOTLIGHT FEATURED HERO BANNER
  Widget _buildSpotlightHeroCard(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const VerifyScreen()),
          );
        },
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              colors: [Color(0xFFECFDF5), Color(0xFFF0FDF4), Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: const Color(0xFFA7F3D0), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Verification Shield with Glow
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF34D399), Color(0xFF059669)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF059669).withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(Icons.verified_user_rounded, color: Colors.white, size: 32),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'FEATURED SPOTLIGHT',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF059669),
                            letterSpacing: 0.8,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Verify Documents',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.3,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'C-of-O & Survey Verification at Lands Registry',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF059669), size: 14),
                ],
              ),
              const SizedBox(height: 12),
              // Slider Indicator Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 20,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 6,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 6,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 2. EXPLORE PROPERTIES BENTO CARD
  Widget _buildExploreBentoCard(BuildContext context, PropertyProvider propProvider) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.04),
      child: InkWell(
        onTap: () {
          propProvider.clearFilters();
          onNavigateTab?.call(1);
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            gradient: const LinearGradient(
              colors: [Color(0xFFF0F9FF), Colors.white],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pill Switcher graphic
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.home_rounded, size: 14, color: Color(0xFF0284C7)),
                        SizedBox(width: 4),
                        Icon(Icons.search_rounded, size: 14, color: Color(0xFF0284C7)),
                      ],
                    ),
                  ),
                  const Icon(Icons.auto_awesome_rounded, size: 14, color: Color(0xFFF59E0B)),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Explore\nProperties',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '100% Vetted listings',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 3. LAND RADAR BENTO CARD
  Widget _buildLandRadarBentoCard(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.04),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LandRadarScreen()),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            gradient: const LinearGradient(
              colors: [Color(0xFFFAF5FF), Colors.white],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Land Radar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'FREE',
                      style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Color(0xFF7C3AED)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              const Text(
                'GPS Beacon Radar Scanner',
                style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              // 3D Concentric Radar Graphic
              Center(
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF10B981).withValues(alpha: 0.08),
                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3), width: 1.5),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        ),
                      ),
                      const Icon(Icons.radar_rounded, size: 28, color: Color(0xFF059669)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 4. MATERIAL INDEX BENTO CARD (WITH SPARKLINE CHART)
  Widget _buildMaterialIndexBentoCard(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.04),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MaterialIndexScreen()),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            gradient: const LinearGradient(
              colors: [Color(0xFFFFF7ED), Colors.white],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Material Index',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEA580C).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      '36 STATES',
                      style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Color(0xFFEA580C)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              const Text(
                'Live Construction Prices',
                style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 10),
              // Sparkline Trend Wave Graphic
              CustomPaint(
                size: const Size(double.infinity, 38),
                painter: _SparklinePainter(),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  const Text('Cement', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                  const SizedBox(width: 8),
                  Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF0284C7), shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  const Text('Rebar', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 5. OFF-PLAN PROJECTS BENTO CARD
  Widget _buildOffPlanBentoCard(BuildContext context, PropertyProvider propProvider) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.04),
      child: InkWell(
        onTap: () {
          propProvider.setFilters(listingType: 'OFF_PLAN');
          onNavigateTab?.call(1);
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            gradient: const LinearGradient(
              colors: [Color(0xFFFEF3C7), Colors.white],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Off-Plan\nProjects',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                      height: 1.2,
                    ),
                  ),
                  const Icon(Icons.auto_awesome_rounded, size: 14, color: Color(0xFFD97706)),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Milestone Escrow Locked',
                style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              // Glowing Shield Security Padlock Graphic
              Center(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                  ),
                  child: const Icon(Icons.lock_outline_rounded, color: Color(0xFF059669), size: 26),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Sparkline Painter for Material Index Chart
class _SparklinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cementPaint = Paint()
      ..color = const Color(0xFF10B981)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rebarPaint = Paint()
      ..color = const Color(0xFF0284C7)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Cement wave path
    final path1 = Path()
      ..moveTo(0, size.height * 0.75)
      ..quadraticBezierTo(size.width * 0.25, size.height * 0.2, size.width * 0.5, size.height * 0.5)
      ..quadraticBezierTo(size.width * 0.75, size.height * 0.85, size.width, size.height * 0.15);

    // Rebar wave path
    final path2 = Path()
      ..moveTo(0, size.height * 0.5)
      ..quadraticBezierTo(size.width * 0.3, size.height * 0.8, size.width * 0.6, size.height * 0.3)
      ..quadraticBezierTo(size.width * 0.85, size.height * 0.1, size.width, size.height * 0.45);

    canvas.drawPath(path1, cementPaint);
    canvas.drawPath(path2, rebarPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
