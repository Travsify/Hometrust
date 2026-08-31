import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/network/api_client.dart';
import '../core/utils/image_helper.dart';
import '../providers/auth_provider.dart';
import '../widgets/persistent_bottom_nav.dart';
import 'kyc_screen.dart';
import 'login_screen.dart';
import 'support_tickets_screen.dart';
import 'payment_security_screen.dart';

class DeveloperProfileScreen extends StatefulWidget {
  const DeveloperProfileScreen({super.key});

  @override
  State<DeveloperProfileScreen> createState() => _DeveloperProfileScreenState();
}

class _DeveloperProfileScreenState extends State<DeveloperProfileScreen> {
  bool _isLoading = true;
  bool _isUploadingLogo = false;
  Uint8List? _localLogoBytes;
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    _fetchProfileStats();
  }

  Future<void> _fetchProfileStats() async {
    try {
      final data = await ApiClient.get('/developers/my-stats');
      if (mounted) {
        setState(() {
          _stats = data;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<String?> _pickAndUploadImage({required String title}) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: true,
      );

      if (result == null || result.files.isEmpty || result.files.first.bytes == null) return null;

      final file = result.files.first;
      setState(() {
        _localLogoBytes = file.bytes;
        _isUploadingLogo = true;
      });

      final uploadRes = await ApiClient.uploadFile(
        '/storage/upload',
        fileBytes: file.bytes!,
        fileName: file.name,
        fieldName: 'file',
      );

      final String? uploadedUrl = uploadRes['fileUrl'];
      return uploadedUrl;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
      return null;
    } finally {
      if (mounted) setState(() => _isUploadingLogo = false);
    }
  }

  Future<void> _handleDirectLogoUpload() async {
    final uploadedUrl = await _pickAndUploadImage(title: 'Upload Company Logo');
    if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
      try {
        await ApiClient.put('/users/profile', {
          'logoUrl': uploadedUrl,
          'avatarUrl': uploadedUrl,
        });

        if (mounted) {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          await authProvider.refreshUser();
          await _fetchProfileStats();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 Corporate Logo updated successfully!'),
              backgroundColor: Color(0xFF059669),
            ),
          );
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
    }
  }

  void _showEditProfileModal(BuildContext context, Map<String, dynamic>? dev, String currentPhone) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    final companyCtrl = TextEditingController(text: dev?['companyName'] ?? user?.developerCompanyName ?? '');
    
    // Parse existing address parts if available
    final rawAddress = dev?['officeAddress'] ?? '';
    final addressParts = rawAddress.split(',').map((s) => s.trim()).toList();
    final streetText = addressParts.isNotEmpty ? addressParts[0] : '';
    final cityText = addressParts.length > 1 ? addressParts[1] : '';
    final stateText = addressParts.length > 2 ? addressParts[2] : (addressParts.length == 2 ? 'Lagos' : '');

    final streetCtrl = TextEditingController(text: streetText);
    final cityCtrl = TextEditingController(text: cityText);
    final stateCtrl = TextEditingController(text: stateText);
    final phoneCtrl = TextEditingController(text: currentPhone);
    final websiteCtrl = TextEditingController(text: dev?['website'] ?? '');
    final bioCtrl = TextEditingController(text: dev?['about'] ?? '');
    String? currentLogoUrl = dev?['logoUrl'] ?? user?.avatarUrl;
    Uint8List? modalPreviewBytes;
    bool isModalUploading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            Future<void> pickModalLogo() async {
              try {
                final result = await FilePicker.platform.pickFiles(
                  type: FileType.any,
                  withData: true,
                );
                if (result != null && result.files.isNotEmpty && result.files.first.bytes != null) {
                  final file = result.files.first;
                  setModalState(() {
                    modalPreviewBytes = file.bytes;
                    isModalUploading = true;
                  });
                  final uploadRes = await ApiClient.uploadFile(
                    '/storage/upload',
                    fileBytes: file.bytes!,
                    fileName: file.name,
                    fieldName: 'file',
                  );
                  if (uploadRes != null && uploadRes['fileUrl'] != null) {
                    setModalState(() {
                      currentLogoUrl = uploadRes['fileUrl'];
                    });
                  }
                }
              } catch (_) {}
              setModalState(() => isModalUploading = false);
            }

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
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Edit Corporate Profile', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                        IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const Text('Update company identity, logo, structured business addresses, and bio for buyers to learn more about you.', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                    const SizedBox(height: 16),

                    // Logo / Profile Image Picker Box
                    Center(
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
                                ),
                                child: isModalUploading
                                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF059669), strokeWidth: 2))
                                    : ImageHelper.buildAvatar(
                                        imageUrl: currentLogoUrl,
                                        previewBytes: modalPreviewBytes,
                                        size: 80,
                                        fallbackName: companyCtrl.text.isNotEmpty ? companyCtrl.text : 'Company',
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: InkWell(
                                  onTap: pickModalLogo,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF059669),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          TextButton.icon(
                            onPressed: pickModalLogo,
                            icon: const Icon(Icons.upload_file_rounded, size: 14, color: Color(0xFF059669)),
                            label: const Text('Change Company Logo / Image', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF059669))),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 1. Company Name
                    const Text('Company / Business Name', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
                    const SizedBox(height: 5),
                    TextField(
                      controller: companyCtrl,
                      decoration: InputDecoration(
                        hintText: 'e.g. Patrick & Partners Real Estate Ltd',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 2. Structured Head Office Address Breakdown
                    const Text('Head Office / Business Address', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
                    const SizedBox(height: 5),
                    TextField(
                      controller: streetCtrl,
                      decoration: InputDecoration(
                        labelText: 'Street Address',
                        hintText: 'e.g. Plot 14, Admiralty Way, Lekki Phase 1',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          flex: 5,
                          child: TextField(
                            controller: cityCtrl,
                            decoration: InputDecoration(
                              labelText: 'City / District',
                              hintText: 'e.g. Lekki / Ikeja',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 5,
                          child: TextField(
                            controller: stateCtrl,
                            decoration: InputDecoration(
                              labelText: 'State',
                              hintText: 'e.g. Lagos / Abuja',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 3. Corporate Contact Phone
                    const Text('Corporate Contact Phone Number', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
                    const SizedBox(height: 5),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: 'e.g. +234 801 234 5678',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 4. Official Website
                    const Text('Official Website URL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
                    const SizedBox(height: 5),
                    TextField(
                      controller: websiteCtrl,
                      keyboardType: TextInputType.url,
                      decoration: InputDecoration(
                        hintText: 'https://yourcompany.ng',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 5. Bio (Tell buyers and users about yourselves)
                    const Text('About & Organization Bio', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
                    const SizedBox(height: 2),
                    const Text('Provide a bio about yourself and your company so users can learn more about your organization, mission, and projects.', style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
                    const SizedBox(height: 5),
                    TextField(
                      controller: bioCtrl,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Write a bio about your leadership team, corporate philosophy, development experience, and notable residential projects...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.all(14),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final street = streetCtrl.text.trim();
                          final city = cityCtrl.text.trim();
                          final state = stateCtrl.text.trim();

                          final List<String> addressList = [];
                          if (street.isNotEmpty) addressList.add(street);
                          if (city.isNotEmpty) addressList.add(city);
                          if (state.isNotEmpty) addressList.add(state);
                          final fullAddress = addressList.join(', ');

                          try {
                            await ApiClient.put('/users/profile', {
                              'companyName': companyCtrl.text.trim(),
                              'businessAddress': fullAddress,
                              'officeAddress': fullAddress,
                              'phone': phoneCtrl.text.trim(),
                              'website': websiteCtrl.text.trim(),
                              'about': bioCtrl.text.trim(),
                              if (currentLogoUrl != null && currentLogoUrl!.isNotEmpty) 'logoUrl': currentLogoUrl,
                              if (currentLogoUrl != null && currentLogoUrl!.isNotEmpty) 'avatarUrl': currentLogoUrl,
                            });
                            if (context.mounted) {
                              final auth = Provider.of<AuthProvider>(context, listen: false);
                              await auth.refreshUser();
                              if (modalPreviewBytes != null) {
                                setState(() {
                                  _localLogoBytes = modalPreviewBytes;
                                });
                              }
                              Navigator.pop(ctx);
                              _fetchProfileStats();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('🎉 Corporate profile & bio updated successfully!'),
                                  backgroundColor: Color(0xFF059669),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
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
                          backgroundColor: const Color(0xFF0F172A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Save Corporate Changes', style: TextStyle(fontWeight: FontWeight.w800)),
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

  void _showChangePasswordModal(BuildContext context) {
    final currentPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                      const Text('Change Account Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                      IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const Text('Enter your current password and set a new secure password.', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                  const SizedBox(height: 16),

                  TextField(
                    controller: currentPassCtrl,
                    obscureText: obscureCurrent,
                    decoration: InputDecoration(
                      labelText: 'Current Password',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      suffixIcon: IconButton(
                        icon: Icon(obscureCurrent ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                        onPressed: () => setModalState(() => obscureCurrent = !obscureCurrent),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: newPassCtrl,
                    obscureText: obscureNew,
                    decoration: InputDecoration(
                      labelText: 'New Password (min 6 chars)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      suffixIcon: IconButton(
                        icon: Icon(obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                        onPressed: () => setModalState(() => obscureNew = !obscureNew),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: confirmPassCtrl,
                    obscureText: obscureNew,
                    decoration: InputDecoration(
                      labelText: 'Confirm New Password',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (currentPassCtrl.text.isEmpty || newPassCtrl.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please fill all password fields')),
                          );
                          return;
                        }
                        if (newPassCtrl.text != confirmPassCtrl.text) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('New passwords do not match')),
                          );
                          return;
                        }

                        try {
                          await ApiClient.post('/auth/change-password', {
                            'currentPassword': currentPassCtrl.text.trim(),
                            'newPassword': newPassCtrl.text.trim(),
                          });
                          if (context.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('🔒 Password changed successfully!'),
                                backgroundColor: Color(0xFF059669),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
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
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Update Password', style: TextStyle(fontWeight: FontWeight.w800)),
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

  void _showFactsFaqModal(BuildContext context) {
    final faqs = [
      {
        'q': 'How are construction milestone payouts disbursed?',
        'a': 'When you submit a milestone completion request with site photos, a certified Hometrust engineer audits the site. Upon verification, the escrow funds for that specific tranche are unlocked directly to your designated corporate bank account.',
      },
      {
        'q': 'What is the subscriber 3-day inspection window?',
        'a': 'After Hometrust certifies a construction milestone, verified subscribers have a 3-day window to view progress updates before the funds are released from the arbiter vault.',
      },
      {
        'q': 'How do Pay-Small-Small projects work for developers?',
        'a': 'You can list fully titled land plots or residential units for installment sales. Buyers pay initial deposits and monthly installments into the dedicated escrow ledger. You receive structured scheduled tranches.',
      },
      {
        'q': 'How are my title and survey documents protected from forgery?',
        'a': 'All documents uploaded to Hometrust are rendered in a secure read-only cloud container with dynamic buyer watermarks and encrypted viewing tokens. Buyers cannot download or replicate raw source documents.',
      },
      {
        'q': 'What are the criteria for Full Developer KYB Certification?',
        'a': 'Full verification requires: (1) Valid CAC Incorporation Certificate (RC Number), (2) Director National Identity (NIN/BVN), (3) Verified Corporate Head Office Address, and (4) Clean land title track record.',
      },
    ];

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
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.help_center_rounded, color: Color(0xFF0284C7)),
                      SizedBox(width: 8),
                      Text('Developer Facts & Operating Rules', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                    ],
                  ),
                  IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const Text('Frequently Asked Questions regarding Hometrust Escrow, KYB, and Milestone payouts.', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
              const SizedBox(height: 16),

              Expanded(
                child: ListView.separated(
                  itemCount: faqs.length,
                  separatorBuilder: (_, __) => const Divider(height: 16, color: Color(0xFFF1F5F9)),
                  itemBuilder: (context, idx) {
                    final item = faqs[idx];
                    return ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: Text(item['q']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            item['a']!,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.45),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPrivacyPolicyModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.privacy_tip_outlined, color: Color(0xFF059669)),
              SizedBox(width: 8),
              Text('Developer Privacy & NDPR', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
            ],
          ),
          content: const SingleChildScrollView(
            child: Text(
              'Hometrust is strictly compliant with the Nigeria Data Protection Act (NDPA) and NDPR regulations.\n\n'
              '1. Corporate Data Protection: Your uploaded corporate incorporation instruments, director identities, and banking details are encrypted with AES-256 bank-grade cryptography.\n\n'
              '2. Anti-Forgery Watermarking: All property titles and architectural plans you provide are rendered strictly through secure read-only streams with active buyer identity watermarking to eliminate forgery risks.\n\n'
              '3. Arbiter Confidentiality: Payout requests, milestone escrow releases, and banking virtual account ledgers are strictly accessible only to your authorized directors and the designated Hometrust escrow trustees.',
              style: TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.5),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('I Understand', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF059669))),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    final dev = _stats?['developer'] as Map<String, dynamic>?;
    final vba = _stats?['virtualAccount'] as Map<String, dynamic>?;

    final companyName = dev?['companyName'] ?? user?.developerCompanyName ?? (user != null ? '${user.firstName} ${user.lastName} Developments' : 'Developer Account');
    final cacNumber = dev?['cacNumber'] ?? 'Not registered';
    final contactPerson = dev?['contactPerson'] ?? user?.fullName ?? 'Lead Director';
    final officeAddress = dev?['officeAddress'] ?? 'Corporate Head Office';
    final phone = user?.phone ?? dev?['phone'] ?? 'Not provided';
    final website = dev?['website'] ?? 'https://hometrustng.com';
    final about = dev?['about'] ?? '';
    final logoUrl = dev?['logoUrl'] ?? user?.avatarUrl;
    final isVerified = dev?['isVerified'] ?? user?.isVerified ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Corporate Profile & Settings', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 18)),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchProfileStats,
        color: const Color(0xFF059669),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 1. CORPORATE HEADER CARD
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      InkWell(
                        onTap: _handleDirectLogoUpload,
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                              ),
                              child: _isUploadingLogo
                                  ? Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0F172A),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Center(
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(color: Color(0xFF059669), strokeWidth: 2),
                                        ),
                                      ),
                                    )
                                  : ImageHelper.buildAvatar(
                                      imageUrl: logoUrl,
                                      previewBytes: _localLogoBytes,
                                      size: 60,
                                      fallbackName: companyName,
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF059669),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              companyName,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'CAC RC: $cacNumber',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isVerified
                                    ? const Color(0xFF059669).withValues(alpha: 0.1)
                                    : const Color(0xFFEF4444).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isVerified ? Icons.verified_rounded : Icons.warning_amber_rounded,
                                    size: 12,
                                    color: isVerified ? const Color(0xFF059669) : const Color(0xFFDC2626),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isVerified ? 'VERIFIED DEVELOPER' : 'KYB PENDING',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: isVerified ? const Color(0xFF059669) : const Color(0xFFDC2626),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24, color: Color(0xFFF1F5F9)),
                  _buildInfoRow('Contact Person', contactPerson),
                  const SizedBox(height: 8),
                  _buildInfoRow('Official Email', user?.email ?? 'developer@company.ng'),
                  const SizedBox(height: 8),
                  _buildInfoRow('Corporate Phone', phone),
                  const SizedBox(height: 8),
                  _buildInfoRow('Head Office', officeAddress),
                  if (website.isNotEmpty && website != 'https://hometrustng.com') ...[
                    const SizedBox(height: 8),
                    _buildInfoRow('Website', website),
                  ],
                  if (about.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF059669)),
                              SizedBox(width: 6),
                              Text('Corporate Bio & Mission', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(about, style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569), height: 1.45)),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showEditProfileModal(context, dev, phone),
                      icon: const Icon(Icons.edit_note_rounded, size: 18),
                      label: const Text('Edit Corporate Profile & Address', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 2. DEVELOPER SUPPORT & ESCALATIONS TICKET SYSTEM
            const Text('Priority Developer Support & Helpdesk', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _buildMenuTile(
                    icon: Icons.confirmation_number_outlined,
                    color: const Color(0xFF059669),
                    title: 'Developer Support Tickets',
                    subtitle: 'Open a ticket, report milestone issues & chat with admin',
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportTicketsScreen()));
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 3. ACCOUNT SECURITY & CORPORATE COMPLIANCE MENU
            const Text('Security, Governance & Facts', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _buildMenuTile(
                    icon: Icons.shield_outlined,
                    color: const Color(0xFF059669),
                    title: 'Payment PIN & Biometrics 🔒',
                    subtitle: authProvider.hasTransactionPin ? '6-digit PIN & Biometrics active' : 'Set up 6-digit payment PIN to secure disbursements',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PaymentSecurityScreen()),
                      ).then((_) => authProvider.refreshUser());
                    },
                  ),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  _buildMenuTile(
                    icon: Icons.lock_outline_rounded,
                    color: const Color(0xFF475569),
                    title: 'Change Password',
                    subtitle: 'Update your corporate account login credentials',
                    onTap: () => _showChangePasswordModal(context),
                  ),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  _buildMenuTile(
                    icon: Icons.verified_user_outlined,
                    color: const Color(0xFF059669),
                    title: 'Corporate KYB & Director Verification',
                    subtitle: isVerified ? 'Verified Active Corporate Account' : 'Upload CAC & Director Documents',
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const KycScreen()));
                    },
                  ),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  _buildMenuTile(
                    icon: Icons.help_outline_rounded,
                    color: const Color(0xFF0284C7),
                    title: 'Developer Facts & Operating FAQs',
                    subtitle: 'Escrow release schedules, milestone audits & payouts',
                    onTap: () => _showFactsFaqModal(context),
                  ),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  _buildMenuTile(
                    icon: Icons.privacy_tip_outlined,
                    color: const Color(0xFFD97706),
                    title: 'Privacy Policy & NDPR Terms',
                    subtitle: 'Data governance and anti-forgery vault security',
                    onTap: () => _showPrivacyPolicyModal(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 5. LOGOUT BUTTON
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await authProvider.logout();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                },
                icon: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 18),
                label: const Text('Log Out of Developer Account', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w800)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFCA5A5)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
      trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF94A3B8)),
      onTap: onTap,
    );
  }
}

