import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/colors.dart';
import '../core/utils/currency_formatter.dart';
import '../providers/property_provider.dart';
import 'property_detail_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  final List<String> _categories = [
    'All',
    'Residential',
    'Apartment',
    'House',
    'Land',
    'Commercial',
    'Off-Plan',
    'Pay-Small-Small',
  ];

  final List<String> _states = ['All', 'Lagos', 'Abuja (FCT)', 'Ogun', 'Rivers'];

  @override
  Widget build(BuildContext context) {
    final propProvider = Provider.of<PropertyProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Explore Properties',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search & Filter Bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search, color: AppColors.textMuted, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _searchCtrl,
                                onSubmitted: (val) {
                                  propProvider.setFilters(search: val);
                                },
                                decoration: const InputDecoration(
                                  hintText: 'Search city, area, title...',
                                  hintStyle: TextStyle(fontSize: 13, color: AppColors.textMuted),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => _showFilterSheet(context, propProvider),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        height: 44,
                        width: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.tune, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
                // PRIMARY SEGMENT SWITCHER (All / Off-Plan / Pay Small Small)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      // 1. All Properties
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            propProvider.setFilters(listingType: 'ALL');
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: (propProvider.selectedListingType == null || propProvider.selectedListingType == 'ALL')
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: (propProvider.selectedListingType == null || propProvider.selectedListingType == 'ALL')
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Text(
                              'All',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: (propProvider.selectedListingType == null || propProvider.selectedListingType == 'ALL')
                                    ? AppColors.primary
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // 2. Off-Plan Projects
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            propProvider.setFilters(listingType: 'OFF_PLAN');
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: propProvider.selectedListingType == 'OFF_PLAN' ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: propProvider.selectedListingType == 'OFF_PLAN'
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Text(
                              '🏗️ Off-Plan',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: propProvider.selectedListingType == 'OFF_PLAN'
                                    ? const Color(0xFF0284C7)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // 3. Pay Small Small
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            propProvider.setFilters(listingType: 'PAY_SMALL_SMALL');
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: propProvider.selectedListingType == 'PAY_SMALL_SMALL' ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: propProvider.selectedListingType == 'PAY_SMALL_SMALL'
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Text(
                              '💳 Pay-Small-Small',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: propProvider.selectedListingType == 'PAY_SMALL_SMALL'
                                    ? const Color(0xFF059669)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // Category Pills
                SizedBox(
                  height: 30,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      final isSelected = (cat == 'All' && propProvider.selectedType == null && (propProvider.selectedListingType == null || propProvider.selectedListingType == 'ALL')) ||
                          (cat == 'Off-Plan' && propProvider.selectedListingType == 'OFF_PLAN') ||
                          (cat == 'Pay-Small-Small' && propProvider.selectedListingType == 'PAY_SMALL_SMALL') ||
                          (cat != 'All' && cat != 'Off-Plan' && cat != 'Pay-Small-Small' && propProvider.selectedType == cat.toUpperCase());

                      return InkWell(
                        onTap: () {
                          if (cat == 'All') {
                            propProvider.setFilters(propertyType: 'All');
                          } else if (cat == 'Off-Plan') {
                            propProvider.setFilters(listingType: 'OFF_PLAN');
                          } else if (cat == 'Pay-Small-Small') {
                            propProvider.setFilters(listingType: 'PAY_SMALL_SMALL');
                          } else {
                            propProvider.setFilters(propertyType: cat.toUpperCase());
                          }
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.cardBorder,
                            ),
                          ),
                          child: Text(
                            cat,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? Colors.white : AppColors.textSecondary,
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

          // Properties List
          Expanded(
            child: propProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : propProvider.properties.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.home_work_outlined, size: 48, color: AppColors.textMuted),
                            const SizedBox(height: 12),
                            const Text(
                              'No properties found matching your search.',
                              style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () => propProvider.clearFilters(),
                              child: const Text('Reset Filters'),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: propProvider.properties.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final prop = propProvider.properties[index];
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
                                            color: AppColors.primary,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            prop.landTitle.replaceAll('_', ' '),
                                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                                          ),
                                        ),
                                      ),
                                      if (prop.developer?.isVerified == true)
                                        Positioned(
                                          top: 10,
                                          right: 10,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: AppColors.emeraldBg,
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: AppColors.emeraldText.withOpacity(0.4)),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.verified, size: 12, color: AppColors.emeraldText),
                                                SizedBox(width: 4),
                                                Text(
                                                  'Verified Developer',
                                                  style: TextStyle(color: AppColors.emeraldText, fontSize: 10, fontWeight: FontWeight.w800),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(16),
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
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text('TOTAL PRICE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                                                Text(CurrencyFormatter.format(prop.price), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                                              ],
                                            ),
                                            if (plan != null)
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                children: [
                                                  const Text('MONTHLY INSTALMENT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.emeraldText)),
                                                  Text('${CurrencyFormatter.format(plan.monthlyPayment)}/mo', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.emeraldText)),
                                                ],
                                              ),
                                          ],
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
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context, PropertyProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Filter Properties', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 12),
              const Text('Filter by State', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _states.map((st) {
                  final isSel = provider.selectedState == st || (st == 'All' && provider.selectedState == null);
                  return ChoiceChip(
                    label: Text(st),
                    selected: isSel,
                    onSelected: (val) {
                      provider.setFilters(state: st == 'All' ? null : st);
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Verified Developers Only', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                value: provider.verifiedOnly,
                onChanged: (val) {
                  provider.setFilters(verifiedOnly: val);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
