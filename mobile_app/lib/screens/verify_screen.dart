import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../core/constants/colors.dart';
import '../providers/verification_provider.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';

class VerifyScreen extends StatefulWidget {
  const VerifyScreen({super.key});

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _propNameCtrl = TextEditingController();
  final _propAddressCtrl = TextEditingController(text: '');
  final _cityCtrl = TextEditingController(text: 'Lekki');
  final _stateCtrl = TextEditingController(text: 'Lagos');

  String _selectedDocType = 'C_OF_O';
  String _urgency = 'STANDARD';
  bool _submitting = false;

  // File picker state
  Uint8List? _pickedFileBytes;
  String? _pickedFileName;

  final List<Map<String, String>> _docTypes = [
    {'id': 'C_OF_O', 'name': 'Certificate of Occupancy (C of O)'},
    {'id': 'DEED_OF_ASSIGNMENT', 'name': 'Deed of Assignment'},
    {'id': 'SURVEY_PLAN', 'name': 'Registered Survey Plan'},
    {'id': 'GOVERNORS_CONSENT', 'name': "Governor's Consent"},
    {'id': 'GAZETTE', 'name': 'Government Gazette / Excision'},
    {'id': 'POWER_OF_ATTORNEY', 'name': 'Irrevocable Power of Attorney'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.isAuthenticated) {
        Provider.of<VerificationProvider>(context, listen: false).fetchMyRequests();
      }
    });
  }

  @override
  void dispose() {
    _propNameCtrl.dispose();
    _propAddressCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        withData: true,
      );
      if (result != null && result.files.single.bytes != null) {
        setState(() {
          _pickedFileBytes = result.files.single.bytes;
          _pickedFileName = result.files.single.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not pick file: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final verifProvider = Provider.of<VerificationProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Document Verification Vault',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 17),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Trust Header Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.shield_outlined, color: AppColors.accentGoldLight, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'HOMETRUST LEGAL & REGISTRY CHECK',
                        style: TextStyle(color: AppColors.accentGoldLight, fontWeight: FontWeight.w800, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Verify Title & Land Documents Before Paying',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Our internal legal team coordinates cadastral registry searches, surveyor coordinate checks, and preliminary heuristic scans.',
                    style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            // New Verification Request Form
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Submit New Document for Verification',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 16),

                    // Document Type Dropdown
                    const Text('Document Type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedDocType,
                          isExpanded: true,
                          items: _docTypes.map((d) {
                            return DropdownMenuItem(
                              value: d['id'],
                              child: Text(d['name']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedDocType = val);
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),
                    const Text('Property Name / Plot ID', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _propNameCtrl,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      decoration: InputDecoration(
                        hintText: 'e.g. Plot 42, Block B, Lekki Phase 1',
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.cardBorder)),
                        isDense: true,
                      ),
                    ),

                    const SizedBox(height: 14),
                    const Text('Property Address', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _propAddressCtrl,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      decoration: InputDecoration(
                        hintText: 'e.g. Admiralty Way, Lekki',
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.cardBorder)),
                        isDense: true,
                      ),
                    ),

                    const SizedBox(height: 18),
                    // File Upload — real picker
                    const Text('Attach Title Document', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: _pickFile,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _pickedFileName != null ? AppColors.emeraldBg : AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _pickedFileName != null ? AppColors.emeraldBorder : AppColors.primary.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              _pickedFileName != null ? Icons.check_circle_rounded : Icons.upload_file_rounded,
                              color: _pickedFileName != null ? AppColors.emeraldText : AppColors.primary,
                              size: 28,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _pickedFileName ?? 'Tap to Select Document File',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _pickedFileName != null ? AppColors.emeraldText : AppColors.textPrimary,
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _pickedFileName != null ? 'Tap to change file' : 'PDF, JPG, PNG — Max 25MB — Encrypted vault',
                              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),
                    // Fee Notice
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('Standard Verification Fee:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                        Text('₦25,000', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.primary)),
                      ],
                    ),

                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : () => _handleSubmit(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: _submitting
                            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text(
                                'Submit Document for Verification',
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Previous Verification Requests
            if (verifProvider.userRequests.isNotEmpty) ...[
              const SizedBox(height: 28),
              const Text(
                'My Verification Requests',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 12),
              ...verifProvider.userRequests.map((req) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(req.verificationCode, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary, fontSize: 13)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: req.status == 'VERIFIED' ? AppColors.emeraldBg : AppColors.amberBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              req.status.replaceAll('_', ' '),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: req.status == 'VERIFIED' ? AppColors.emeraldText : AppColors.amberText,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(req.propertyName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      Text('${req.propertyAddress}, ${req.city}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      if (req.finalFindings != null) ...[
                        const SizedBox(height: 8),
                        Text('Findings: ${req.finalFindings}', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textSecondary)),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }

  void _handleSubmit(BuildContext context) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isAuthenticated) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }

    if (_formKey.currentState?.validate() != true) return;

    if (_pickedFileBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please attach a title document file before submitting.'),
          backgroundColor: AppColors.roseText,
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    final verifProvider = Provider.of<VerificationProvider>(context, listen: false);

    final req = await verifProvider.submitVerification(
      propertyName: _propNameCtrl.text.trim(),
      propertyAddress: _propAddressCtrl.text.trim(),
      state: _stateCtrl.text.trim(),
      city: _cityCtrl.text.trim(),
      documentType: _selectedDocType,
      urgency: _urgency,
      fileName: _pickedFileName ?? 'document.pdf',
      fileBytes: _pickedFileBytes,
    );

    setState(() => _submitting = false);

    if (req != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Verification Request Submitted: ${req.verificationCode}'),
          backgroundColor: AppColors.emeraldText,
        ),
      );
      _propNameCtrl.clear();
      _propAddressCtrl.clear();
      setState(() {
        _pickedFileBytes = null;
        _pickedFileName = null;
      });
    }
  }
}
