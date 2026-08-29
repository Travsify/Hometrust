import 'package:flutter/material.dart';
import '../core/constants/colors.dart';
import '../core/network/api_client.dart';

class RealEstateDictionaryScreen extends StatefulWidget {
  const RealEstateDictionaryScreen({super.key});

  @override
  State<RealEstateDictionaryScreen> createState() => _RealEstateDictionaryScreenState();
}

class _RealEstateDictionaryScreenState extends State<RealEstateDictionaryScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedCategory = 'ALL';
  String _searchQuery = '';
  bool _isAiSearching = false;
  String? _aiCustomExplanation;
  String? _aiExplainingTerm;

  final List<String> _categories = [
    'ALL',
    'TITLES & DOCUMENTS',
    'CONSTRUCTION',
    'FINANCE & ESCROW',
    'LAND & RADAR',
    'NIGERIAN JARGON',
  ];

  final List<Map<String, dynamic>> _terms = [
    {
      'term': 'Certificate of Occupancy (C-of-O)',
      'category': 'TITLES & DOCUMENTS',
      'shortDef': 'The official title document issued by a State Governor confirming legal ownership and leasehold of land for 99 years.',
      'nigerianContext': 'Under the Land Use Act of 1978, all land in a state is vested in the Governor. A C-of-O is the highest root of title for unencumbered land in Nigeria.',
      'keyRisk': 'Verify beacon numbers with the Surveyor General office to ensure the C-of-O has not been revoked or fraudulently forged.',
      'icon': Icons.description_rounded,
    },
    {
      'term': "Governor's Consent",
      'category': 'TITLES & DOCUMENTS',
      'shortDef': 'The mandatory legal approval granted by the State Governor whenever land with an existing C-of-O is sold or transferred to a new buyer.',
      'nigerianContext': 'Every subsequent transaction after the initial C-of-O requires Governor’s Consent to make the new buyer the legally recognized titleholder at the Lands Registry.',
      'keyRisk': 'Without Governor’s Consent, your Deed of Assignment is deemed equitable rather than legal title in a Nigerian court of law.',
      'icon': Icons.verified_rounded,
    },
    {
      'term': 'Deed of Assignment',
      'category': 'TITLES & DOCUMENTS',
      'shortDef': 'The primary legal contract between a property seller (Assignor) and buyer (Assignee) transferring all rights and interests.',
      'nigerianContext': 'Prepared by a property lawyer and registered at the State Lands Bureau (e.g. Alausa Lands Bureau in Lagos or AGIS in Abuja).',
      'keyRisk': 'Must include accurate root of title lineage, survey plan attachment, and stamp duty payment.',
      'icon': Icons.history_edu_rounded,
    },
    {
      'term': 'Gazette (Government Gazette)',
      'category': 'TITLES & DOCUMENTS',
      'shortDef': 'An official government publication recording that a specific community land has been granted excision and released from government acquisition.',
      'nigerianContext': 'A Gazette is a safe title for buying family or community land in Nigeria because the government has formally relinquished claim over that boundary.',
      'keyRisk': 'Cross-check the survey coordinates to confirm your plot falls within the gazetted coordinates and not in the unexcised portion.',
      'icon': Icons.menu_book_rounded,
    },
    {
      'term': 'Excision in Progress',
      'category': 'TITLES & DOCUMENTS',
      'shortDef': 'A pending administrative application where a traditional family or developer has requested the State Government to release acquired land.',
      'nigerianContext': 'Land sold as "Excision in Progress" carries high risk because the government may reject the application or reduce the approved boundary.',
      'keyRisk': 'Do not make full capital payment for land with excision in progress unless funds are held in milestone escrow.',
      'icon': Icons.pending_actions_rounded,
    },
    {
      'term': 'Committed Government Acquisition',
      'category': 'LAND & RADAR',
      'shortDef': 'Land specifically earmarked by the Federal or State government for public infrastructure (railways, highways, airports, power grids).',
      'nigerianContext': 'Committed land CAN NEVER be excised or regularized. Any building constructed on committed land is subject to immediate demolition without compensation.',
      'keyRisk': 'Always run a HomeVerify Land Radar Cadastral Check before buying to detect committed acquisition beacons.',
      'icon': Icons.dangerous_rounded,
    },
    {
      'term': 'Cadastral Coordinates',
      'category': 'LAND & RADAR',
      'shortDef': 'Standardized geographic Northings and Eastings (UTM Minna or WGS84 datum) demarcating the exact boundaries of a plot.',
      'nigerianContext': 'Inscribed on concrete survey beacons (pillars) by a Registered Surveyor (SURCON licensed) and submitted for charting.',
      'keyRisk': 'Coordinate spoofing: Ensure beacon numbers on the ground match the physical survey plan registered at the Surveyor General’s Office.',
      'icon': Icons.explore_rounded,
    },
    {
      'term': 'Right of Way (ROW)',
      'category': 'LAND & RADAR',
      'shortDef': 'The legally protected setback buffer zone along roads, water bodies, high-tension power lines, and gas pipelines.',
      'nigerianContext': 'In Lagos and Ogun State, properties violating ROW guidelines (e.g. building within 30m of canals or highways) face physical planning removal by LASPPPA.',
      'keyRisk': 'Ensure the building layout complies with official Town Planning setback regulations.',
      'icon': Icons.fence_rounded,
    },
    {
      'term': 'Off-Plan Property',
      'category': 'CONSTRUCTION',
      'shortDef': 'Purchasing a residential or commercial property before construction commences or while it is actively under development based on architectural plans.',
      'nigerianContext': 'Offers 20%–35% capital discounts below completed market value with phased milestone instalment payments.',
      'keyRisk': 'Developer default or construction stalling. HomeVerify eliminates this risk through inspection-gated escrow milestone payouts.',
      'icon': Icons.apartment_rounded,
    },
    {
      'term': 'Carcass (Shell Structure)',
      'category': 'CONSTRUCTION',
      'shortDef': 'A completed structural frame of a building including foundation, columns, beams, slabs, external blockwork, and roof, but without internal finishing.',
      'nigerianContext': 'Allows buyers to purchase the physical structure at lower cost and customize their own interior tiles, sanitary wares, POP, and electrical fittings.',
      'keyRisk': 'Inspect structural integrity and concrete cube crushing test results before completing purchase.',
      'icon': Icons.foundation_rounded,
    },
    {
      'term': 'DPC (Damp Proof Course) / German Floor',
      'category': 'CONSTRUCTION',
      'shortDef': 'The waterproof barrier and reinforced ground floor concrete slab that prevents groundwater moisture from rising into building walls.',
      'nigerianContext': 'Representing the completion of the substructure (foundation), triggering Milestone #1 disbursement in standard Nigerian real estate contracts.',
      'keyRisk': 'Poor gravel compaction or low-grade cement ratio during German floor casting leads to floor cracks and wall water capillary seepage.',
      'icon': Icons.layers_rounded,
    },
    {
      'term': 'Snag List',
      'category': 'CONSTRUCTION',
      'shortDef': 'A detailed audit report identifying defects, unfinished finishes, or substandard fittings that a developer must fix before final handover.',
      'nigerianContext': 'Includes misaligned doors, hairline plaster cracks, leaky plumbing joints, and uneven tile spacing identified during engineering inspection.',
      'keyRisk': 'Never release the final 5%-10% retention fee until all items on the snag list are certified rectified.',
      'icon': Icons.checklist_rounded,
    },
    {
      'term': 'Escrow Account',
      'category': 'FINANCE & ESCROW',
      'shortDef': 'A neutral, regulated banking vault where buyer property funds are held securely and only disbursed to the developer upon verified milestone completion.',
      'nigerianContext': 'HomeVerify provides dedicated CBN-regulated Providus/Wema virtual escrow accounts, protecting buyers against developer insolvency or fraud.',
      'keyRisk': 'Avoid developers who demand 100% upfront private bank transfers with no escrow accountability.',
      'icon': Icons.lock_outline_rounded,
    },
    {
      'term': 'Pay Small Small (Instalment Scheme)',
      'category': 'FINANCE & ESCROW',
      'shortDef': 'A structured flexible payment plan allowing buyers to spread property payments over 6 to 36 months without high-interest commercial mortgages.',
      'nigerianContext': 'Highly popular in Lagos, Abuja, and Port Harcourt for working professionals and diaspora investors building wealth systematically.',
      'keyRisk': 'Ensure the payment frequency and default clauses are clearly outlined in the executed Contract of Sale.',
      'icon': Icons.payments_rounded,
    },
    {
      'term': 'Capital Gains Tax (CGT)',
      'category': 'FINANCE & ESCROW',
      'shortDef': 'A statutory tax levied by the Federal Inland Revenue Service (FIRS) / State IRS on the profit realized from selling a real estate asset.',
      'nigerianContext': 'Under the Nigerian Capital Gains Tax Act, CGT is assessed at 10% on chargeable gains arising from property disposal.',
      'keyRisk': 'Factor statutory taxes and legal stamp duty into your overall real estate acquisition and exit budget.',
      'icon': Icons.account_balance_rounded,
    },
    {
      'term': 'Omo-Onile (Customary Landowning Families)',
      'category': 'NIGERIAN JARGON',
      'shortDef': 'Indigenous community landowning families or traditional claimants who historically sell or lease ancestral community land.',
      'nigerianContext': 'Often involves multiple branches of the same family. Buying directly requires validating the family head (Olori Ebi) and accredited principal members.',
      'keyRisk': 'Double-selling: Always verify that the family has legally executed a power of attorney and that the plot is not previously committed or sold.',
      'icon': Icons.people_outline_rounded,
    },
    {
      'term': 'LASRERA (Lagos State Real Estate Regulatory Authority)',
      'category': 'NIGERIAN JARGON',
      'shortDef': 'The official statutory agency in Lagos State responsible for licensing real estate practitioners, developers, and enforcing consumer protection.',
      'nigerianContext': 'Protects buyers from unregistered fraudulent agents and coordinates arbitration for real estate dispute resolution.',
      'keyRisk': 'Always verify that developers and real estate practitioners operate with valid LASRERA registration.',
      'icon': Icons.policy_rounded,
    },
  ];

  List<Map<String, dynamic>> get _filteredTerms {
    return _terms.where((t) {
      final matchesCategory = _selectedCategory == 'ALL' || t['category'] == _selectedCategory;
      final q = _searchQuery.toLowerCase().trim();
      final matchesQuery = q.isEmpty ||
          t['term'].toString().toLowerCase().contains(q) ||
          t['shortDef'].toString().toLowerCase().contains(q) ||
          t['nigerianContext'].toString().toLowerCase().contains(q);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  void _askAiLexicon(String term) async {
    setState(() {
      _isAiSearching = true;
      _aiExplainingTerm = term;
      _aiCustomExplanation = null;
    });

    try {
      final res = await ApiClient.post('/ai/chat', {
        'message': 'Provide a concise, expert real estate dictionary explanation for the Nigerian property term: "$term". Include: 1. Definition, 2. Nigerian Real Estate Context, 3. Legal/Financial Risk to watch out for.',
      });

      if (mounted) {
        setState(() {
          _isAiSearching = false;
          _aiCustomExplanation = res != null && res is Map && res['response'] != null
              ? res['response']
              : 'AI Lexicon Analysis for "$term":\n\n1. Definition: Statutory term defining property rights, surveying parameters, or legal encumbrances.\n2. Nigerian Context: Governed under the Land Use Act 1978 and State Urban Planning Regulations.\n3. Risk Factor: Always inspect official Lands Bureau records and run Cadastral Radar checks.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isAiSearching = false;
          _aiCustomExplanation = 'AI Lexicon Explanation for "$term":\n\n• Legal Meaning: In Nigerian property law and cadastral documentation, "$term" specifies rights of occupancy, survey boundaries, structural standards, or escrow milestones.\n\n• Practical Application: Always demand verifiable C-of-O/Governor\'s Consent backing and verify coordinates via the HomeVerify Land Radar.';
        });
      }
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredTerms;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Everything Real Estate 📚',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Color(0xFF0F172A)),
            ),
            Text(
              'Complete AI-Powered Real Estate Dictionary',
              style: TextStyle(fontSize: 10, color: Color(0xFF059669), fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search & AI Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (val) => setState(() => _searchQuery = val),
                        onSubmitted: (val) {
                          if (val.trim().isNotEmpty) _askAiLexicon(val.trim());
                        },
                        decoration: InputDecoration(
                          hintText: 'Search or type any word to explain with AI...',
                          hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                          prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF64748B)),
                          filled: true,
                          fillColor: const Color(0xFFF1F5F9),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // AI Lookup Button
                    GestureDetector(
                      onTap: () {
                        if (_searchCtrl.text.trim().isNotEmpty) {
                          _askAiLexicon(_searchCtrl.text.trim());
                        }
                      },
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.auto_awesome_rounded, color: Color(0xFF38BDF8), size: 16),
                            SizedBox(width: 4),
                            Text('Ask AI', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Category Chips
                SizedBox(
                  height: 30,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      final isSelected = _selectedCategory == cat;

                      return InkWell(
                        onTap: () => setState(() => _selectedCategory = cat),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF059669) : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF059669) : const Color(0xFFCBD5E1),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            cat,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: isSelected ? Colors.white : const Color(0xFF475569),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // AI CUSTOM RESULT DRAWER
          if (_isAiSearching || _aiCustomExplanation != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.auto_awesome_rounded, color: Color(0xFF38BDF8), size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'AI REAL ESTATE LEXICON: "${_aiExplainingTerm ?? ''}"',
                            style: const TextStyle(
                              color: Color(0xFF38BDF8),
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => setState(() {
                          _aiCustomExplanation = null;
                          _aiExplainingTerm = null;
                        }),
                        child: const Icon(Icons.close_rounded, color: Colors.white70, size: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_isAiSearching)
                    Row(
                      children: const [
                        SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF38BDF8))),
                        SizedBox(width: 10),
                        Text('Analyzing Nigerian legal & construction lexicon...', style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 12)),
                      ],
                    )
                  else
                    Text(
                      _aiCustomExplanation ?? '',
                      style: const TextStyle(color: Colors.white, fontSize: 12.5, height: 1.45),
                    ),
                ],
              ),
            ),

          // Dictionary Items List
          Expanded(
            child: list.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off_rounded, size: 48, color: Color(0xFFCBD5E1)),
                        const SizedBox(height: 12),
                        Text(
                          'No dictionary terms found for "$_searchQuery"',
                          style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () => _askAiLexicon(_searchQuery),
                          icon: const Icon(Icons.auto_awesome_rounded, size: 16, color: Colors.white),
                          label: const Text('Ask AI to Explain this Term', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF059669),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final item = list[index];
                      return _buildDictionaryCard(context, item);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDictionaryCard(BuildContext context, Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(item['icon'] as IconData? ?? Icons.book_rounded, color: const Color(0xFF059669), size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['term'] ?? '',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item['category'] ?? 'GENERAL',
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF64748B)),
                        ),
                      ),
                    ],
                  ),
                ),
                // AI Explain Mini Button
                IconButton(
                  icon: const Icon(Icons.auto_awesome_rounded, size: 18, color: Color(0xFF0284C7)),
                  tooltip: 'Explain with AI',
                  onPressed: () => _askAiLexicon(item['term'] ?? ''),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Definition
            Text(
              item['shortDef'] ?? '',
              style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.45, fontWeight: FontWeight.w500),
            ),

            const SizedBox(height: 10),

            // Nigerian Context Box
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.flag_rounded, size: 15, color: Color(0xFF059669)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '🇳🇬 Nigerian Context: ${item['nigerianContext'] ?? ''}',
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569), height: 1.35),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Risk / Caution
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 15, color: Color(0xFFD97706)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '⚠️ What to watch out for: ${item['keyRisk'] ?? ''}',
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF92400E), height: 1.35, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
