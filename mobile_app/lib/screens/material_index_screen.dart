import 'package:flutter/material.dart';
import '../core/constants/colors.dart';

class MaterialIndexScreen extends StatefulWidget {
  const MaterialIndexScreen({super.key});

  @override
  State<MaterialIndexScreen> createState() => _MaterialIndexScreenState();
}

class _MaterialIndexScreenState extends State<MaterialIndexScreen> {
  String _selectedCity = 'Lagos (Depot Average)';

  final List<Map<String, dynamic>> _commodities = [
    {
      'name': 'Dangote / BUA Cement (50kg)',
      'spec': 'Grade 42.5N / Portland',
      'price': 'NGN 8,400 - 8,700',
      'unit': 'per 50kg bag',
      'trend': 'STABLE',
      'change': '-1.2% this week',
      'icon': Icons.inventory_2_outlined,
      'color': Color(0xFF059669),
    },
    {
      'name': '12mm High-Yield TMT Rebar',
      'spec': 'FE 500 High-Tensile Steel',
      'price': 'NGN 1,180,000',
      'unit': 'per Ton (approx. 94 lengths)',
      'trend': 'UP',
      'change': '+3.4% this week',
      'icon': Icons.architecture_rounded,
      'color': Color(0xFFDC2626),
    },
    {
      'name': '16mm High-Yield TMT Rebar',
      'spec': 'FE 500 Column / Beam Grade',
      'price': 'NGN 1,220,000',
      'unit': 'per Ton (approx. 53 lengths)',
      'trend': 'UP',
      'change': '+2.8% this week',
      'icon': Icons.straighten_rounded,
      'color': Color(0xFFDC2626),
    },
    {
      'name': 'Granite 3/4 inch (Clean Black)',
      'spec': 'Standard Foundation/Slab aggregate',
      'price': 'NGN 285,000',
      'unit': 'per 30-ton tipper load',
      'trend': 'STABLE',
      'change': '0.0% this week',
      'icon': Icons.terrain_rounded,
      'color': Color(0xFF059669),
    },
    {
      'name': 'Sharp Sand (Washed Creek)',
      'spec': 'Plastering and casting sand',
      'price': 'NGN 145,000',
      'unit': 'per 20-ton tipper load',
      'trend': 'STABLE',
      'change': '0.0% this week',
      'icon': Icons.waves_rounded,
      'color': Color(0xFF059669),
    },
    {
      'name': '9-Inch Solid Sandcrete Blocks',
      'spec': 'Machine-vibrated 1:6 mix',
      'price': 'NGN 780 - 850',
      'unit': 'per piece delivered',
      'trend': 'DOWN',
      'change': '-2.0% this week',
      'icon': Icons.view_module_rounded,
      'color': Color(0xFF059669),
    },
    {
      'name': 'Aluminium Longspan (0.55mm)',
      'spec': 'Coated Anti-Corrosion Sheet',
      'price': 'NGN 7,600',
      'unit': 'per square meter',
      'trend': 'STABLE',
      'change': '+0.5% this week',
      'icon': Icons.roofing_rounded,
      'color': Color(0xFFD97706),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Building Material Index'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                          'WEEKLY BENCHMARK',
                          style: TextStyle(
                            color: AppColors.accentGoldLight,
                            fontWeight: FontWeight.w800,
                            fontSize: 9,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const Text(
                        'Verified by Site QS',
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
                    'Real-time market rates for building materials to protect you from inflated contractor quotations.',
                    style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Live Market Rates',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCity,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      items: const [
                        DropdownMenuItem(value: 'Lagos (Depot Average)', child: Text('Lagos')),
                        DropdownMenuItem(value: 'Abuja (FCT Average)', child: Text('Abuja')),
                        DropdownMenuItem(value: 'Port Harcourt (Rivers)', child: Text('Port Harcourt')),
                        DropdownMenuItem(value: 'Ibadan (Oyo)', child: Text('Ibadan')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedCity = val);
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _commodities.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, idx) {
                final item = _commodities[idx];
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
                      'Tip: Cement prices are currently stable across Western depots. Ideal period to purchase blocks and lock foundation casting.',
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
