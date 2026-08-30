import 'package:flutter/material.dart';
import '../widgets/persistent_bottom_nav.dart';
import 'land_radar_screen.dart';
import 'material_index_screen.dart';
import 'legal_request_screen.dart';
import 'real_estate_dictionary_screen.dart';
import 'verify_screen.dart';
import 'developer_boq_validator_screen.dart';

class DeveloperToolsScreen extends StatefulWidget {
  const DeveloperToolsScreen({super.key});

  @override
  State<DeveloperToolsScreen> createState() => _DeveloperToolsScreenState();
}

class _DeveloperToolsScreenState extends State<DeveloperToolsScreen> {
  void _showMilestoneInspectionModal() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String selectedStage = 'Stage 2: Structural Framing & Lintels';

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
                  const Text('Request Milestone Inspection', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                  IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Schedule a physical site inspection by certified Hometrust COREN structural engineers to sign off your milestone and unlock escrow funds.',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedStage,
                decoration: InputDecoration(
                  labelText: 'Construction Milestone Stage',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: [
                  'Stage 1: Substructure & Foundation (20%)',
                  'Stage 2: Structural Framing & Lintels (25%)',
                  'Stage 3: Roofing & Parapet Walls (20%)',
                  'Stage 4: Plumbing, Electrical & MEP (15%)',
                  'Stage 5: Plastering, Tiling & Finishing (15%)',
                  'Stage 6: Final Snagging & Handover (5%)',
                ].map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 12)))).toList(),
                onChanged: (val) => selectedStage = val!,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Site Engineer / Resident Contact Person',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Site Contact Phone Number',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
                decoration: InputDecoration(
                  labelText: 'Site Access Instructions / Gate Pass Notes',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (nameCtrl.text.isEmpty || phoneCtrl.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter site engineer contact details')),
                      );
                      return;
                    }
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Milestone inspection scheduled! Hometrust engineering team assigned.'),
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
                  child: const Text('Schedule Certified Inspection', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const PersistentBottomNav(activeIndex: 3),
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Developer Tools & Modules', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 18)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── 1. PRIMARY FEATURED ACTION: MILESTONE INSPECTION ──
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF059669), Color(0xFF047857)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF059669).withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.verified_rounded, color: Colors.white, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Milestone Inspection & Sign-Off',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Book a site visit with Hometrust COREN structural engineers to certify your construction progress and unlock milestone escrow funds.',
                  style: TextStyle(color: Color(0xFFD1FAE5), fontSize: 12, height: 1.4),
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: _showMilestoneInspectionModal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF059669),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Schedule Milestone Audit', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── 2. BENTO GRID SECTION HEADER ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Construction & Legal Bento Grid',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF059669).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('6 MODULES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF059669))),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── 3. 2x3 BENTO GRID OF ACTIVE TOOLS ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // LEFT COLUMN
              Expanded(
                child: Column(
                  children: [
                    // Bento 1: Contractor BOQ Price Validator
                    _buildBentoGridCard(
                      icon: Icons.receipt_long_rounded,
                      accentColor: const Color(0xFF059669),
                      bgGradient: [const Color(0xFFECFDF5), Colors.white],
                      title: 'Contractor BOQ Validator',
                      subtitle: 'Audit material quotes against live state benchmarks to eliminate contractor padding.',
                      badge: 'AI COST AUDIT',
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const DeveloperBoqValidatorScreen()));
                      },
                    ),
                    const SizedBox(height: 14),

                    // Bento 2: 36 States Material Price Index
                    _buildBentoGridCard(
                      icon: Icons.insights_rounded,
                      accentColor: const Color(0xFF0284C7),
                      bgGradient: [const Color(0xFFF0F9FF), Colors.white],
                      title: '36 States Material Index',
                      subtitle: 'Wholesale & retail prices for cement, rebar, sand, and granite across Nigeria.',
                      badge: 'LIVE BENCHMARKS',
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const MaterialIndexScreen()));
                      },
                    ),
                    const SizedBox(height: 14),

                    // Bento 3: Title & Land Registry Search
                    _buildBentoGridCard(
                      icon: Icons.verified_user_rounded,
                      accentColor: const Color(0xFF10B981),
                      bgGradient: [const Color(0xFFF0FDF4), Colors.white],
                      title: 'Title & Land Registry',
                      subtitle: 'Direct search and verification at Alausa, AGIS, and state land registries.',
                      badge: 'REGISTRY SEARCH',
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const VerifyScreen()));
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // RIGHT COLUMN
              Expanded(
                child: Column(
                  children: [
                    // Bento 4: Land Radar & Boundary Scan
                    _buildBentoGridCard(
                      icon: Icons.radar_rounded,
                      accentColor: const Color(0xFF7C3AED),
                      bgGradient: [const Color(0xFFF5F3FF), Colors.white],
                      title: 'Land Radar & GPS Plotter',
                      subtitle: 'Scan cadastral beacons to check encroachment, committed gazette, and acquisition status.',
                      badge: 'GPS BEACON SCAN',
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const LandRadarScreen()));
                      },
                    ),
                    const SizedBox(height: 14),

                    // Bento 5: 3% Legal Document Drafting
                    _buildBentoGridCard(
                      icon: Icons.gavel_rounded,
                      accentColor: const Color(0xFFD97706),
                      bgGradient: [const Color(0xFFFFFBEB), Colors.white],
                      title: 'Legal Drafting (3%)',
                      subtitle: 'Automated NBA-compliant Contracts of Sale, Deeds of Assignment, and Covenants.',
                      badge: 'NBA COMPLIANT',
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const LegalRequestScreen()));
                      },
                    ),
                    const SizedBox(height: 14),

                    // Bento 6: Real Estate Lexicon ("Arbiter of Truth")
                    _buildBentoGridCard(
                      icon: Icons.menu_book_rounded,
                      accentColor: const Color(0xFF0F172A),
                      bgGradient: [const Color(0xFFF8FAFC), Colors.white],
                      title: 'Hometrust Lexicon',
                      subtitle: 'Nigerian real estate terms, legal checklists, red flags, and title classifications.',
                      badge: 'ARBITER OF TRUTH',
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const RealEstateDictionaryScreen()));
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildBentoGridCard({
    required IconData icon,
    required Color accentColor,
    required List<Color> bgGradient,
    required String title,
    required String subtitle,
    required String badge,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: bgGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accentColor.withValues(alpha: 0.15), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: accentColor, size: 20),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: accentColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), height: 1.2),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B), height: 1.35),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('Open Tool', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: accentColor)),
                    const SizedBox(width: 2),
                    Icon(Icons.arrow_forward_rounded, size: 12, color: accentColor),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

