import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/colors.dart';
import '../core/utils/currency_formatter.dart';
import '../providers/property_provider.dart';
import '../providers/purchase_provider.dart';
import 'verify_screen.dart';
import 'legal_request_screen.dart';
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.shield_rounded, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 8),
            const Text(
              'HomeVerify',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 18,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            onPressed: () {
              propProvider.fetchAll();
              purchaseProvider.fetchMyPurchases();
            },
          ),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HERO BANNER
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accentGold.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.4)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_user_rounded, color: AppColors.accentGoldLight, size: 12),
                          SizedBox(width: 4),
                          Text(
                            'NIGERIA REAL ESTATE DUE DILIGENCE & ESCROW',
                            style: TextStyle(
                              color: AppColors.accentGoldLight,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Verify Title Deeds.\nPay in Milestone Escrow.',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Protect yourself from fake land titles, double-selling & contractor abandonment with state-backed verification and escrow.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 22),

                    // MODERN 2x3 QUICK ACTION & VALUE GRID
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.22,
                      children: [
                        // 1. Verify Document
                        _buildActionGridCard(
                          context: context,
                          title: 'Verify Document',
                          subtitle: 'C-of-O & Survey check',
                          badge: 'LEGAL VAULT',
                          icon: Icons.shield_outlined,
                          accentColor: AppColors.accentGoldLight,
                          badgeBg: AppColors.accentGold.withValues(alpha: 0.2),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const VerifyScreen()),
                            );
                          },
                        ),

                        // 2. Explore Properties (All Vetted, Off-Plan & Instalments)
                        _buildActionGridCard(
                          context: context,
                          title: 'Explore Properties',
                          subtitle: 'Vetted land & homes',
                          badge: '100% VETTED',
                          icon: Icons.travel_explore_rounded,
                          accentColor: const Color(0xFF38BDF8),
                          badgeBg: const Color(0xFF0284C7).withValues(alpha: 0.25),
                          onTap: () {
                            propProvider.clearFilters();
                            onNavigateTab?.call(1);
                          },
                        ),

                        // 3. Document Preparation Service (IN THE MIDDLE)
                        _buildActionGridCard(
                          context: context,
                          title: 'Document Prep',
                          subtitle: 'Deed & Contract Drafting',
                          badge: 'LEGAL DRAFT',
                          icon: Icons.history_edu_rounded,
                          accentColor: const Color(0xFF34D399),
                          badgeBg: const Color(0xFF059669).withValues(alpha: 0.25),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const LegalRequestScreen()),
                            );
                          },
                        ),

                        // 4. Pay Small-Small
                        _buildActionGridCard(
                          context: context,
                          title: 'Pay Small-Small',
                          subtitle: 'Dedicated NUBAN bank',
                          badge: 'DVA BANKING',
                          icon: Icons.account_balance_wallet_rounded,
                          accentColor: const Color(0xFFFBBF24),
                          badgeBg: const Color(0xFFD97706).withValues(alpha: 0.25),
                          onTap: () {
                            propProvider.setFilters(listingType: 'PAY_SMALL_SMALL');
                            onNavigateTab?.call(1);
                          },
                        ),

                        // 5. Free Land Risk Radar (FREE VALUE 1)
                        _buildActionGridCard(
                          context: context,
                          title: 'Free Land Radar',
                          subtitle: 'Scan 36 States Coords',
                          badge: 'FREE RADAR',
                          icon: Icons.radar_rounded,
                          accentColor: const Color(0xFFA78BFA),
                          badgeBg: const Color(0xFF7C3AED).withValues(alpha: 0.25),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const LandRadarScreen()),
                            );
                          },
                        ),

                        // 6. Material Price Index (FREE VALUE 2)
                        _buildActionGridCard(
                          context: context,
                          title: 'Material Index',
                          subtitle: 'Cement & Rebar 36 States',
                          badge: 'LIVE PRICES',
                          icon: Icons.trending_up_rounded,
                          accentColor: const Color(0xFFFB923C),
                          badgeBg: const Color(0xFFEA580C).withValues(alpha: 0.25),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const MaterialIndexScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ACTIVE PURCHASES SNAPSHOT (If user has active purchases)
              if (purchaseProvider.userPurchases.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'My Active Purchases & Instalments',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 135,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
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
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.cardBorder),
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
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.primary),
                                ),
                                Text(
                                  '${(p.progressPercentage * 100).toInt()}% Paid',
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: AppColors.emeraldText),
                                ),
                              ],
                            ),
                            Text(
                              p.property?.title ?? p.projectUnit?.name ?? 'Property Purchase',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            LinearProgressIndicator(
                              value: p.progressPercentage,
                              backgroundColor: AppColors.background,
                              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Paid: ${CurrencyFormatter.format(p.amountPaid)}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                                Text(
                                  'Bal: ${CurrencyFormatter.format(p.outstandingBalance)}',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
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
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionGridCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String badge,
    required IconData icon,
    required Color accentColor,
    required Color badgeBg,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      shadowColor: accentColor.withValues(alpha: 0.18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: accentColor.withValues(alpha: 0.12),
        highlightColor: accentColor.withValues(alpha: 0.06),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accentColor.withValues(alpha: 0.22), width: 1.2),
            gradient: LinearGradient(
              colors: [
                accentColor.withValues(alpha: 0.06),
                Colors.white,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                      border: Border.all(color: accentColor.withValues(alpha: 0.25), width: 1),
                    ),
                    child: Icon(icon, size: 20, color: accentColor),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: accentColor.withValues(alpha: 0.2), width: 0.8),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        color: accentColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
