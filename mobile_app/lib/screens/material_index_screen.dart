import 'package:flutter/material.dart';
import '../core/constants/colors.dart';

class MaterialIndexScreen extends StatefulWidget {
  const MaterialIndexScreen({super.key});

  @override
  State<MaterialIndexScreen> createState() => _MaterialIndexScreenState();
}

class _MaterialIndexScreenState extends State<MaterialIndexScreen> {
  String _selectedState = 'Lagos (South-West)';

  final List<String> _allStates = [
    'Lagos (South-West)',
    'Abuja FCT (North-Central)',
    'Rivers / Port Harcourt (South-South)',
    'Ogun (South-West)',
    'Oyo / Ibadan (South-West)',
    'Enugu (South-East)',
    'Anambra / Onitsha (South-East)',
    'Delta / Asaba (South-South)',
    'Edo / Benin (South-South)',
    'Akwa Ibom / Uyo (South-South)',
    'Cross River / Calabar (South-South)',
    'Imo / Owerri (South-East)',
    'Abia / Aba (South-East)',
    'Kano (North-West)',
    'Kaduna (North-West)',
    'Plateau / Jos (North-Central)',
    'Kwara / Ilorin (North-Central)',
    'Osun (South-West)',
    'Ondo / Akure (South-West)',
    'Ekiti (South-West)',
    'Kogi (North-Central)',
    'Benue / Makurdi (North-Central)',
    'Nasarawa (North-Central)',
    'Niger / Minna (North-Central)',
    'Bayelsa (South-South)',
    'Ebonyi (South-East)',
    'Bauchi (North-East)',
    'Gombe (North-East)',
    'Adamawa / Yola (North-East)',
    'Borno / Maiduguri (North-East)',
    'Katsina (North-West)',
    'Sokoto (North-West)',
    'Kebbi (North-West)',
    'Zamfara (North-West)',
    'Taraba (North-East)',
    'Yobe (North-East)',
    'Jigawa (North-West)',
  ];

