import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../core/network/api_client.dart';
import '../core/utils/image_helper.dart';
import '../core/constants/colors.dart';
import '../providers/auth_provider.dart';
import 'package:flutter/services.dart';
import 'chat_screen.dart';
import 'login_screen.dart';
import 'site_reels_screen.dart';
import 'create_reel_screen.dart';
import '../widgets/in_app_call_modal.dart';

class DeveloperPublicProfileScreen extends StatefulWidget {
  final Map<String, dynamic> developer;

  const DeveloperPublicProfileScreen({super.key, required this.developer});

  @override
  State<DeveloperPublicProfileScreen> createState() => _DeveloperPublicProfileScreenState();
}

class _DeveloperPublicProfileScreenState extends State<DeveloperPublicProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  Map<String, dynamic> _fullProfile = {};
  List<dynamic> _posts = [];
  List<dynamic> _projects = [];
  List<dynamic> _testimonials = [];
  List<dynamic> _certifications = [];

  bool _isLoading = true;
  bool _isFollowing = false;
  int _followersCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    final devId = widget.developer['id'] ?? '';
    try {
      final results = await Future.wait([
        ApiClient.get('/developers/$devId').catchError((_) => <String, dynamic>{}),
        ApiClient.get('/reels/feed?developerId=$devId&includeExpired=true').catchError((_) => []),
        ApiClient.get('/projects?developerId=$devId').catchError((_) => []),
      ]);

      final profile = results[0] is Map ? results[0] as Map<String, dynamic> : <String, dynamic>{};
      final postsRaw = results[1] is List
          ? results[1] as List
          : (results[1] is Map && results[1]['data'] is List ? results[1]['data'] as List : <dynamic>[]);
      final projRaw = results[2] is List
          ? results[2] as List
          : (results[2] is Map && results[2]['data'] is List ? results[2]['data'] as List : <dynamic>[]);

      final certs = <dynamic>[];
      if (profile['certifications'] is List) {
        certs.addAll(profile['certifications'] as List);
      } else {
        if (profile['cacNumber'] != null) {
          certs.add({'label': 'CAC Registration', 'value': 'RC ${profile['cacNumber']}'});
        }
        if (profile['isVerified'] == true) {
          certs.add({'label': 'Hometrust Verified', 'value': 'Platform KYC Passed ✓'});
        }
      }

      final testimonialsRaw = profile['reviews'] is List
          ? profile['reviews'] as List
          : profile['testimonials'] is List
              ? profile['testimonials'] as List
              : <dynamic>[];

      if (mounted) {
        setState(() {
          _fullProfile = profile;
          _posts = postsRaw;
          _projects = projRaw;
          _certifications = certs;
          _testimonials = testimonialsRaw;
          _isFollowing = profile['isFollowing'] == true;
          _followersCount = (profile['followersCount'] is int) ? profile['followersCount'] as int : 0;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleFollow() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isAuthenticated) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }

    final devId = widget.developer['id'] ?? '';
    if (devId.isEmpty) return;

    final newStatus = !_isFollowing;
    final companyName = _fullProfile['companyName'] ?? widget.developer['companyName'] ?? 'Developer';

    // Optimistic UI state update
    setState(() {
      _isFollowing = newStatus;
      _followersCount = (_followersCount + (newStatus ? 1 : -1)).clamp(0, 9999999);
    });

    try {
      final res = await ApiClient.post('/developers/$devId/follow', {});
      if (res is Map && res['isFollowing'] != null && mounted) {
        setState(() {
          _isFollowing = res['isFollowing'] == true;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newStatus ? '✅ You are now following $companyName' : 'Unfollowed $companyName'),
            duration: const Duration(seconds: 2),
            backgroundColor: const Color(0xFF059669),
          ),
        );
      }
    } catch (e) {
      // Revert optimistic state on error
      if (mounted) {
        setState(() {
          _isFollowing = !newStatus;
          _followersCount = (_followersCount + (!newStatus ? 1 : -1)).clamp(0, 9999999);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update follow status: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  void _showEditBioModal(BuildContext context, Map<String, dynamic> dev) {
    final bioCtrl = TextEditingController(text: dev['bio'] ?? dev['about'] ?? dev['description'] ?? '');
    final websiteCtrl = TextEditingController(text: dev['website'] ?? '');
    final addressCtrl = TextEditingController(text: dev['officeAddress'] ?? dev['businessAddress'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
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
                  const Text('Edit Bio & Public Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                  IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const Text('This information appears on your Homegram public profile for buyers to see.', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
              const SizedBox(height: 16),
              const Text('Bio / Company Introduction', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
              const SizedBox(height: 5),
              TextField(
                controller: bioCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Tell buyers about your projects, experience, and development mission...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Office Address', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
              const SizedBox(height: 5),
              TextField(
                controller: addressCtrl,
                decoration: InputDecoration(
                  hintText: 'e.g. 14 Admiralty Way, Lekki Phase 1, Lagos',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Website URL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
              const SizedBox(height: 5),
              TextField(
                controller: websiteCtrl,
                decoration: InputDecoration(
                  hintText: 'https://yourcompany.ng',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      await ApiClient.put('/users/profile', {
                        'about': bioCtrl.text.trim(),
                        'bio': bioCtrl.text.trim(),
                        'officeAddress': addressCtrl.text.trim(),
                        'businessAddress': addressCtrl.text.trim(),
                        'website': websiteCtrl.text.trim(),
                      });
                      if (context.mounted) {
                        Navigator.pop(ctx);
                        _loadProfile();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✨ Bio & profile details updated!'),
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
                  child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPostActionsSheet(dynamic post) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;
    final dev = _fullProfile.isNotEmpty ? _fullProfile : widget.developer;
    final devId = dev['id'] ?? widget.developer['id'];
    final devUserId = dev['userId'] ?? widget.developer['userId'];
    final isOwner = user != null && (user.id == devId || user.id == devUserId || (user.developerCompanyName != null && user.developerCompanyName == dev['companyName']));

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              (post['tagTitle'] ?? 'Upload Details').toString(),
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.play_circle_outline_rounded, color: Color(0xFF059669)),
              title: const Text('View Fullscreen', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => SiteReelsScreen(initialPostId: post['id'])));
              },
            ),
            if (isOwner) ...[
              ListTile(
                leading: const Icon(Icons.edit_note_rounded, color: Color(0xFF0284C7)),
                title: const Text('Edit Details & Price Tag', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                subtitle: const Text('Change caption, title, or tagged price', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                onTap: () {
                  Navigator.pop(ctx);
                  _showEditPostModal(post);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626)),
                title: const Text('Delete Upload', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFFDC2626))),
                subtitle: const Text('Permanently remove this photo/video from your page', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDeletePost(post);
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.share_outlined, color: Color(0xFF475569)),
              title: const Text('Share Link', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              onTap: () {
                Navigator.pop(ctx);
                Clipboard.setData(ClipboardData(text: 'https://hometrustng.com/reels/${post['id']}'));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('🔗 Link copied to clipboard!'), backgroundColor: Color(0xFF059669)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditPostModal(dynamic post) {
    final captionCtrl = TextEditingController(text: post['caption'] ?? '');
    final titleCtrl = TextEditingController(text: post['tagTitle'] ?? '');
    final priceCtrl = TextEditingController(text: post['tagPrice'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
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
                  const Text('Edit Upload Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                  IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const Text('Update the description, project unit label, or price for this upload.', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
              const SizedBox(height: 16),
              const Text('Title / Tag (e.g. Unit A Structural Slab)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
              const SizedBox(height: 5),
              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(
                  hintText: 'e.g. 3-Bedroom Penthouse Tour',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Tagged Price (Optional)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
              const SizedBox(height: 5),
              TextField(
                controller: priceCtrl,
                decoration: InputDecoration(
                  hintText: 'e.g. ₦85,000,000',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Caption / Description', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
              const SizedBox(height: 5),
              TextField(
                controller: captionCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Describe this site milestone or property feature...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      await ApiClient.patch('/reels/${post['id']}', {
                        'tagTitle': titleCtrl.text.trim(),
                        'tagPrice': priceCtrl.text.trim(),
                        'caption': captionCtrl.text.trim(),
                      });
                      if (context.mounted) {
                        Navigator.pop(ctx);
                        _loadProfile();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✅ Upload details updated!'),
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
                  child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeletePost(dynamic post) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: Color(0xFFDC2626)),
            SizedBox(width: 8),
            Text('Delete Upload?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete "${post['tagTitle'] ?? 'this upload'}"? It will be removed from your Homegram page and the discovery feed.',
          style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ApiClient.delete('/reels/${post['id']}');
                if (mounted) {
                  _loadProfile();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🗑️ Upload deleted successfully'),
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
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final dev = _fullProfile.isNotEmpty ? _fullProfile : widget.developer;
    final companyName = dev['companyName'] ?? 'Developer';
    final logoUrl = (dev['logoUrl'] ?? dev['avatarUrl'] ?? '').toString();
    final bio = (dev['bio'] ?? dev['description'] ?? 'Verified property developer on Hometrust.').toString();
    final address = (dev['officeAddress'] ?? '').toString();
    final cac = (dev['cacNumber'] ?? '').toString();
    final verified = dev['isVerified'] == true;

    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;
    final devId = dev['id'] ?? widget.developer['id'];
    final devUserId = dev['userId'] ?? widget.developer['userId'];
    final isOwner = user != null && (user.id == devId || user.id == devUserId || (user.developerCompanyName != null && user.developerCompanyName == companyName));

    return Scaffold(
      backgroundColor: Colors.white,
      body: NestedScrollView(
        headerSliverBuilder: (ctx, _) => [
          SliverAppBar(
            backgroundColor: Colors.white,
            pinned: true,
            expandedHeight: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF0F172A)),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(companyName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A))),
            actions: [
              if (verified)
                const Padding(
                  padding: EdgeInsets.only(right: 14),
                  child: Icon(Icons.verified_rounded, color: Color(0xFF059669), size: 22),
                ),
            ],
          ),

          SliverToBoxAdapter(
            child: _isLoading
                ? const SizedBox(height: 200, child: Center(child: CircularProgressIndicator(color: AppColors.primary)))
                : Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar + Stats
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 84,
                              height: 84,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF059669), Color(0xFF0EA5E9)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(3),
                                child: ClipOval(
                                  child: Container(
                                    color: Colors.white,
                                    child: ClipOval(
                                      child: logoUrl.isNotEmpty
                                          ? Image.network(
                                              ImageHelper.resolveUrl(logoUrl) ?? logoUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => _fallback(companyName),
                                            )
                                          : _fallback(companyName),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _stat(_posts.length.toString(), 'Posts'),
                                  _stat(_followersCount.toString(), 'Followers'),
                                  _stat(_projects.length.toString(), 'Projects'),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Name + CAC + Address + Bio
                        Row(children: [
                          Text(companyName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF0F172A))),
                          if (verified) ...[const SizedBox(width: 6), const Icon(Icons.verified_rounded, size: 16, color: Color(0xFF059669))],
                        ]),
                        if (cac.isNotEmpty)
                          Text('CAC: RC $cac', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                        if (address.isNotEmpty)
                          Row(children: [
                            const Icon(Icons.place_rounded, size: 12, color: Color(0xFF94A3B8)),
                            const SizedBox(width: 3),
                            Expanded(child: Text(address, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)), maxLines: 1, overflow: TextOverflow.ellipsis)),
                          ]),
                        if (bio.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(bio, style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569), height: 1.4), maxLines: 3, overflow: TextOverflow.ellipsis),
                        ],
                        const SizedBox(height: 12),

                        // Action buttons
                        Builder(
                          builder: (context) {
                            final auth = Provider.of<AuthProvider>(context);
                            final user = auth.user;
                            final devId = dev['id'] ?? widget.developer['id'];
                            final devUserId = dev['userId'] ?? widget.developer['userId'];
                            final isOwner = user != null && (user.id == devId || user.id == devUserId || (user.developerCompanyName != null && user.developerCompanyName == companyName));

                            if (isOwner) {
                              return Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => _showEditBioModal(context, dev),
                                      child: Container(
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          border: Border.all(color: const Color(0xFFE2E8F0)),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Center(
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.edit_note_rounded, size: 16, color: Color(0xFF0F172A)),
                                              SizedBox(width: 4),
                                              Text('Edit Bio & Info', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF0F172A))),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (_) => const CreateReelScreen()),
                                        ).then((_) => _loadProfile());
                                      },
                                      child: Container(
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF059669),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Center(
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.video_call_rounded, size: 16, color: Colors.white),
                                              SizedBox(width: 4),
                                              Text('Upload Reel', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Colors.white)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () {
                                      Clipboard.setData(ClipboardData(text: 'https://hometrustng.com/developers/${dev['id']}'));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('🔗 Profile link copied to clipboard! Share with prospective buyers.'),
                                          backgroundColor: Color(0xFF059669),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: const Color(0xFFE2E8F0)),
                                      ),
                                      child: const Center(child: Icon(Icons.share_rounded, size: 16, color: Color(0xFF0F172A))),
                                    ),
                                  ),
                                ],
                              );
                            }

                            return Row(children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: _toggleFollow,
                                  child: Container(
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: _isFollowing ? Colors.white : const Color(0xFF059669),
                                      border: Border.all(color: _isFollowing ? const Color(0xFFE2E8F0) : const Color(0xFF059669)),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Text(
                                        _isFollowing ? 'Following' : 'Follow',
                                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: _isFollowing ? const Color(0xFF0F172A) : Colors.white),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    final auth = Provider.of<AuthProvider>(context, listen: false);
                                    if (!auth.isAuthenticated) { Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())); return; }
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(developerId: dev['id'], recipientId: dev['userId'], recipientName: companyName, recipientRole: 'Verified Developer')));
                                  },
                                  child: Container(
                                    height: 36,
                                    decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(8)),
                                    child: const Center(child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.chat_bubble_outline_rounded, size: 14, color: Color(0xFF0F172A)), SizedBox(width: 4), Text('Chat', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A)))])),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  final auth = Provider.of<AuthProvider>(context, listen: false);
                                  if (!auth.isAuthenticated) { Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())); return; }
                                  InAppCallModal.show(context, entityName: companyName, entityRole: 'Verified Developer', developerId: dev['id'], recipientId: dev['userId']);
                                },
                                child: Container(width: 36, height: 36, decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(8)), child: const Center(child: Icon(Icons.phone_rounded, size: 18, color: Colors.white))),
                              ),
                            ]);
                          },
                        ),
                        const SizedBox(height: 14),
                      ],
                    ),
                  ),
          ),

          // Stories (recent reels as story circles)
          if (!_isLoading && _posts.isNotEmpty)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 92,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: min(_posts.length, 8),
                  itemBuilder: (ctx, i) {
                    final post = _posts[i];
                    final thumb = (post['thumbnailUrl'] ?? post['mediaUrl'] ?? '').toString();
                    return GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SiteReelsScreen(initialPostId: post['id']))),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Column(children: [
                          Container(
                            width: 58, height: 58,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(colors: [Color(0xFF059669), Color(0xFF0EA5E9)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(2),
                              child: ClipOval(
                                child: thumb.isNotEmpty
                                    ? Image.network(ImageHelper.resolveUrl(thumb) ?? thumb, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: const Color(0xFF0F172A), child: const Icon(Icons.play_circle_outline, color: Colors.white, size: 20)))
                                    : Container(color: const Color(0xFF0F172A), child: const Icon(Icons.play_circle_outline, color: Colors.white, size: 20)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            (post['tagTitle'] ?? 'Reel').toString().split(' ').first,
                            style: const TextStyle(fontSize: 10, color: Color(0xFF475569)),
                            maxLines: 1,
                          ),
                        ]),
                      ),
                    );
                  },
                ),
              ),
            ),

          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverTabBarDelegate(TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF059669),
              unselectedLabelColor: const Color(0xFF94A3B8),
              indicatorColor: const Color(0xFF059669),
              indicatorWeight: 2.5,
              labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
              tabs: const [
                Tab(icon: Icon(Icons.grid_view_rounded, size: 22)),
                Tab(icon: Icon(Icons.play_circle_rounded, size: 22)),
                Tab(icon: Icon(Icons.apartment_rounded, size: 22)),
                Tab(icon: Icon(Icons.star_rounded, size: 22)),
              ],
            )),
          ),
        ],

        body: TabBarView(
          controller: _tabController,
          children: [
            _PostsGridTab(
              posts: _posts,
              certifications: _certifications,
              isOwner: isOwner,
              onPostTap: _showPostActionsSheet,
            ),
            _VideosTab(
              posts: _posts.where((p) => p['mediaType'] == 'VIDEO').toList(),
              isOwner: isOwner,
              onPostTap: _showPostActionsSheet,
            ),
            _ProjectsTab(projects: _projects),
            _TestimonialsTab(testimonials: _testimonials),
          ],
        ),
      ),
    );
  }

  Widget _fallback(String name) => Container(
        color: const Color(0xFF0F172A),
        child: Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'D', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 32))),
      );

  Widget _stat(String value, String label) => Column(mainAxisSize: MainAxisSize.min, children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF0F172A))),
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
      ]);
}

