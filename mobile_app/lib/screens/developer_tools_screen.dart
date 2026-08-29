import 'package:flutter/material.dart';
import 'land_radar_screen.dart';
import 'material_index_screen.dart';
import 'legal_request_screen.dart';
import 'real_estate_dictionary_screen.dart';
import 'verify_screen.dart';
import 'developer_boq_validator_screen.dart';
import 'developer_jv_board_screen.dart';
import 'developer_site_gallery_screen.dart';

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
    String selectedDate = 'Tomorrow (10:00 AM)';

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
                value: selectedStage,
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Developer Tools & Modules', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 18)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. PRIMARY FEATURED ACTION: REQUEST MILESTONE INSPECTION
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

          const Text('Ecosystem Construction & Legal Tools', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
          const SizedBox(height: 12),

          // 2. CONTRACTOR BOQ MATERIAL PRICE VALIDATOR
          _buildToolTile(
            icon: Icons.receipt_long_rounded,
            iconColor: const Color(0xFF059669),
            title: 'Contractor BOQ Price Validator',
            subtitle: 'Cross-check contractor Bill of Quantities quotes against certified state material indices to detect padding and overbilling.',
            badge: 'AI COST AUDIT',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const DeveloperBoqValidatorScreen()));
            },
          ),
          const SizedBox(height: 12),

          // 3. JOINT VENTURE (JV) LAND MATCHING BOARD
          _buildToolTile(
            icon: Icons.handshake_rounded,
            iconColor: const Color(0xFF0284C7),
            title: 'JV Land Matching Board',
            subtitle: 'Browse pre-vetted land parcels across prime corridors available for Joint Venture development with certified titles.',
            badge: 'JV PARTNERS',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const DeveloperJvBoardScreen()));
            },
          ),
          const SizedBox(height: 12),

          // 4. SITE DRONE & GEOTAGGED PROGRESS GALLERY
          _buildToolTile(
            icon: Icons.photo_camera_back_rounded,
            iconColor: const Color(0xFF7C3AED),
            title: 'Site Drone & Geotagged Gallery',
            subtitle: 'Timestamped EXIF GPS progress photos showing structural rising stages to build transparent buyer confidence.',
            badge: 'VISUAL AUDIT',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const DeveloperSiteGalleryScreen()));
            },
          ),
          const SizedBox(height: 12),

          // 5. 36 STATES MATERIAL PRICE INDEX
          _buildToolTile(
            icon: Icons.analytics_rounded,
            iconColor: const Color(0xFF0D9488),
            title: '36 States Material Price Index',
            subtitle: 'Real-time verified wholesale & retail pricing for cement, rebar, granite, sand, and roofing across Nigeria.',
            badge: 'LIVE BENCHMARKS',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const MaterialIndexScreen()));
            },
          ),
          const SizedBox(height: 12),

          // 6. LAND RADAR & BOUNDARY COORDINATES
          _buildToolTile(
            icon: Icons.radar_rounded,
            iconColor: const Color(0xFF9333EA),
            title: 'Land Radar & Coordinate Plotter',
            subtitle: 'Instantly check GPS / cadastral survey coordinates against government acquisition and master plans.',
            badge: 'SURVEY CHECK',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const LandRadarScreen()));
            },
          ),
          const SizedBox(height: 12),

          // 7. 3% LEGAL DOCUMENT PREPARATION
          _buildToolTile(
            icon: Icons.gavel_rounded,
            iconColor: const Color(0xFFD97706),
            title: 'Legal Document Drafting (3%)',
            subtitle: 'Automated legal drafting for Joint Venture agreements, Deeds of Assignment, and bespoke off-plan contracts.',
            badge: 'LEGAL DRAFTING',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const LegalRequestScreen()));
            },
          ),
          const SizedBox(height: 12),

          // 8. TITLE & DOCUMENT VERIFICATION
          _buildToolTile(
            icon: Icons.security_rounded,
            iconColor: const Color(0xFF059669),
            title: 'Title & Land Registry Search',
            subtitle: 'AI-assisted document scanning and physical registry search at state lands bureaus (Alausa, AGIS).',
            badge: 'TITLE SEARCH',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const VerifyScreen()));
            },
          ),
          const SizedBox(height: 12),

          // 9. REAL ESTATE LEXICON (ARBITER OF TRUTH)
          _buildToolTile(
            icon: Icons.menu_book_rounded,
            iconColor: const Color(0xFF0F172A),
            title: 'Hometrust Lexicon ("Arbiter of Truth")',
            subtitle: 'Comprehensive real estate terms, legal definitions, verification checklists, and warning signs.',
            badge: 'DICTIONARY',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const RealEstateDictionaryScreen()));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildToolTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String badge,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: iconColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: iconColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
            ],
          ),
        ),
      ),
    );
  }
}