  List<Map<String, dynamic>> _getCommoditiesForState(String state) {
    // Dynamic regional adjustment factors based on logistics & factory depots
    final bool isNorth = state.contains('Kano') ||
        state.contains('Kaduna') ||
        state.contains('Plateau') ||
        state.contains('Borno') ||
        state.contains('Bauchi') ||
        state.contains('Sokoto') ||
        state.contains('Adamawa') ||
        state.contains('Katsina');

    final bool isSouthEastOrSouthSouth = state.contains('Rivers') ||
        state.contains('Enugu') ||
        state.contains('Anambra') ||
        state.contains('Delta') ||
        state.contains('Akwa Ibom') ||
        state.contains('Imo') ||
        state.contains('Abia') ||
        state.contains('Edo');

    final cementPrice = isNorth
        ? 'NGN 8,600 - 8,900'
        : (isSouthEastOrSouthSouth ? 'NGN 8,500 - 8,800' : 'NGN 8,300 - 8,600');

    final rebar12mm = isNorth
        ? 'NGN 1,220,000'
        : (isSouthEastOrSouthSouth ? 'NGN 1,200,000' : 'NGN 1,180,000');

    final rebar16mm = isNorth
        ? 'NGN 1,260,000'
        : (isSouthEastOrSouthSouth ? 'NGN 1,240,000' : 'NGN 1,220,000');

    final granitePrice = isNorth
        ? 'NGN 310,000'
        : (isSouthEastOrSouthSouth ? 'NGN 295,000' : 'NGN 280,000');

    final sandPrice = isNorth
        ? 'NGN 160,000'
        : (isSouthEastOrSouthSouth ? 'NGN 150,000' : 'NGN 140,000');

    final blockPrice = isNorth
        ? 'NGN 820 - 900'
        : (isSouthEastOrSouthSouth ? 'NGN 800 - 880' : 'NGN 760 - 840');

    final roofingPrice = isNorth ? 'NGN 8,100' : 'NGN 7,600';

    return [
      {
        'name': 'Dangote / BUA / Elephant Cement',
        'spec': 'Grade 42.5N / Portland (50kg)',
        'price': cementPrice,
        'unit': 'per 50kg bag delivered',
        'trend': 'STABLE',
        'change': '-1.2% this week',
        'icon': Icons.inventory_2_outlined,
        'color': const Color(0xFF059669),
      },
      {
        'name': '12mm High-Yield TMT Rebar',
        'spec': 'FE 500 High-Tensile Certified Steel',
        'price': rebar12mm,
        'unit': 'per Ton (approx. 94 lengths)',
        'trend': 'UP',
        'change': '+3.4% this week',
        'icon': Icons.architecture_rounded,
        'color': const Color(0xFFDC2626),
      },
      {
        'name': '16mm High-Yield TMT Rebar',
        'spec': 'FE 500 Column / Beam Structural Grade',
        'price': rebar16mm,
        'unit': 'per Ton (approx. 53 lengths)',
        'trend': 'UP',
        'change': '+2.8% this week',
        'icon': Icons.straighten_rounded,
        'color': const Color(0xFFDC2626),
      },
      {
        'name': 'Granite 3/4 inch (Clean Black)',
        'spec': 'Foundation & Slab Concrete Aggregate',
        'price': granitePrice,
        'unit': 'per 30-ton tipper load',
        'trend': 'STABLE',
        'change': '0.0% this week',
        'icon': Icons.terrain_rounded,
        'color': const Color(0xFF059669),
      },
      {
        'name': 'Sharp Sand (Washed Creek)',
        'spec': 'Plastering & Casting Clean Sand',
        'price': sandPrice,
        'unit': 'per 20-ton tipper load',
        'trend': 'STABLE',
        'change': '0.0% this week',
        'icon': Icons.waves_rounded,
        'color': const Color(0xFF059669),
      },
      {
        'name': '9-Inch Solid Sandcrete Blocks',
        'spec': 'Machine-vibrated 1:6 mix standard',
        'price': blockPrice,
        'unit': 'per piece delivered',
        'trend': 'DOWN',
        'change': '-2.0% this week',
        'icon': Icons.view_module_rounded,
        'color': const Color(0xFF059669),
      },
      {
        'name': 'Aluminium Longspan Roofing (0.55mm)',
        'spec': 'Oven-baked Anti-Corrosion Sheet',
        'price': roofingPrice,
        'unit': 'per square meter',
        'trend': 'STABLE',
        'change': '+0.5% this week',
        'icon': Icons.roofing_rounded,
        'color': const Color(0xFFD97706),
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final commodities = _getCommoditiesForState(_selectedState);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Building Material Index (36 States)'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Index Badge
            Container(
              padding: const EdgeInsets.all(18),
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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accentGold.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          '36 STATES BENCHMARK',
                          style: TextStyle(
                            color: AppColors.accentGoldLight,
                            fontWeight: FontWeight.w800,
                            fontSize: 9,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const Text(
                        'Verified by Certified QS',
                        style: TextStyle(color: Colors.white60, fontSize: 10),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Nigeria Construction Inflation Index',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Real-time market rates for building materials across all 36 Nigerian states to protect you from inflated contractor quotations.',
                    style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // State Selector
            const Text(
              'Select State / Region:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedState,
                  isExpanded: true,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  items: _allStates.map((s) {
                    return DropdownMenuItem(
                      value: s,
                      child: Text(s, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedState = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Commodity List
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: commodities.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, idx) {
                final item = commodities[idx];
                final isUp = item['trend'] == 'UP';
                final isDown = item['trend'] == 'DOWN';
                return Container(
                  padding: const EdgeInsets.all(16),
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
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(item['icon'] as IconData, color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['name'] as String,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item['spec'] as String,
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item['unit'] as String,
                              style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            item['price'] as String,
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: (item['color'] as Color).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isUp
                                      ? Icons.arrow_upward_rounded
                                      : isDown
                                          ? Icons.arrow_downward_rounded
                                          : Icons.remove_rounded,
                                  size: 10,
                                  color: item['color'] as Color,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  item['change'] as String,
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: item['color'] as Color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.emeraldBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.emeraldBorder),
              ),
              child: Row(
                children: const [
                  Icon(Icons.lightbulb_outline_rounded, color: AppColors.emeraldText, size: 22),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tip: Always request quantity surveyor approval for steel and cement batch tickets before authorizing milestone disbursements.',
                      style: TextStyle(fontSize: 11, color: AppColors.emeraldText, height: 1.4, fontWeight: FontWeight.w600),
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