// ── Posts Grid ────────────────────────────────────────────────────────────────
class _PostsGridTab extends StatelessWidget {
  final List<dynamic> posts;
  final List<dynamic> certifications;
  final bool isOwner;
  final Function(dynamic)? onPostTap;

  const _PostsGridTab({
    required this.posts,
    required this.certifications,
    this.isOwner = false,
    this.onPostTap,
  });

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.grid_view_rounded, size: 44, color: Color(0xFFCBD5E1)),
        SizedBox(height: 12),
        Text('No posts yet', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
      ]));
    }

    return CustomScrollView(slivers: [
      if (certifications.isNotEmpty)
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFA7F3D0))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [
                Icon(Icons.workspace_premium_rounded, color: Color(0xFF059669), size: 16),
                SizedBox(width: 6),
                Text('CERTIFICATIONS & CREDENTIALS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF065F46), letterSpacing: 0.5)),
              ]),
              const SizedBox(height: 8),
              ...certifications.map((c) {
                final label = c is Map ? (c['label'] ?? '') : c.toString();
                final value = c is Map ? (c['value'] ?? '') : '';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(children: [
                    const Icon(Icons.check_circle_rounded, size: 13, color: Color(0xFF059669)),
                    const SizedBox(width: 6),
                    Expanded(child: Text('$label${value.isNotEmpty ? ' — $value' : ''}', style: const TextStyle(fontSize: 12, color: Color(0xFF064E3B), fontWeight: FontWeight.w600))),
                  ]),
                );
              }),
            ]),
          ),
        ),

      SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (ctx, i) {
            final post = posts[i];
            final thumb = (post['thumbnailUrl'] ?? post['mediaUrl'] ?? '').toString();
            final isVideo = post['mediaType'] == 'VIDEO';
            return GestureDetector(
              onTap: () {
                if (isOwner && onPostTap != null) {
                  onPostTap!(post);
                } else {
                  Navigator.push(ctx, MaterialPageRoute(builder: (_) => SiteReelsScreen(initialPostId: post['id'])));
                }
              },
              onLongPress: () => onPostTap?.call(post),
              child: Stack(fit: StackFit.expand, children: [
                thumb.isNotEmpty
                    ? Image.network(ImageHelper.resolveUrl(thumb) ?? thumb, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: const Color(0xFF1E293B)))
                    : Container(color: const Color(0xFF1E293B), child: const Center(child: Icon(Icons.image_rounded, color: Colors.white24, size: 28))),
                if (isVideo) const Positioned(top: 6, right: 6, child: Icon(Icons.play_circle_filled_rounded, color: Colors.white, size: 20)),
                if (isOwner)
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(Icons.more_horiz_rounded, color: Colors.white, size: 14),
                    ),
                  ),
              ]),
            );
          },
          childCount: posts.length,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 2, crossAxisSpacing: 2),
      ),
    ]);
  }
}

