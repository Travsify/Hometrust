import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/constants/colors.dart';
import '../core/network/api_client.dart';
import '../core/utils/currency_formatter.dart';
import '../providers/auth_provider.dart';
import 'developer_boq_validator_screen.dart';
import 'developer_projects_screen.dart';
import 'developer_subscribers_screen.dart';
import 'land_radar_screen.dart';
import 'material_index_screen.dart';
import 'real_estate_dictionary_screen.dart';
import 'legal_request_screen.dart';
import 'notifications_screen.dart';
import 'kyc_screen.dart';
import 'inbox_screen.dart';
import 'wallet_screen.dart';
import 'verify_screen.dart';
import 'build_for_me_screen.dart';
import 'support_tickets_screen.dart';
import 'site_reels_screen.dart';
import 'create_reel_screen.dart';

class DeveloperHomeScreen extends StatefulWidget {
  final Function(int)? onNavigateTab;
  const DeveloperHomeScreen({super.key, this.onNavigateTab});

  @override
  State<DeveloperHomeScreen> createState() => _DeveloperHomeScreenState();
}

class _DeveloperHomeScreenState extends State<DeveloperHomeScreen> {
  final PageController _spotlightController = PageController();
  int _currentSpotlightIndex = 0;
  bool _isLoading = true;
  bool _isBalanceVisible = false;
  Map<String, dynamic>? _stats;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchDeveloperStats();
  }

  @override
  void dispose() {
    _spotlightController.dispose();
    super.dispose();
  }

  Future<void> _fetchDeveloperStats() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await ApiClient.get('/developers/my-stats');
      if (mounted) {
        setState(() {
          _stats = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
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

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    final companyName = _stats?['developer']?['companyName'] ??
        user?.developerCompanyName ??
        (user != null ? '${user.firstName} ${user.lastName} Developments' : 'Developer Portal');
    final cacNumber = _stats?['developer']?['cacNumber'] ?? 'CAC Registered';
    final isVerified = _stats?['developer']?['isVerified'] ?? user?.isVerified ?? false;

    final availableBalance = (_stats?['financials']?['availableBalance'] as num?)?.toDouble() ?? 0.0;
    final lockedEscrow = (_stats?['financials']?['lockedEscrowBalance'] as num?)?.toDouble() ?? 0.0;
    final grossRevenue = (_stats?['financials']?['totalGrossRevenue'] as num?)?.toDouble() ?? 0.0;

    final virtualAccount = _stats?['virtualAccount'] as Map<String, dynamic>?;

    final totalProjects = _stats?['inventory']?['totalProjects'] ?? 0;
    final totalUnits = _stats?['inventory']?['totalUnits'] ?? 0;
    final availableUnits = _stats?['inventory']?['availableUnits'] ?? 0;
    final soldUnits = _stats?['inventory']?['soldUnits'] ?? 0;

    final activeMilestones = (_stats?['activeMilestones'] as List?) ?? [];
    final recentSubscribers = (_stats?['subscribers']?['recent'] as List?) ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            // App Icon with verified border
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.3), width: 1.2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: Image.asset(
                  'assets/icon/app_icon.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFF0F172A),
                    child: const Icon(Icons.apartment_rounded, color: Color(0xFF10B981), size: 18),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          companyName,
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (isVerified)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF059669).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified_rounded, size: 10, color: Color(0xFF059669)),
                              SizedBox(width: 2),
                              Text(
                                'KYB',
                                style: TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF059669),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  Text(
                    'CAC: $cacNumber • Developer Portal',
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // ── DEVELOPER INBOX BUTTON ──
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF334155), size: 22),
            tooltip: 'Buyer Inquiries & Messages',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const InboxScreen()));
            },
          ),
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
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchDeveloperStats,
        color: const Color(0xFF059669),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. DEVELOPER GREETING & VERIFICATION STATUS
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.firstName != null ? 'Welcome, ${user!.firstName} 🏗️' : 'Developer Dashboard 🏗️',
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Corporate Escrow & Verified Construction Management.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // ACCURATE VERIFIED BADGE
                    GestureDetector(
                      onTap: () {
                        if (!isVerified) {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const KycScreen()));
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isVerified
                              ? const Color(0xFF10B981).withValues(alpha: 0.12)
                              : const Color(0xFFEF4444).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isVerified ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isVerified ? Icons.verified_rounded : Icons.warning_amber_rounded,
                              size: 13,
                              color: isVerified ? const Color(0xFF059669) : const Color(0xFFDC2626),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isVerified ? 'VERIFIED KYB' : 'UNVERIFIED',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: isVerified ? const Color(0xFF059669) : const Color(0xFFDC2626),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 1.5 DEVELOPER SITE STORIES & REELS PUBLISHING BANNER
              _buildDeveloperStoriesActionBanner(context),
              const SizedBox(height: 14),

              // 2. SLIDEABLE SPOTLIGHT HERO BANNER CAROUSEL
              _buildSpotlightCarousel(context),
              const SizedBox(height: 16),

              // 3. BENTO BOX GRID (Tools, Projects & Wallet Ledger)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // LEFT COLUMN
                  Expanded(
                    child: Column(
                      children: [
                        // Bento 1: Projects & Inventory
                        _buildProjectsBentoCard(context, totalProjects, totalUnits, availableUnits, soldUnits),
                        const SizedBox(height: 14),
                        // Bento 2: 36 States Material Price Index
                        _buildMaterialIndexBentoCard(context),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  // RIGHT COLUMN
                  Expanded(
                    child: Column(
                      children: [
                        // Bento 3: Wallet
                        _buildWalletBentoCard(context),
                        const SizedBox(height: 14),
                        // Bento 4: Contractor BOQ Price Validator
                        _buildBoqBentoCard(context),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildLandRadarBentoCard(context),
              const SizedBox(height: 16),

              // 5. SUBSCRIBER CRM & IN-APP COMMUNICATIONS BANNER
              _buildSubscribersBanner(context),
              const SizedBox(height: 14),

              // 6. REAL ESTATE DICTIONARY & LEGAL DRAFTING
              _buildLegalDictionaryBanner(context),
              const SizedBox(height: 14),

              // 7. DEVELOPER SUPPORT & DISPUTE TICKETS
              _buildSupportTicketsBanner(context),
              const SizedBox(height: 24),

              // 8. ACTIVE CONSTRUCTION MILESTONES (100% Real Database Data)
              _buildActiveMilestonesSection(context, activeMilestones),
              const SizedBox(height: 24),

              // 8. RECENT SUBSCRIBERS & TRANCHE LEDGER (100% Real Database Data)
              _buildRecentSubscribersSection(context, recentSubscribers),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }


  // ── 1. SPOTLIGHT HERO CAROUSEL ──
  Widget _buildSpotlightCarousel(BuildContext context) {
    final List<Map<String, dynamic>> slides = [
      {
        'title': 'Milestone-Based Escrow Release',
        'subtitle': 'Receive buyer funds directly as construction passes verified engineering milestones.',
        'badge': 'AUTOMATED DISBURSEMENT',
        'gradient': [const Color(0xFF064E3B), const Color(0xFF047857)],
        'icon': Icons.shield_outlined,
        'action': 'View Milestones →',
        'onTap': () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const DeveloperProjectsScreen()));
        },
      },
      {
        'title': 'Legal Drafting & Document Prep',
        'subtitle': 'Draft joint venture agreements, deed of assignments & bespoke development contracts.',
        'badge': 'BAR-CERTIFIED SOLICITORS',
        'gradient': [const Color(0xFF0F172A), const Color(0xFF1E293B)],
        'icon': Icons.description_rounded,
        'action': 'Draft Contracts →',
        'onTap': () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const LegalRequestScreen()));
        },
      },
      {
        'title': 'Lands Registry Title Search & Vetting',
        'subtitle': 'Verify Governor\'s Consent, C of O, Gazette & gazetted acquisition records at lands bureau.',
        'badge': 'REGISTRY DUE DILIGENCE',
        'gradient': [const Color(0xFF075985), const Color(0xFF0284C7)],
        'icon': Icons.verified_user_rounded,
        'action': 'Start Title Search →',
        'onTap': () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const VerifyScreen()));
        },
      },
      {
        'title': 'Charter A Builder 🏗️ (Build-For-Me)',
        'subtitle': 'Contract vetted COREN engineers & master craftsmen with managed milestone escrow protection.',
        'badge': 'CHARTER A BUILDER',
        'gradient': [const Color(0xFF581C87), const Color(0xFF7E22CE)],
        'icon': Icons.architecture_rounded,
        'action': 'Charter A Builder →',
        'onTap': () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const BuildForMeScreen()));
        },
      },
    ];

    return Column(
      children: [
        SizedBox(
          height: 132,
          child: PageView.builder(
            controller: _spotlightController,
            onPageChanged: (idx) => setState(() => _currentSpotlightIndex = idx),
            itemCount: slides.length,
            itemBuilder: (context, index) {
              final slide = slides[index];
              return GestureDetector(
                onTap: slide['onTap'] as VoidCallback,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: slide['gradient'] as List<Color>,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    slide['badge'] as String,
                                    style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.w900, letterSpacing: 0.6),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.touch_app_rounded, color: Colors.white70, size: 12),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              slide['title'] as String,
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              slide['subtitle'] as String,
                              style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 10.5, height: 1.3),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(slide['icon'] as IconData, color: Colors.white, size: 24),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            slides.length,
            (idx) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 2.5),
              width: _currentSpotlightIndex == idx ? 16 : 6,
              height: 4,
              decoration: BoxDecoration(
                color: _currentSpotlightIndex == idx ? const Color(0xFF059669) : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── 2. BENTO BOX: WALLET ──
  Widget _buildWalletBentoCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen()));
      },
      child: Container(
        height: 165,
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF059669), size: 20),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('ESCROW', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: Color(0xFF065F46))),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Wallet', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                SizedBox(height: 2),
                Text('Fund balance, withdraw, settlements & ledger', style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'Manage Wallet',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF059669)),
                ),
                Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF059669)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── 3. BENTO BOX 1: PROJECTS & INVENTORY ──
  Widget _buildProjectsBentoCard(
    BuildContext context,
    int totalProjects,
    int totalUnits,
    int availableUnits,
    int soldUnits,
  ) {
    return GestureDetector(
      onTap: () {
        if (widget.onNavigateTab != null) {
          widget.onNavigateTab!(1); // Go to Projects Tab
        } else {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const DeveloperProjectsScreen()));
        }
      },
      child: Container(
        height: 165,
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.apartment_rounded, color: Color(0xFF059669), size: 20),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$totalProjects Active',
                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF059669)),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'My Projects',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 2),
                Text(
                  '$soldUnits sold / $totalUnits total units',
                  style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'Manage Units',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF059669)),
                ),
                Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF059669)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── 4. BENTO BOX 2: 36 STATES MATERIAL PRICE INDEX ──
  Widget _buildMaterialIndexBentoCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const MaterialIndexScreen()));
      },
      child: Container(
        height: 165,
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD97706).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.insights_rounded, color: Color(0xFFD97706), size: 20),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD97706).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '36 States',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFFD97706)),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Material Index',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                ),
                SizedBox(height: 2),
                Text(
                  'Cement, Rebar & Granite',
                  style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'Check Prices',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFFD97706)),
                ),
                Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFFD97706)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── 5. BENTO BOX 3: LAND RADAR & BOUNDARY SCAN ──
  Widget _buildLandRadarBentoCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const LandRadarScreen()));
      },
      child: Container(
        height: 165,
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.radar_rounded, color: Color(0xFF0284C7), size: 20),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'GPS Satellite',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF0284C7)),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Land Radar',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                ),
                SizedBox(height: 2),
                Text(
                  'Coordinate & Title Scan',
                  style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'Scan Land',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0284C7)),
                ),
                Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF0284C7)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── 6. BENTO BOX 4: CONTRACTOR BOQ PRICE VALIDATOR ──
  Widget _buildBoqBentoCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const DeveloperBoqValidatorScreen()));
      },
      child: Container(
        height: 165,
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF059669), size: 20),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'AI Audit',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF059669)),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Contractor BOQ',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                ),
                SizedBox(height: 2),
                Text(
                  'Audit Material Quotes',
                  style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'Audit BOQ',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF059669)),
                ),
                Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF059669)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── 9. SUBSCRIBER CRM & IN-APP COMMUNICATIONS BANNER ──
  Widget _buildSubscribersBanner(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (widget.onNavigateTab != null) {
          widget.onNavigateTab!(2); // Go to Subscribers tab
        } else {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const DeveloperSubscribersScreen()));
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF059669).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF059669), size: 22),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Buyer CRM & In-App Communications',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Chat & in-app calls with privacy phone masking and automated payment dunning.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.3),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF059669), size: 22),
          ],
        ),
      ),
    );
  }

  // ── 10. REAL ESTATE DICTIONARY & 3% LEGAL BANNER ──
  Widget _buildLegalDictionaryBanner(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const LegalRequestScreen()));
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.gavel_rounded, color: Color(0xFF475569), size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '3% Legal Drafting',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF94A3B8)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const RealEstateDictionaryScreen()));
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.menu_book_rounded, color: Color(0xFF059669), size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Real Estate Lexicon',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF94A3B8)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── 1.5 DEVELOPER SITE STORIES & REELS PUBLISHING BANNER ──
  Widget _buildDeveloperStoriesActionBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF059669).withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.5)),
                ),
                child: const Icon(Icons.videocam_rounded, color: Color(0xFF34D399), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Site Stories & Reels 🎥',
                      style: TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w900),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Post live build progress & reach subscribed buyers.',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CreateReelScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.add_photo_alternate_rounded, size: 16),
                  label: const Text('Post Site Story', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SiteReelsScreen()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF334155)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.play_circle_outline_rounded, size: 16, color: Color(0xFF34D399)),
                  label: const Text('Watch Feed', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── 11. DEVELOPER SUPPORT TICKETS BANNER ──
  Widget _buildSupportTicketsBanner(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportTicketsScreen()));
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.headset_mic_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Developer Support & Priority Tickets',
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Request support for KYB, milestone audit reviews, escrow releases & technical queries.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.35),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  // ── 12. ACTIVE CONSTRUCTION MILESTONES (100% Real Database Data) ──
  Widget _buildActiveMilestonesSection(BuildContext context, List<dynamic> activeMilestones) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Active Construction Milestones',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF059669).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${activeMilestones.length} ONGOING',
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF059669)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (activeMilestones.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.foundation_rounded, size: 36, color: Color(0xFF94A3B8)),
                    const SizedBox(height: 8),
                    const Text('No Active Milestones Yet', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF334155))),
                    const SizedBox(height: 4),
                    const Text('Publish a project and configure construction milestones to unlock escrow disbursements.', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        if (widget.onNavigateTab != null) {
                          widget.onNavigateTab!(1);
                        } else {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const DeveloperProjectsScreen()));
                        }
                      },
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('Add Milestone Project', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...activeMilestones.map((m) {
              final pct = ((m['percentage'] as num?)?.toDouble() ?? 0.0) / 100.0;
              final targetDate = m['completionDate'] != null ? m['completionDate'].toString().split('T')[0] : 'In Progress';
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${m['projectName'] ?? "Project"} • ${m['title'] ?? "Milestone"}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${((pct * 100).toInt())}% Done',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF059669)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: pct.clamp(0.0, 1.0),
                        minHeight: 7,
                        backgroundColor: const Color(0xFFE2E8F0),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF059669)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Target: $targetDate',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                        Text(
                          'Escrow Value: ${CurrencyFormatter.format((m['amount'] as num?)?.toDouble() ?? 0)}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // ── 12. RECENT SUBSCRIBERS & PAYMENTS SECTION (100% Real Database Data) ──
  Widget _buildRecentSubscribersSection(BuildContext context, List<dynamic> recent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Subscribers & Payments',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
            ),
            TextButton(
              onPressed: () {
                if (widget.onNavigateTab != null) {
                  widget.onNavigateTab!(2); // Go to Subscribers Tab
                } else {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const DeveloperSubscribersScreen()));
                }
              },
              child: const Text('View All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0284C7))),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (recent.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Center(
              child: Column(
                children: [
                  Icon(Icons.receipt_long_outlined, size: 36, color: Color(0xFF94A3B8)),
                  SizedBox(height: 8),
                  Text('No Subscribers Yet', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF334155))),
                  SizedBox(height: 4),
                  Text('When buyers subscribe to your off-plan units, their instalments will appear here in real time.', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                ],
              ),
            ),
          )
        else
          ...recent.map((sub) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_rounded, color: Color(0xFF059669), size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sub['buyerName'] ?? 'Subscriber',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${sub['itemTitle'] ?? "Unit"} • ${sub['purchaseCode'] ?? ""}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        CurrencyFormatter.format((sub['amountPaid'] as num?)?.toDouble() ?? 0),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF059669)),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          sub['status'] ?? 'ACTIVE',
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF0284C7)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  // ── 13. BANK SETTLEMENT PAYOUT MODAL ──
  void _showPayoutModal(BuildContext context) {
    final amountCtrl = TextEditingController();
    final acctCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    String selectedBank = 'Guaranty Trust Bank (058)';

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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Request Bank Settlement Payout', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Withdraw cleared milestone funds directly to your verified corporate commercial bank account.',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Payout Amount (NGN)',
                  prefixText: '₦ ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedBank,
                decoration: InputDecoration(
                  labelText: 'Destination Commercial Bank',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: [
                  'Guaranty Trust Bank (058)',
                  'Zenith Bank (057)',
                  'Access Bank (044)',
                  'First Bank of Nigeria (011)',
                  'United Bank for Africa (033)',
                  'Providus Bank (101)',
                  'Wema Bank (035)',
                  'Stanbic IBTC Bank (221)',
                ].map((b) => DropdownMenuItem(value: b, child: Text(b, style: const TextStyle(fontSize: 13)))).toList(),
                onChanged: (val) => selectedBank = val!,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: acctCtrl,
                keyboardType: TextInputType.number,
                maxLength: 10,
                decoration: InputDecoration(
                  labelText: '10-Digit NUBAN Account Number',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Corporate Account Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (amountCtrl.text.isEmpty || acctCtrl.text.isEmpty || nameCtrl.text.isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Please fill all payout fields')),
                      );
                      return;
                    }
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Payout request submitted successfully! Processing via Secure Bank Transfer.'),
                        backgroundColor: Color(0xFF059669),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Confirm & Process Payout', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
