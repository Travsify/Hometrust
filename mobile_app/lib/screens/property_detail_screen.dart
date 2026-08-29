import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/colors.dart';
import '../core/utils/currency_formatter.dart';
import '../core/network/api_client.dart';
import '../models/property_model.dart';
import '../providers/purchase_provider.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'chat_screen.dart';
import 'kyc_screen.dart';
import '../widgets/in_app_call_modal.dart';

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

                  // CRITICAL ESCROW SECURITY NOTICE
                  Container(
                    margin: const EdgeInsets.only(top: 14),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'CRITICAL ESCROW SECURITY NOTICE',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF991B1B)),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Always make all payments exclusively through HomeVerify in-app escrow. NEVER pay directly to developers or agents. Payments made outside HomeVerify cannot be tracked, protected, or refunded.',
                                style: TextStyle(fontSize: 11, color: Color(0xFFB91C1C), height: 1.35, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
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
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    final auth = Provider.of<AuthProvider>(context, listen: false);
                                    if (!auth.isAuthenticated) {
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                                      return;
                                    }
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ChatScreen(
                                          recipientName: prop.developer!.companyName,
                                          propertyTitle: prop.title,
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: AppColors.primary),
                                  label: const Text('Chat In-App', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primary)),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    side: const BorderSide(color: AppColors.primary, width: 1.2),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    final auth = Provider.of<AuthProvider>(context, listen: false);
                                    if (!auth.isAuthenticated) {
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                                      return;
                                    }
                                    InAppCallModal.show(
                                      context,
                                      entityName: prop.developer!.companyName,
                                    );
                                  },
                                  icon: const Icon(Icons.phone_in_talk_rounded, size: 14, color: Colors.white),
                                  label: const Text('Call In-App', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF059669),
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    elevation: 0,
                                  ),
                                ),
                              ),
                            ],
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
                            'HomeVerify coordinates document verification and structured payment plans. Legal rights and allocations are governed by the executed purchase contract.',
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
              // In-App Chat / Call Action Trigger
              InkWell(
                onTap: () {
                  final devName = widget.property.developer?.companyName ?? 'Verified Developer';
                  showModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (ctx) => Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            devName,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Encrypted In-App Communication • Phone Numbers Masked',
                            style: TextStyle(fontSize: 11, color: Color(0xFF059669), fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 20),
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primary),
                            ),
                            title: const Text('Chat In-App', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                            subtitle: const Text('Send instant messages to developer rep', style: TextStyle(fontSize: 12)),
                            onTap: () {
                              Navigator.pop(ctx);
                              final auth = Provider.of<AuthProvider>(context, listen: false);
                              if (!auth.isAuthenticated) {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                                return;
                              }
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatScreen(
                                    recipientName: devName,
                                    propertyTitle: widget.property.title,
                                  ),
                                ),
                              );
                            },
                          ),
                          const Divider(),
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.phone_in_talk_rounded, color: Color(0xFF059669)),
                            ),
                            title: const Text('Call In-App', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                            subtitle: const Text('Encrypted audio relay (no phone number required)', style: TextStyle(fontSize: 12)),
                            onTap: () {
                              Navigator.pop(ctx);
                              final auth = Provider.of<AuthProvider>(context, listen: false);
                              if (!auth.isAuthenticated) {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                                return;
                              }
                              InAppCallModal.show(context, entityName: devName);
                            },
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.forum_rounded, color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showInspectionDialog(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Book Inspection', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _handleStartPurchase(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Start Purchase', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInspectionDialog(BuildContext context) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isAuthenticated) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.lock_outline_rounded, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Sign In Required', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ],
          ),
          content: const Text(
            'Please sign in or create an account to book an on-site property inspection so we can verify your identity and generate your official inspection pass.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Sign In / Register', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
      return;
    }

    DateTime selectedDate = DateTime.now().add(const Duration(days: 2));

    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      helpText: 'Select Inspection Date',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );

    if (picked == null || !mounted) return;
    selectedDate = picked;

    // Confirm dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Inspection Request', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Property: ${widget.property.title}'),
            const SizedBox(height: 8),
            Text('Date: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
            const SizedBox(height: 8),
            const Text('Team: HomeVerify Technical Officers & Developer Rep.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            const Text('Hours: 10:00 AM – 4:00 PM', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ApiClient.post('/inspections', {
        'propertyId': widget.property.id,
        'scheduledDate': selectedDate.toIso8601String(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inspection request submitted! Our team will confirm within 24 hours.'),
            backgroundColor: AppColors.emeraldText,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not submit inspection: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppColors.roseText,
          ),
        );
      }
    }
  }

  void _handleStartPurchase(BuildContext context) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isAuthenticated) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }

    // Mandatory KYC Verification Gate for Property Purchases & Escrow
    if (auth.user?.isVerified != true) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.verified_user_outlined, color: Color(0xFF059669)),
              SizedBox(width: 8),
              Text('KYC Verification Required', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            ],
          ),
          content: const Text(
            'Under CBN real estate escrow regulations, all property purchases (Off-Plan & Pay-Small-Small) require a verified identity.\n\nPlease complete your quick KYC verification to activate your dedicated bank account and proceed with this purchase.',
            style: TextStyle(fontSize: 12.5, height: 1.4, color: Color(0xFF475569)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const KycScreen()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Verify KYC Now 🛡️', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      );
      return;
    }

    final purchaseProvider = Provider.of<PurchaseProvider>(context, listen: false);

    // Single Active Property Purchase Enforcement
    final hasActivePurchase = purchaseProvider.userPurchases.any(
      (p) => (p.status == 'ACTIVE' || p.status == 'INITIATED') && p.outstandingBalance > 0,
    );

    if (hasActivePurchase) {
      final active = purchaseProvider.userPurchases.firstWhere(
        (p) => (p.status == 'ACTIVE' || p.status == 'INITIATED') && p.outstandingBalance > 0,
      );
      final activeTitle = active.property?.title ?? active.projectUnit?.name ?? active.purchaseCode;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.info_outline_rounded, color: Color(0xFFEA580C)),
              SizedBox(width: 8),
              Text('Active Order in Progress', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            ],
          ),
          content: Text(
            'You currently have an active property purchase ($activeTitle - ${active.purchaseCode}) in progress.\n\nTo ensure complete milestone escrow protection, only one property purchase is permitted at a time. Please complete your existing balance before adding another property.',
            style: const TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF475569)),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Understood', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      return;
    }

    final purchase = await purchaseProvider.initiatePurchase(
      propertyId: widget.property.id,
      paymentPlanId: _selectedPlan?.id,
    );

    if (purchase != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Purchase created: ${purchase.purchaseCode} — Transfer to your dedicated account to begin.'),
          backgroundColor: AppColors.emeraldText,
        ),
      );
    }
  }
}