// ── Videos Tab ────────────────────────────────────────────────────────────────
class _VideosTab extends StatelessWidget {
  final List<dynamic> posts;
  final bool isOwner;
  final Function(dynamic)? onPostTap;

  const _VideosTab({
    required this.posts,
    this.isOwner = false,
    this.onPostTap,
  });

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.videocam_off_rounded, size: 44, color: Color(0xFFCBD5E1)),
        SizedBox(height: 12),
        Text('No videos posted yet', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
      ]));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: posts.length,
      itemBuilder: (ctx, i) => _VideoCard(
        post: posts[i],
        isOwner: isOwner,
        onPostTap: onPostTap,
      ),
    );
  }
}

class _VideoCard extends StatefulWidget {
  final Map<String, dynamic> post;
  final bool isOwner;
  final Function(dynamic)? onPostTap;

  const _VideoCard({
    required this.post,
    this.isOwner = false,
    this.onPostTap,
  });

  @override
  State<_VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<_VideoCard> {
  VideoPlayerController? _ctrl;
  bool _initialized = false;

  @override
  void dispose() { _ctrl?.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final thumb = (post['thumbnailUrl'] ?? post['mediaUrl'] ?? '').toString();
    final title = (post['tagTitle'] ?? 'Site Progress Video').toString();
    final caption = (post['caption'] ?? '').toString();
    final price = (post['tagPrice'] ?? '').toString();
    final createdAt = (post['createdAt'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8F0)), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SiteReelsScreen(initialPostId: post['id']))),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(fit: StackFit.expand, children: [
                _initialized && _ctrl != null
                    ? VideoPlayer(_ctrl!)
                    : thumb.isNotEmpty
                        ? Image.network(ImageHelper.resolveUrl(thumb) ?? thumb, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: const Color(0xFF0F172A)))
                        : Container(color: const Color(0xFF0F172A)),
                if (!_initialized)
                  Center(child: Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), shape: BoxShape.circle),
                    child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 32),
                  )),
              ]),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(
              children: [
                Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A)))),
                if (widget.isOwner)
                  IconButton(
                    icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF64748B), size: 20),
                    onPressed: () => widget.onPostTap?.call(post),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
            if (caption.isNotEmpty) ...[const SizedBox(height: 4), Text(caption, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis)],
            if (price.isNotEmpty) ...[const SizedBox(height: 6), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(6)), child: Text(price, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF059669))))],
            if (createdAt.isNotEmpty) ...[const SizedBox(height: 4), Text(_fmtDate(createdAt), style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)))],
          ]),
        ),
      ]),
    );
  }

  String _fmtDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final diff = DateTime.now().difference(dt);
      if (diff.inDays > 30) return '${dt.day}/${dt.month}/${dt.year}';
      if (diff.inDays > 0) return '${diff.inDays}d ago';
      if (diff.inHours > 0) return '${diff.inHours}h ago';
      return '${diff.inMinutes}m ago';
    } catch (_) { return ''; }
  }
}

