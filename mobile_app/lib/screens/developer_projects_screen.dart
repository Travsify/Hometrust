import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../models/project_model.dart';
import 'developer_milestone_submission_modal.dart';
import 'project_detail_screen.dart';

class DeveloperProjectsScreen extends StatefulWidget {
  const DeveloperProjectsScreen({super.key});

  @override
  State<DeveloperProjectsScreen> createState() => _DeveloperProjectsScreenState();
}

class _DeveloperProjectsScreenState extends State<DeveloperProjectsScreen> {
  bool _isLoading = true;
  List<dynamic> _projects = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchProjects();
  }

  Future<void> _fetchProjects() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await ApiClient.get('/developers/my-projects');
      if (mounted) {
        setState(() {
          _projects = data is List ? data : [];
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

  void _showAddProjectModal() {
    String projectType = 'OFF_PLAN'; // OFF_PLAN or PAY_SMALL_SMALL
    String propertyCategory = 'TERRACE'; // LAND, TERRACE, APARTMENT, DUPLEX, COMMERCIAL
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final areaCtrl = TextEditingController();
    final completionCtrl = TextEditingController(text: 'Q4 2027');
    String selectedState = 'Lagos';
    String selectedCity = 'Lekki';

    // Dynamic Multi-Document List
    final List<Map<String, dynamic>> projectDocuments = [
      {
        'type': 'Certificate of Occupancy (C of O)',
        'numberCtrl': TextEditingController(),
        'urlCtrl': TextEditingController(),
      },
      {
        'type': 'Registered Cadastral Survey Plan',
        'numberCtrl': TextEditingController(),
        'urlCtrl': TextEditingController(),
      },
    ];

    // Dynamic Multi-Media Walkthrough List
    final List<Map<String, dynamic>> projectWalkthroughs = [
      {
        'mediaType': 'Aerial Drone Walkthrough (YouTube / MP4)',
        'titleCtrl': TextEditingController(text: 'Aerial Site Drone Walkthrough'),
        'urlCtrl': TextEditingController(),
      },
      {
        'mediaType': 'Matterport 3D Virtual Tour / 360°',
        'titleCtrl': TextEditingController(text: '3D Virtual Matterport Tour'),
        'urlCtrl': TextEditingController(),
      },
    ];

    // Unit / Package details
    final unitNameCtrl = TextEditingController(text: '3 Bedroom Luxury Terrace');
    final unitPriceCtrl = TextEditingController(text: '75000000');
    final unitDepositCtrl = TextEditingController(text: '15000000');
    final unitCountCtrl = TextEditingController(text: '8');
    final durationMonthsCtrl = TextEditingController(text: '12');
    final possessionThresholdCtrl = TextEditingController(text: '50');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isPaySmallSmall = projectType == 'PAY_SMALL_SMALL';

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
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isPaySmallSmall ? 'Publish Pay-Small-Small Package' : 'Publish Off-Plan Project',
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                        ),
                        IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isPaySmallSmall
                          ? 'Sell existing houses or serviced land plots by structured monthly instalments.'
                          : 'List a new off-plan estate development protected by Hometrust Milestone Escrow.',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 16),

                    // ── PROJECT TYPE TOGGLE ──
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setModalState(() {
                                  projectType = 'OFF_PLAN';
                                  unitNameCtrl.text = '3 Bedroom Luxury Terrace';
                                  completionCtrl.text = 'Q4 2027';
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: !isPaySmallSmall ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(9),
                                  boxShadow: !isPaySmallSmall
                                      ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
                                      : null,
                                ),
                                child: Center(
                                  child: Text(
                                    '🏗️ Off-Plan (Milestones)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: !isPaySmallSmall ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setModalState(() {
                                  projectType = 'PAY_SMALL_SMALL';
                                  unitNameCtrl.text = '500 SQM Serviced Plot (or Finished Unit)';
                                  completionCtrl.text = 'Immediate / Ready';
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: isPaySmallSmall ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(9),
                                  boxShadow: isPaySmallSmall
                                      ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
                                      : null,
                                ),
                                child: Center(
                                  child: Text(
                                    '💳 Pay Small Small',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: isPaySmallSmall ? const Color(0xFF059669) : const Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Property Sub-type Selector
                    DropdownButtonFormField<String>(
                      value: propertyCategory,
                      decoration: InputDecoration(
                        labelText: 'Property Category',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'TERRACE', child: Text('Terrace / Townhouse')),
                        DropdownMenuItem(value: 'DUPLEX', child: Text('Semi-Detached / Detached Duplex')),
                        DropdownMenuItem(value: 'APARTMENT', child: Text('Apartment / Flat')),
                        DropdownMenuItem(value: 'LAND', child: Text('Serviced Land / Residential Plots')),
                        DropdownMenuItem(value: 'COMMERCIAL', child: Text('Commercial Space / Office')),
                      ],
                      onChanged: (val) => setModalState(() => propertyCategory = val!),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: isPaySmallSmall ? 'Package / Estate Name (e.g. Greenwood Park Plots)' : 'Project Name (e.g. Ikate Luxury Heights)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedState,
                            decoration: InputDecoration(
                              labelText: 'State',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            items: ['Lagos', 'Abuja FCT', 'Rivers', 'Ogun', 'Oyo', 'Enugu', 'Anambra', 'Delta']
                                .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13))))
                                .toList(),
                            onChanged: (val) => selectedState = val!,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: areaCtrl,
                            decoration: InputDecoration(
                              labelText: 'Area (e.g. Lekki Phase 1)',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: addressCtrl,
                      decoration: InputDecoration(
                        labelText: 'Site Address',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (!isPaySmallSmall) ...[
                      TextField(
                        controller: completionCtrl,
                        decoration: InputDecoration(
                          labelText: 'Estimated Completion (e.g. Q4 2027)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    TextField(
                      controller: descCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Description & Infrastructure (Roads, Drainage, Power)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── DYNAMIC MEDIA & VIDEO WALKTHROUGHS ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Media & Virtual Walkthroughs (${projectWalkthroughs.length})',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            setModalState(() {
                              projectWalkthroughs.add({
                                'mediaType': 'Aerial Drone Walkthrough (YouTube / MP4)',
                                'titleCtrl': TextEditingController(text: 'Site Walkthrough ${projectWalkthroughs.length + 1}'),
                                'urlCtrl': TextEditingController(),
                              });
                            });
                          },
                          icon: const Icon(Icons.add_circle_outline_rounded, size: 16, color: Color(0xFF0284C7)),
                          label: const Text('Add Media', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0284C7))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Upload drone site videos, Matterport 3D tours, and live streaming links for prospective buyers.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 10),

                    ...projectWalkthroughs.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final walk = entry.value;
                      final mediaType = walk['mediaType'] as String;
                      final urlCtrl = walk['urlCtrl'] as TextEditingController;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Media #${idx + 1}',
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF0284C7)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: mediaType,
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      border: OutlineInputBorder(),
                                    ),
                                    items: const [
                                      DropdownMenuItem(value: 'Aerial Drone Walkthrough (YouTube / MP4)', child: Text('Aerial Drone Video', style: TextStyle(fontSize: 12))),
                                      DropdownMenuItem(value: 'Matterport 3D Virtual Tour / 360°', child: Text('Matterport 3D Tour', style: TextStyle(fontSize: 12))),
                                      DropdownMenuItem(value: 'Architectural 3D Render Video', child: Text('3D Architectural Video', style: TextStyle(fontSize: 12))),
                                      DropdownMenuItem(value: 'Live Site Progress Stream', child: Text('Live Progress Stream', style: TextStyle(fontSize: 12))),
                                    ],
                                    onChanged: (val) => setModalState(() => walk['mediaType'] = val!),
                                  ),
                                ),
                                if (projectWalkthroughs.length > 1) ...[
                                  const SizedBox(width: 6),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                                    onPressed: () => setModalState(() => projectWalkthroughs.removeAt(idx)),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: urlCtrl,
                              decoration: InputDecoration(
                                labelText: 'Media Stream / Embed URL (YouTube, Matterport, MP4)',
                                hintText: 'https://...',
                                isDense: true,
                                prefixIcon: const Icon(Icons.link_rounded, size: 18, color: Color(0xFF0284C7)),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 14),

                    // ── DYNAMIC MULTI-DOCUMENT ATTACHMENT VAULT ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Title & Legal Documents (${projectDocuments.length})',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            setModalState(() {
                              projectDocuments.add({
                                'type': 'Governor’s Consent',
                                'numberCtrl': TextEditingController(),
                                'urlCtrl': TextEditingController(),
                              });
                            });
                          },
                          icon: const Icon(Icons.add_circle_outline_rounded, size: 16, color: Color(0xFF059669)),
                          label: const Text('Add Document', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF059669))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'All attached documents are stored in Hometrust Secure Read-Only Vault with dynamic watermarking. Buyers cannot download raw files.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 10),

                    ...projectDocuments.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final doc = entry.value;
                      final docType = doc['type'] as String;
                      final numCtrl = doc['numberCtrl'] as TextEditingController;
                      final urlCtrl = doc['urlCtrl'] as TextEditingController;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF059669).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Doc #${idx + 1}',
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF059669)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: docType,
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      border: OutlineInputBorder(),
                                    ),
                                    items: const [
                                      DropdownMenuItem(value: 'Certificate of Occupancy (C of O)', child: Text('Certificate of Occupancy (C of O)', style: TextStyle(fontSize: 12))),
                                      DropdownMenuItem(value: 'Governor’s Consent', child: Text('Governor’s Consent', style: TextStyle(fontSize: 12))),
                                      DropdownMenuItem(value: 'Registered Cadastral Survey Plan', child: Text('Registered Survey Plan', style: TextStyle(fontSize: 12))),
                                      DropdownMenuItem(value: 'Approved Architectural / Building Plan', child: Text('Approved Building Plan', style: TextStyle(fontSize: 12))),
                                      DropdownMenuItem(value: 'Gazette / Excision Record', child: Text('Gazette / Excision', style: TextStyle(fontSize: 12))),
                                      DropdownMenuItem(value: 'Deed of Assignment / Conveyance', child: Text('Deed of Assignment', style: TextStyle(fontSize: 12))),
                                      DropdownMenuItem(value: 'Layout Approval & Allocation Letter', child: Text('Layout / Allocation Letter', style: TextStyle(fontSize: 12))),
                                      DropdownMenuItem(value: 'Environmental Impact Assessment (EIA)', child: Text('EIA Assessment', style: TextStyle(fontSize: 12))),
                                      DropdownMenuItem(value: 'Custom Legal Title Instrument', child: Text('Custom Legal Document', style: TextStyle(fontSize: 12))),
                                    ],
                                    onChanged: (val) => setModalState(() => doc['type'] = val!),
                                  ),
                                ),
                                if (projectDocuments.length > 1) ...[
                                  const SizedBox(width: 6),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                                    onPressed: () => setModalState(() => projectDocuments.removeAt(idx)),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: numCtrl,
                              decoration: InputDecoration(
                                labelText: 'Registration / Plan / Gazette Number',
                                hintText: 'e.g. Vol 2024 Page 45 / OG/2023/118',
                                isDense: true,
                                prefixIcon: const Icon(Icons.tag_rounded, size: 18, color: Color(0xFF059669)),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: urlCtrl,
                              decoration: InputDecoration(
                                labelText: 'Document Vault URL / File Reference',
                                hintText: 'https://vault.hometrust.ng/docs/...',
                                isDense: true,
                                prefixIcon: const Icon(Icons.cloud_upload_outlined, size: 18, color: Color(0xFF059669)),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    // Quick Add Document Outlined Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setModalState(() {
                            projectDocuments.add({
                              'type': 'Approved Architectural / Building Plan',
                              'numberCtrl': TextEditingController(),
                              'urlCtrl': TextEditingController(),
                            });
                          });
                        },
                        icon: const Icon(Icons.add_rounded, size: 16, color: Color(0xFF059669)),
                        label: const Text('+ Add Another Property Document', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFF059669))),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF059669), width: 1.2),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── UNIT / PACKAGE FINANCIAL CONFIGURATION ──
                    Text(
                      isPaySmallSmall ? 'Installment Financial Terms' : 'Unit Financial Configuration',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: unitNameCtrl,
                      decoration: InputDecoration(
                        labelText: isPaySmallSmall ? 'Package / Plot Name' : 'Unit Type Name',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: unitPriceCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Total Price (NGN)',
                              prefixText: '₦ ',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: unitDepositCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Initial Deposit (NGN)',
                              prefixText: '₦ ',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: durationMonthsCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Tenor (Months)',
                              hintText: isPaySmallSmall ? '24' : '12',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: unitCountCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Total Units/Plots',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (isPaySmallSmall) ...[
                      const SizedBox(height: 10),
                      TextField(
                        controller: possessionThresholdCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Move-In / Site Demarcation Threshold (%)',
                          hintText: '50',
                          suffixText: '% paid',
                          helperText: 'Buyer receives physical possession or fencing rights once this % is cleared into escrow.',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (nameCtrl.text.isEmpty || addressCtrl.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter project name and address')),
                            );
                            return;
                          }

                          final price = double.tryParse(unitPriceCtrl.text) ?? 50000000;
                          final deposit = double.tryParse(unitDepositCtrl.text) ?? 15000000;
                          final count = int.tryParse(unitCountCtrl.text) ?? 4;
                          final tenor = int.tryParse(durationMonthsCtrl.text) ?? (isPaySmallSmall ? 24 : 12);
                          final monthly = (price - deposit) > 0 ? (price - deposit) / tenor : 0.0;

                          // Compile all dynamic walkthrough media
                          final validWalkthroughs = projectWalkthroughs
                              .where((w) => (w['urlCtrl'] as TextEditingController).text.trim().isNotEmpty)
                              .toList();
                          final firstVideo = validWalkthroughs.isNotEmpty
                              ? (validWalkthroughs.first['urlCtrl'] as TextEditingController).text.trim()
                              : null;
                          final first3dTour = validWalkthroughs.length > 1
                              ? (validWalkthroughs[1]['urlCtrl'] as TextEditingController).text.trim()
                              : null;

                          // Compile all dynamic property documents
                          final formattedDocs = projectDocuments.map((d) {
                            final docType = d['type'] as String;
                            final numText = (d['numberCtrl'] as TextEditingController).text.trim();
                            final urlText = (d['urlCtrl'] as TextEditingController).text.trim();
                            final docSlug = docType.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');

                            return {
                              'documentType': docType,
                              'fileName': numText.isNotEmpty ? '$docType ($numText)' : docType,
                              'documentNumber': numText.isNotEmpty ? numText : 'VERIFIED-DOC-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                              'fileUrl': urlText.isNotEmpty ? urlText : 'https://vault.hometrust.ng/docs/$docSlug.pdf',
                            };
                          }).toList();

                          final payload = {
                            'projectType': projectType,
                            'propertyCategory': propertyCategory,
                            'name': nameCtrl.text.trim(),
                            'description': descCtrl.text.trim().isNotEmpty
                                ? descCtrl.text.trim()
                                : (isPaySmallSmall
                                    ? 'Serviced plots & residential packages with structured monthly instalment plans.'
                                    : 'Luxury off-plan development protected by Hometrust Milestone Escrow.'),
                            'state': selectedState,
                            'city': selectedCity,
                            'area': areaCtrl.text.trim().isNotEmpty ? areaCtrl.text.trim() : 'Lekki',
                            'address': addressCtrl.text.trim(),
                            'expectedCompletion': isPaySmallSmall ? 'Immediate / Ready' : completionCtrl.text.trim(),
                            'videoUrl': firstVideo,
                            'virtualTourUrl': first3dTour,
                            'mediaWalkthroughs': validWalkthroughs.map((w) => {
                              'mediaType': w['mediaType'],
                              'title': (w['titleCtrl'] as TextEditingController).text.trim(),
                              'url': (w['urlCtrl'] as TextEditingController).text.trim(),
                            }).toList(),
                            'documentUrls': formattedDocs,
                            'units': [
                              {
                                'unitType': unitNameCtrl.text.trim(),
                                'name': unitNameCtrl.text.trim(),
                                'size': isPaySmallSmall ? '500 SQM Serviced Plot' : '180 SQM',
                                'bedrooms': propertyCategory == 'LAND' ? 0 : 3,
                                'bathrooms': propertyCategory == 'LAND' ? 0 : 3,
                                'price': price,
                                'initialDeposit': deposit,
                                'durationMonths': tenor,
                                'monthlyInstalment': monthly,
                                'totalUnits': count,
                              },
                            ],
                          };

                          try {
                            await ApiClient.post('/developers/projects', payload);
                            if (mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('🎉 ${isPaySmallSmall ? "Pay-Small-Small Package" : "Off-Plan Project"} published successfully!'),
                                  backgroundColor: const Color(0xFF059669),
                                ),
                              );
                              _fetchProjects();
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(e.toString().replaceAll('Exception: ', '')),
                                  backgroundColor: const Color(0xFFDC2626),
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isPaySmallSmall ? const Color(0xFF059669) : const Color(0xFF0F172A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          isPaySmallSmall ? 'Publish Pay-Small-Small Package' : 'Publish Off-Plan Project',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
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
        title: const Text('My Projects & Inventory', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF334155)),
            onPressed: _fetchProjects,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddProjectModal,
        backgroundColor: const Color(0xFF059669),
        icon: const Icon(Icons.add_home_work_rounded, color: Colors.white),
        label: const Text('Add Project', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF059669)))
          : _projects.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.apartment_rounded, size: 64, color: Color(0xFFCBD5E1)),
                        const SizedBox(height: 16),
                        const Text('No Projects Listed Yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                        const SizedBox(height: 8),
                        const Text(
                          'Publish your off-plan estates and residential developments to start receiving verified buyer subscriptions.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _showAddProjectModal,
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Create First Project', style: TextStyle(fontWeight: FontWeight.w800)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF059669),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchProjects,
                  color: const Color(0xFF059669),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _projects.length,
                    itemBuilder: (context, index) {
                      final project = _projects[index];
                      final units = (project['units'] as List?) ?? [];
                      final totalUnits = project['totalUnits'] ?? units.length;
                      final availableUnits = project['availableUnits'] ?? totalUnits;
                      final milestones = (project['milestones'] as List?) ?? [];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Project Header Image & Title
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          project['name'] ?? 'Estate Project',
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF059669).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          project['status'] ?? 'UNDER_CONSTRUCTION',
                                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF059669)),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF64748B)),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${project['area'] ?? project['city']}, ${project['state']}',
                                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1, color: Color(0xFFF1F5F9)),

                            // Units Inventory Strip
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Inventory Status', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                      const SizedBox(height: 2),
                                      Text(
                                        '$availableUnits / $totalUnits Available',
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text('Completion Target', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                      const SizedBox(height: 2),
                                      Text(
                                        project['expectedCompletion'] ?? 'Q4 2027',
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0284C7)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Milestones & Escrow Manager Strip
                            if (milestones.isNotEmpty) ...[
                              InkWell(
                                onTap: () => _showMilestoneManagerModal(project),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.foundation_rounded, size: 18, color: Color(0xFF059669)),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Milestones: ${milestones.length} Certified Stages',
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                            ),
                                            const SizedBox(height: 2),
                                            const Text(
                                              'Tap to submit COREN proof packs & review escrow release status',
                                              style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF94A3B8)),
                                    ],
                                  ),
                                ),
                              ),
                            ],

                            // Actions
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _showMilestoneManagerModal(project),
                                      icon: const Icon(Icons.engineering_outlined, size: 16, color: Color(0xFF059669)),
                                      label: const Text('Manage Milestones', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF059669))),
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(color: Color(0xFF059669)),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ProjectDetailScreen(
                                              project: ProjectModel.fromJson(project),
                                            ),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF0F172A),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      child: const Text('View Public Page', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  void _showMilestoneManagerModal(Map<String, dynamic> project) {
    final milestones = (project['milestones'] as List?) ?? [];
    final projectId = project['id']?.toString() ?? '';
    final projectName = project['name']?.toString() ?? 'Project';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Certified Milestones & Escrow',
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              projectName,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF059669), fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.2)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.shield_rounded, color: Color(0xFF059669), size: 18),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Tripartite Proof-of-Work: Upload COREN engineer certification, test reports, and 360° video for each phase to trigger 5-day review & escrow tranche releases.',
                            style: TextStyle(fontSize: 11, color: Color(0xFF065F46), height: 1.35),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  Expanded(
                    child: ListView.separated(
                      itemCount: milestones.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, idx) {
                        final m = milestones[idx] as Map<String, dynamic>;
                        final status = m['status'] ?? 'PENDING';
                        final isInReview = status == 'IN_REVIEW';
                        final isDisbursed = status == 'DISBURSED' || status == 'COMPLETED';
                        final isRemediation = status == 'REMEDIATION_REQUIRED';

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isInReview
                                ? const Color(0xFFFFFBEB)
                                : (isDisbursed ? const Color(0xFFECFDF5) : Colors.white),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isInReview
                                  ? const Color(0xFFFDE68A)
                                  : (isDisbursed ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0)),
                              width: isInReview || isDisbursed ? 1.5 : 1.0,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${idx + 1}. ${m['title'] ?? 'Milestone'}',
                                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isInReview
                                          ? const Color(0xFFD97706)
                                          : (isDisbursed ? const Color(0xFF059669) : const Color(0xFF64748B)),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      isInReview ? '5-DAY REVIEW ACTIVE' : (isDisbursed ? 'ESCROW DISBURSED' : status),
                                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                ],
                              ),
                              if (m['description'] != null && m['description'].toString().isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  m['description'],
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                ),
                              ],
                              const SizedBox(height: 10),

                              if (isInReview) ...[
                                const Row(
                                  children: [
                                    Icon(Icons.timer_outlined, size: 14, color: Color(0xFFD97706)),
                                    SizedBox(width: 6),
                                    Text(
                                      'Subscribers are reviewing live video & COREN proof',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF92400E)),
                                    ),
                                  ],
                                ),
                              ] else if (isDisbursed) ...[
                                Row(
                                  children: [
                                    const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF059669)),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Tranche Released: Ref ${m['payoutTransactionRef'] ?? 'ESC-PAID'}',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF065F46)),
                                    ),
                                  ],
                                ),
                              ] else ...[
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        backgroundColor: Colors.transparent,
                                        builder: (_) => DeveloperMilestoneSubmissionModal(
                                          projectId: projectId,
                                          projectName: projectName,
                                          milestone: m,
                                          onSubmitted: _fetchProjects,
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.upload_file_rounded, size: 16),
                                    label: Text(
                                      isRemediation ? 'Resubmit Remediated Proof' : 'Submit Milestone Proof Pack',
                                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isRemediation ? const Color(0xFFE11D48) : const Color(0xFF059669),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      elevation: 0,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
