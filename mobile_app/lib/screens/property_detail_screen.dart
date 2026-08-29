import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/colors.dart';
import '../core/utils/currency_formatter.dart';
import '../models/property_model.dart';
import '../providers/purchase_provider.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';

class PropertyDetailScreen extends StatefulWidget {
  final PropertyModel property;

  const PropertyDetailScreen({super.key, required this.property});

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  int _selectedImageIndex = 0;
  PaymentPlanModel? _selectedPlan;

  @override
  void initState() {
    super.initState();
    if (widget.property.paymentPlans.isNotEmpty) {
      _selectedPlan = widget.property.paymentPlans[0];
    }
  }

  @override
  Widget build(BuildContext context) {
    final prop = widget.property;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Silver App Bar Gallery
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppColors.primaryDark,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  PageView.builder(
                    itemCount: prop.images.isNotEmpty ? prop.images.length : 1,
                    onPageChanged: (index) {
                      setState(() => _selectedImageIndex = index);
                    },
                    itemBuilder: (context, index) {
                      final url = prop.images.isNotEmpty ? prop.images[index] : prop.firstImage;
                      return Image.network(
                        url,
                        width: double.infinity,
                        height: 300,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade400),
                      );
                    },
                  ),
                  Positioned(
                    bottom: 12,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_selectedImageIndex + 1} / ${prop.images.isNotEmpty ? prop.images.length : 1}',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Details Body
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Badges
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          prop.propertyType,
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.emeraldBg,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.emeraldText.withOpacity(0.4)),
                        ),
                        child: Text(
                          prop.landTitle.replaceAll('_', ' '),
                          style: const TextStyle(color: AppColors.emeraldText, fontSize: 10, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    prop.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 16, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${prop.address}, ${prop.area}, ${prop.city}',
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  // Price Overview Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TOTAL PURCHASE PRICE',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          CurrencyFormatter.format(prop.price),
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primary),
                        ),
                        if (prop.landSize != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Land Size: ${prop.landSize}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Payment Plans Section (Pay-Small-Small)
                  if (prop.paymentPlans.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Flexible Payment Plans',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 10),
                    ...prop.paymentPlans.map((plan) {
                      final isSelected = _selectedPlan?.id == plan.id;
                      return InkWell(
                        onTap: () => setState(() => _selectedPlan = plan),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.cardBorder,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(plan.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Initial: ${CurrencyFormatter.format(plan.initialDeposit)} • ${plan.durationMonths} Months',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                              Text(
                                '${CurrencyFormatter.format(plan.monthlyPayment)}/mo',
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.emeraldText),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ],

                  // Developer Profile Card
                  if (prop.developer != null) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Verified Developer Profile',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.business_rounded, color: AppColors.primary),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      prop.developer!.companyName,
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.textPrimary),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'CAC: ${prop.developer!.cacNumber} • ${prop.developer!.yearsOperating} Years Active',
                                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.emeraldBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified, size: 14, color: AppColors.emeraldText),
                                SizedBox(width: 6),
                                Text(
                                  'Corporate CAC, Directors & Track Record Verified',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.emeraldText),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Description
                  const SizedBox(height: 24),
                  const Text(
                    'Property Description',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    prop.description,
                    style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.textSecondary),
                  ),

                  // Legal Disclaimer Notice
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.amberBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.accentGold.withOpacity(0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Icon(Icons.info_outline, color: AppColors.amberText, size: 18),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'EstateVerify coordinates document verification and structured payment plans. Legal rights and allocations are governed by the executed purchase contract.',
                            style: TextStyle(fontSize: 11, color: AppColors.amberText, height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.cardBorder)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -3)),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showInspectionDialog(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Book Inspection', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _handleStartPurchase(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Start Purchase', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInspectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Schedule Site Inspection', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Inspection Team: EstateVerify Technical Officers & Developer Rep.'),
            SizedBox(height: 12),
            Text('Available Days: Monday - Saturday (10:00 AM - 4:00 PM)'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Inspection request submitted successfully!')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Confirm Date'),
          ),
        ],
      ),
    );
  }

  void _handleStartPurchase(BuildContext context) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isAuthenticated) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }

    final purchaseProvider = Provider.of<PurchaseProvider>(context, listen: false);
    final purchase = await purchaseProvider.initiatePurchase(
      propertyId: widget.property.id,
      paymentPlanId: _selectedPlan?.id,
    );

    if (purchase != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Purchase record created: ${purchase.purchaseCode}')),
      );
    }
  }
}
