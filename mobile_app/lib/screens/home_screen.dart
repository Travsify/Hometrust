import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/colors.dart';
import '../core/utils/currency_formatter.dart';
import '../core/network/api_client.dart';
import '../providers/property_provider.dart';
import '../providers/purchase_provider.dart';
import 'property_detail_screen.dart';
import 'project_detail_screen.dart';
import 'verify_screen.dart';
import 'legal_request_screen.dart';
import 'land_radar_screen.dart';
import 'material_index_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'HomeVerify',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.emeraldBg,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.emeraldText.withOpacity(0.3)),
              ),
              child: const Text(
                'VERIFIED',
                style: TextStyle(
                  color: AppColors.emeraldText,
                  fontWeight: FontWeight.w800,
                  fontSize: 9,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () async {
              try {
                final notifications = await ApiClient.get('/notifications?limit=10&unread=true');
                if (!context.mounted) return;
                final count = (notifications is List) ? notifications.length : 0;
                if (count == 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No unread notifications')),
                  );
                } else {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                    builder: (_) => Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Notifications ($count unread)', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 12),
                          ...(notifications as List).take(5).map((n) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.notifications_active_rounded, color: AppColors.primary),
                            title: Text(n['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                            subtitle: Text(n['message'] ?? '', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          )).toList(),
                        ],
                      ),
                    ),
                  );
                }
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Could not load notifications')),
                  );
                }
              }
            },
            icon: const Icon(Icons.notifications_none_rounded, color: AppColors.textPrimary),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await propProvider.fetchAll();
          await purchaseProvider.fetchMyPurchases();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HERO SECTION
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
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
                        color: AppColors.accentGold.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.accentGold.withOpacity(0.4)),
                      ),
                      child: const Text(
                        '🇳🇬 NIGERIAN REAL ESTATE GATEWAY',
                        style: TextStyle(
                          color: AppColors.accentGoldLight,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Buy property with confidence.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Verify property documents, discover verified projects, pay in instalments and keep all your records in one place.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // MODERN 2x3 QUICK ACTION SERVICE & VALUE GRID
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.25,
                      children: [
                        // Grid Item 1: Verify Document
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

                        // Grid Item 2: Explore Properties
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
                          },
                        ),

                        // Grid Item 3: Document Preparation Service (MIDDLE)
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

                        // Grid Item 4: Off-Plan Projects
                        _buildActionGridCard(
                          context: context,
                          title: 'Off-Plan Projects',
                          subtitle: 'Milestone-locked build',
                          badge: 'ESCROW LOCK',
                          icon: Icons.apartment_rounded,
                          accentColor: const Color(0xFFFBBF24),
                          badgeBg: const Color(0xFFD97706).withValues(alpha: 0.25),
                          onTap: () {
                            propProvider.setFilters(listingType: 'OFF_PLAN');
                          },
                        ),

                        // Grid Item 5: Free Land Risk Radar (FREE VALUE 1)
                        _buildActionGridCard(
                          context: context,
                          title: 'Free Land Radar',
                          subtitle: 'Scan GPS & Beacon coords',
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

                        // Grid Item 6: Material Price Index (FREE VALUE 2)
                        _buildActionGridCard(
                          context: context,
                          title: 'Material Index',
                          subtitle: 'Cement & Rebar Rates',
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

              // ACTIVE PURCHASES SNAPSHOT (If Any)
              if (purchaseProvider.userPurchases.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'My Active Purchases',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 140,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: purchaseProvider.userPurchases.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final p = purchaseProvider.userPurchases[index];
                      return Container(
                        width: 280,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
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

              // VERIFIED DEVELOPERS
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Verified Developers',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                    Text(
                      'CAC Audited',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.emeraldText),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: propProvider.developers.isEmpty
                    ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.business_outlined, color: AppColors.primary, size: 20),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'No Developers Listed At This Time',
                                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.textPrimary),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'CAC & EFCC vetted developers will automatically appear here once onboarded.',
                                    style: TextStyle(fontSize: 10, color: AppColors.textSecondary, height: 1.3),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    : SizedBox(
                        height: 105,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          scrollDirection: Axis.horizontal,
                          itemCount: propProvider.developers.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final dev = propProvider.developers[index];
                            return Container(
                              width: 180,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.cardBorder),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.verified, color: AppColors.emeraldText, size: 14),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          dev.companyName,
                                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: AppColors.textPrimary),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    'RC: ${dev.cacNumber}',
                                    style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontFamily: 'monospace'),
                                  ),
                                  Text(
                                    '${dev.completedProjectsCount} Delivered Projects',
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primary),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
              ),

              // OFF-PLAN PROJECTS SHOWCASE
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Off-Plan Developments',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                    TextButton(
                      onPressed: () {
                        propProvider.setFilters(listingType: 'OFF_PLAN');
                      },
                      child: const Text('See All →', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: propProvider.projects.isEmpty
                    ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFBBF24).withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.apartment_rounded, color: Color(0xFFD97706), size: 28),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'No Off-Plan Developments Available Yet',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Milestone escrow-locked development projects will be visible here once published.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.3),
                            ),
                          ],
                        ),
                      )
                    : SizedBox(
                        height: 230,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: propProvider.projects.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 14),
                          itemBuilder: (context, index) {
                            final proj = propProvider.projects[index];
                            return InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProjectDetailScreen(project: proj),
                                  ),
                                );
                              },
                              child: Container(
                                width: 250,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.cardBorder),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Stack(
                                      children: [
                                        Image.network(
                                          proj.firstImage,
                                          height: 120,
                                          width: 250,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Container(height: 120, color: Colors.grey.shade300),
                                        ),
                                        Positioned(
                                          top: 8,
                                          left: 8,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withValues(alpha: 0.7),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'Completion: ${proj.expectedCompletion}',
                                              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            proj.name,
                                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.textPrimary),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${proj.area}, ${proj.city}',
                                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            '${proj.units.length} Unit Types Available',
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),

              // PAY-SMALL-SMALL & FEATURED PROPERTIES
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Pay Small-Small Properties',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                    TextButton(
                      onPressed: () {
                        propProvider.setFilters(listingType: 'PAY_SMALL_SMALL');
                      },
                      child: const Text('View All →', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                    ),
                  ],
                ),
              ),
              if (propProvider.paySmallSmallProperties.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF34D399).withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF059669), size: 28),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'No Pay Small-Small Properties Available Yet',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Properties with flexible monthly instalment schedules will appear here once listed.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: propProvider.paySmallSmallProperties.take(4).length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final prop = propProvider.paySmallSmallProperties[index];
                    final plan = prop.paymentPlans.isNotEmpty ? prop.paymentPlans[0] : null;

                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PropertyDetailScreen(property: prop),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Stack(
                              children: [
                                Image.network(
                                  prop.firstImage,
                                  height: 160,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(height: 160, color: Colors.grey.shade300),
                                ),
                                Positioned(
                                  top: 10,
                                  left: 10,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.emeraldBg,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: AppColors.emeraldBorder),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.verified, size: 12, color: AppColors.emeraldText),
                                        const SizedBox(width: 4),
                                        Text(
                                          prop.verificationStatus == 'VERIFIED' ? 'C-of-O Verified' : prop.landTitle.replaceAll('_', ' '),
                                          style: const TextStyle(
                                            color: AppColors.emeraldText,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    prop.title,
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.textPrimary),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${prop.area}, ${prop.city}, ${prop.state}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                  const SizedBox(height: 12),
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
                                            const Text('TOTAL PRICE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                                            Text(CurrencyFormatter.format(prop.price), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                                          ],
                                        ),
                                        if (plan != null)
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              const Text('PAY MONTHLY FROM', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.emeraldText)),
                                              Text('${CurrencyFormatter.format(plan.monthlyPayment)}/mo', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.emeraldText)),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
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