// ── Projects Tab ──────────────────────────────────────────────────────────────
class _ProjectsTab extends StatelessWidget {
  final List<dynamic> projects;
  const _ProjectsTab({required this.projects});

  @override
  Widget build(BuildContext context) {
    if (projects.isEmpty) {
      return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.apartment_rounded, size: 44, color: Color(0xFFCBD5E1)),
        SizedBox(height: 12),
        Text('No active projects found', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
      ]));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: projects.length,
      itemBuilder: (ctx, i) {
        final proj = projects[i] is Map ? projects[i] as Map<String, dynamic> : <String, dynamic>{};
        final name = (proj['name'] ?? proj['title'] ?? 'Project').toString();
        final location = (proj['location'] ?? proj['address'] ?? '').toString();
        final type = (proj['type'] ?? proj['projectType'] ?? 'OFFPLAN').toString();
        final status = (proj['status'] ?? 'ACTIVE').toString();
        final totalUnits = proj['totalUnits'] ?? proj['units'] ?? '';
        final price = proj['pricePerUnit'] ?? proj['price'] ?? '';
        final imageUrl = (proj['imageUrl'] ?? '').toString();

        Color statusColor = const Color(0xFF059669);
        if (status == 'COMPLETED') statusColor = const Color(0xFF3B82F6);
        if (status == 'PAUSED') statusColor = const Color(0xFFF59E0B);

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8F0)), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              child: imageUrl.isNotEmpty
                  ? Image.network(ImageHelper.resolveUrl(imageUrl) ?? imageUrl, height: 130, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(height: 60, color: const Color(0xFF0F172A)))
                  : Container(height: 60, color: const Color(0xFF0F172A), child: const Center(child: Icon(Icons.apartment_rounded, color: Colors.white38, size: 32))),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF0F172A)))),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)), child: Text(status, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: statusColor))),
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(5)), child: Text(type.replaceAll('_', ' '), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF3B82F6)))),
                  if (location.isNotEmpty) ...[const SizedBox(width: 8), const Icon(Icons.place_rounded, size: 11, color: Color(0xFF94A3B8)), const SizedBox(width: 2), Expanded(child: Text(location, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)), maxLines: 1, overflow: TextOverflow.ellipsis))],
                ]),
                if (price.toString().isNotEmpty) ...[const SizedBox(height: 6), Text('₦${price.toString()}${totalUnits.toString().isNotEmpty ? ' · ${totalUnits} units' : ''}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF059669)))],
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFA7F3D0))),
                  child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.shield_rounded, size: 12, color: Color(0xFF059669)), SizedBox(width: 4), Text('Milestone Escrow Protected', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFF059669)))]),
                ),
              ]),
            ),
          ]),
        );
      },
    );
  }
}

