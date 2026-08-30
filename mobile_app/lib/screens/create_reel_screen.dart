import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/colors.dart';
import '../core/network/api_client.dart';
import '../providers/auth_provider.dart';

class CreateReelScreen extends StatefulWidget {
  const CreateReelScreen({super.key});

  @override
  State<CreateReelScreen> createState() => _CreateReelScreenState();
}

class _CreateReelScreenState extends State<CreateReelScreen> {
  final _captionCtrl = TextEditingController();
  final _tagTitleCtrl = TextEditingController();
  final _tagPriceCtrl = TextEditingController();

  PlatformFile? _pickedFile;
  Uint8List? _previewBytes;
  String _mediaType = 'VIDEO'; // 'VIDEO' | 'IMAGE'
  bool _isUploading = false;
  String? _uploadStatusText;

  List<dynamic> _projects = [];
  String? _selectedProjectId;
  bool _loadingProjects = true;

  @override
  void initState() {
    super.initState();
    _fetchDeveloperProjects();
  }

  @override
  void dispose() {
    _captionCtrl.dispose();
    _tagTitleCtrl.dispose();
    _tagPriceCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchDeveloperProjects() async {
    try {
      final res = await ApiClient.get('/developers/my-projects');
      if (mounted) {
        final List<dynamic> list = res is List ? res : (res?['data'] is List ? res['data'] : []);
        setState(() {
          _projects = list;
          _loadingProjects = false;
          if (list.isNotEmpty) {
            _selectedProjectId = list.first['id'];
            _tagTitleCtrl.text = list.first['name'] ?? '';
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingProjects = false);
    }
  }

  Future<void> _pickMedia() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp4', 'mov', 'jpg', 'jpeg', 'png', 'webp'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty && result.files.first.bytes != null) {
        final file = result.files.first;
        final ext = (file.extension ?? '').toLowerCase();
        final isImg = ['jpg', 'jpeg', 'png', 'webp'].contains(ext);

        setState(() {
          _pickedFile = file;
          _mediaType = isImg ? 'IMAGE' : 'VIDEO';
          _previewBytes = file.bytes;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick file: $e'), backgroundColor: const Color(0xFFDC2626)),
      );
    }
  }

  Future<void> _publishReel() async {
    if (_pickedFile == null || _previewBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a video or image to publish'), backgroundColor: Color(0xFFDC2626)),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadStatusText = 'Uploading media to Hometrust secure cloud...';
    });

    try {
      final uploadRes = await ApiClient.uploadFile(
        '/storage/upload',
        fileBytes: _previewBytes!,
        fileName: _pickedFile!.name,
        fieldName: 'file',
      );

      final String? mediaUrl = uploadRes['fileUrl'];
      if (mediaUrl == null || mediaUrl.isEmpty) {
        throw Exception('Server failed to return media file URL');
      }

      setState(() => _uploadStatusText = 'Publishing site story to followers...');

      await ApiClient.post('/reels', {
        'mediaUrl': mediaUrl,
        'mediaType': _mediaType,
        'caption': _captionCtrl.text.trim(),
        'projectId': _selectedProjectId,
        'tagTitle': _tagTitleCtrl.text.trim(),
        'tagPrice': _tagPriceCtrl.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Site Story & Reel published successfully! Your followers have been notified.'),
            backgroundColor: Color(0xFF059669),
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to publish reel: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Post Site Story / Reel',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Color(0xFF0F172A)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── MEDIA PICKER BOX ──
            InkWell(
              onTap: _isUploading ? null : _pickMedia,
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: double.infinity,
                height: 220,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFF334155), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: _previewBytes != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: _mediaType == 'IMAGE'
                                ? Image.memory(_previewBytes!, fit: BoxFit.cover)
                                : Container(
                                    color: const Color(0xFF0F172A),
                                    child: const Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.video_library_rounded, color: Color(0xFF34D399), size: 48),
                                          SizedBox(height: 8),
                                          Text('Video Selected (Ready to Upload)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                                        ],
                                      ),
                                    ),
                                  ),
                          ),
                          Positioned(
                            top: 10,
                            right: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Icon(_mediaType == 'VIDEO' ? Icons.videocam_rounded : Icons.photo_camera_rounded, color: Colors.white, size: 14),
                                  const SizedBox(width: 4),
                                  Text('Tap to Change', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF334155)),
                            ),
                            child: const Icon(Icons.add_photo_alternate_rounded, color: Color(0xFF34D399), size: 36),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Select Site Video or Photo',
                            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'MP4, MOV, JPG, PNG • Max 60 Seconds',
                            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),

            // ── PROJECT LINKING DROPDOWN ──
            const Text('Link to Off-Plan Project / Property', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF334155))),
            const SizedBox(height: 6),
            if (_loadingProjects)
              const LinearProgressIndicator(color: AppColors.primary)
            else if (_projects.isNotEmpty)
              DropdownButtonFormField<String>(
                value: _selectedProjectId,
                items: _projects.map((p) {
                  return DropdownMenuItem<String>(
                    value: p['id'].toString(),
                    child: Text(p['name']?.toString() ?? 'Project', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedProjectId = val;
                    final matched = _projects.firstWhere((p) => p['id'] == val, orElse: () => null);
                    if (matched != null) {
                      _tagTitleCtrl.text = matched['name'] ?? '';
                    }
                  });
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  filled: true,
                  fillColor: Colors.white,
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('No projects found. Enter tag details manually below.', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
              ),
            const SizedBox(height: 16),

            // ── TAG TITLE & PRICE HOOK ──
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tag Label / Building Name', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _tagTitleCtrl,
                        decoration: InputDecoration(
                          hintText: 'e.g. Ikoyi Smart Terraces',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Price Hook', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _tagPriceCtrl,
                        decoration: InputDecoration(
                          hintText: 'From ₦2.5M',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── CAPTION FIELD ──
            const Text('Caption & Construction Milestone Notes', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF334155))),
            const SizedBox(height: 6),
            TextField(
              controller: _captionCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'e.g. Casting the 3rd floor slab today! 🏗️ Fully verified by COREN engineers. 4 units remaining on flexible milestone escrow.',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.all(14),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 24),

            // Uploading status
            if (_isUploading) ...[
              Center(
                child: Column(
                  children: [
                    const CircularProgressIndicator(color: Color(0xFF059669)),
                    const SizedBox(height: 10),
                    Text(_uploadStatusText ?? 'Uploading...', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF059669))),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],

            // ── SUBMIT BUTTON ──
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isUploading ? null : _publishReel,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
                icon: const Icon(Icons.rocket_launch_rounded, color: Color(0xFF34D399), size: 20),
                label: const Text(
                  'Publish Site Story & Reel 🚀',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