// ── Testimonials Tab ──────────────────────────────────────────────────────────
class _TestimonialsTab extends StatelessWidget {
  final List<dynamic> testimonials;
  const _TestimonialsTab({required this.testimonials});

  @override
  Widget build(BuildContext context) {
    if (testimonials.isEmpty) {
      return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.star_border_rounded, size: 44, color: Color(0xFFCBD5E1)),
        SizedBox(height: 12),
        Text('No buyer reviews yet', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
        SizedBox(height: 6),
        Padding(padding: EdgeInsets.symmetric(horizontal: 32), child: Text('Reviews appear automatically after verified purchases complete', style: TextStyle(fontSize: 11, color: Color(0xFFCBD5E1)), textAlign: TextAlign.center)),
      ]));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: testimonials.length,
      itemBuilder: (ctx, i) {
        final t = testimonials[i] is Map ? testimonials[i] as Map<String, dynamic> : <String, dynamic>{};
        final reviewerName = (t['buyerName'] ?? t['reviewer'] ?? t['userName'] ?? 'Verified Buyer').toString();
        final rating = (t['rating'] ?? 5) as num;
        final comment = (t['comment'] ?? t['review'] ?? t['text'] ?? '').toString();
        final date = (t['createdAt'] ?? '').toString();

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              CircleAvatar(radius: 18, backgroundColor: const Color(0xFF059669), child: Text(reviewerName.isNotEmpty ? reviewerName[0].toUpperCase() : 'B', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900))),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(reviewerName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A))),
                Row(children: List.generate(5, (s) => Icon(s < rating.round() ? Icons.star_rounded : Icons.star_border_rounded, size: 14, color: const Color(0xFFF59E0B)))),
              ])),
              if (date.isNotEmpty) Text(_fmtDate(date), style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
            ]),
            if (comment.isNotEmpty) ...[const SizedBox(height: 10), Text(comment, style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569), height: 1.4))],
            const SizedBox(height: 8),
            const Row(children: [Icon(Icons.verified_rounded, size: 12, color: Color(0xFF059669)), SizedBox(width: 4), Text('Verified Purchase', style: TextStyle(fontSize: 10, color: Color(0xFF059669), fontWeight: FontWeight.w700))]),
          ]),
        );
      },
    );
  }

  String _fmtDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final diff = DateTime.now().difference(dt);
      if (diff.inDays > 30) return '${dt.day}/${dt.month}/${dt.year}';
      if (diff.inDays > 0) return '${diff.inDays}d ago';
      return '${diff.inHours}h ago';
    } catch (_) { return ''; }
  }
}

// ── Sliver Tab Bar Delegate ───────────────────────────────────────────────────
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _SliverTabBarDelegate(this.tabBar);

  @override
  Widget build(BuildContext ctx, double shrinkOffset, bool overlapsContent) => Container(
        color: Colors.white,
        child: Column(children: [const Divider(height: 1, color: Color(0xFFE2E8F0)), tabBar, const Divider(height: 1, color: Color(0xFFE2E8F0))]),
      );

  @override
  double get maxExtent => tabBar.preferredSize.height + 2;
  @override
  double get minExtent => tabBar.preferredSize.height + 2;
  @override
  bool shouldRebuild(_SliverTabBarDelegate _) => false;
}
