import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import '../core/network/api_client.dart';
import '../core/utils/image_helper.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'chat_screen.dart';

class SiteReelsScreen extends StatefulWidget {
  final String? initialPostId;
  final String initialTab;

  const SiteReelsScreen({
    super.key,
    this.initialPostId,
    this.initialTab = 'discover',
  });

  @override
  State<SiteReelsScreen> createState() => _SiteReelsScreenState();
}

class _SiteReelsScreenState extends State<SiteReelsScreen> {
  late PageController _pageController;
  List<dynamic> _posts = [];
  bool _isLoading = true;
  String _selectedTab = 'discover'; // 'discover' | 'following'
  int _currentIndex = 0;
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
    _pageController = PageController();
    _fetchReels();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchReels() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiClient.get('/reels/feed?tab=$_selectedTab');
      if (mounted) {
        final List<dynamic> loaded = res is List ? res : (res?['data'] is List ? res['data'] : []);
        int startIndex = 0;
        if (widget.initialPostId != null) {
          final foundIdx = loaded.indexWhere((p) => p['id'] == widget.initialPostId);
          if (foundIdx != -1) startIndex = foundIdx;
        }

        setState(() {
          _posts = loaded;
          _currentIndex = startIndex;
          _isLoading = false;
        });

        if (startIndex > 0 && _pageController.hasClients) {
          _pageController.jumpToPage(startIndex);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleLike(int index) async {
    final post = _posts[index];
    final postId = post['id'];
    final bool currentStatus = post['isLiked'] ?? false;
    final int currentCount = post['likesCount'] ?? 0;

    // Optimistic UI update
    setState(() {
      _posts[index]['isLiked'] = !currentStatus;
      _posts[index]['likesCount'] = currentStatus ? (currentCount - 1) : (currentCount + 1);
    });

    try {
      final res = await ApiClient.post('/reels/like/$postId', {});
      if (res != null && mounted) {
        setState(() {
          _posts[index]['isLiked'] = res['isLiked'] ?? !currentStatus;
          _posts[index]['likesCount'] = res['likesCount'] ?? _posts[index]['likesCount'];
        });
      }
    } catch (_) {
      // Revert on failure
      if (mounted) {
        setState(() {
          _posts[index]['isLiked'] = currentStatus;
          _posts[index]['likesCount'] = currentCount;
        });
      }
    }
  }

  Future<void> _toggleFollow(int index) async {
    final post = _posts[index];
    final devId = post['developerId'];
    final bool currentFollow = post['isFollowing'] ?? false;

    setState(() {
      for (var p in _posts) {
        if (p['developerId'] == devId) {
          p['isFollowing'] = !currentFollow;
        }
      }
    });

    try {
      final res = await ApiClient.post('/reels/developers/$devId/follow', {});
      if (res != null && mounted) {
        final newFollow = res['isFollowing'] ?? !currentFollow;
        setState(() {
          for (var p in _posts) {
            if (p['developerId'] == devId) {
              p['isFollowing'] = newFollow;
            }
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newFollow ? '✅ Followed ${post['developer']?['companyName']}' : 'Unfollowed developer'),
            duration: const Duration(seconds: 1),
            backgroundColor: const Color(0xFF059669),
          ),
        );
      }
    } catch (_) {}
  }

  void _sharePost(Map<String, dynamic> post) {
    final devName = post['developer']?['companyName'] ?? 'Verified Developer';
    final caption = post['caption'] ?? 'Check out this verified construction progress!';
    final tag = post['tagTitle'] ?? 'Hometrust Verified Property';
    final price = post['tagPrice'] ?? '';

    Share.share(
      '🏗️ *Hometrust Site Progress Update*\n'
      'By: $devName\n'
      'Project: $tag ${price.isNotEmpty ? "($price)" : ""}\n\n'
      '$caption\n\n'
      'Verified with Milestone Escrow on Hometrust: https://estateverify-app.onrender.com',
      subject: 'Hometrust Site Update: $tag',
    );
  }

  void _chatDeveloper(Map<String, dynamic> post) {
    final dev = post['developer'];
    if (dev == null) return;
    final devUserId = dev['userId'];
    if (devUserId == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          recipientId: devUserId,
          developerId: dev['id'],
          recipientName: dev['companyName'] ?? 'Developer Support',
          propertyTitle: post['tagTitle'],
          projectId: post['projectId'],
          propertyId: post['propertyId'],
        ),
      ),
    );
  }

  void _openProjectOrProperty(Map<String, dynamic> post) {
    // Show modal overview with off-plan units & developer chat
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        final dev = post['developer'] ?? {};
        final proj = post['project'] ?? {};
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      post['tagTitle'] ?? proj['name'] ?? 'Off-Plan Project',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.shield_rounded, color: Color(0xFF059669), size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'DEVELOPER: ${dev['companyName'] ?? 'Verified Developer'}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF059669)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('STARTING INITIAL DEPOSIT', style: TextStyle(fontSize: 10, color: Color(0xFF065F46), fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(post['tagPrice'] ?? 'Flexible Installments', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF064E3B))),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFF059669), borderRadius: BorderRadius.circular(8)),
                      child: const Text('MILESTONE ESCROW', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w900)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                post['caption'] ?? 'Contracted structural milestone monitoring under COREN engineering verification.',
                style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569), height: 1.4),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _chatDeveloper(post);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                  label: const Text('Chat Developer for Floorplans & Units', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showReelOptionsSheet(Map<String, dynamic> post) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;
    final dev = post['developer'] as Map<String, dynamic>? ?? {};
    final isOwner = user != null && (
      user.id == post['developerId'] ||
      user.id == dev['id'] ||
      user.id == dev['userId'] ||
      (user.developerCompanyName != null && user.developerCompanyName == dev['companyName'])
    );

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
              (post['tagTitle'] ?? 'Reel Options').toString(),
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 12),
            if (isOwner) ...[
              ListTile(
                leading: const Icon(Icons.edit_note_rounded, color: Color(0xFF0284C7)),
                title: const Text('Edit Reel Details & Price Tag', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                subtitle: const Text('Change caption, title, or tagged price', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                onTap: () {
                  Navigator.pop(ctx);
                  _showEditReelModal(post);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626)),
                title: const Text('Delete Reel', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFFDC2626))),
                subtitle: const Text('Permanently remove this video from your page and discover feed', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDeleteReel(post);
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.share_outlined, color: Color(0xFF475569)),
              title: const Text('Share Reel Link', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              onTap: () {
                Navigator.pop(ctx);
                _sharePost(post);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditReelModal(Map<String, dynamic> post) {
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
                  const Text('Edit Reel Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                  IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const Text('Update the description, project unit label, or price for this reel.', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
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
                        setState(() {
                          post['tagTitle'] = titleCtrl.text.trim();
                          post['tagPrice'] = priceCtrl.text.trim();
                          post['caption'] = captionCtrl.text.trim();
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✅ Reel updated successfully!'),
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

  void _confirmDeleteReel(Map<String, dynamic> post) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: Color(0xFFDC2626)),
            SizedBox(width: 8),
            Text('Delete Reel?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete "${post['tagTitle'] ?? 'this reel'}"? It will be removed from your page and the discover feed.',
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
                  setState(() {
                    _posts.removeWhere((p) => p['id'] == post['id']);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🗑️ Reel deleted successfully'),
                      backgroundColor: Color(0xFF059669),
                    ),
                  );
                  if (_posts.isEmpty) {
                    Navigator.pop(context);
                  }
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── REELS PAGEVIEW ──
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF059669)),
            )
          else if (_posts.isEmpty)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.movie_filter_outlined, color: Color(0xFF64748B), size: 54),
                  const SizedBox(height: 14),
                  Text(
                    _selectedTab == 'following'
                        ? 'No updates from followed developers yet.'
                        : 'No site updates posted yet.',
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedTab == 'following'
                        ? 'Switch to "Discover" or follow developers to see live builds!'
                        : 'Verified developers will post construction videos shortly.',
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                  ),
                  const SizedBox(height: 20),
                  if (_selectedTab == 'following')
                    ElevatedButton(
                      onPressed: () {
                        setState(() => _selectedTab = 'discover');
                        _fetchReels();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Browse Discover Reels'),
                    ),
                ],
              ),
            )
          else
            PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: _posts.length,
              onPageChanged: (idx) {
                setState(() => _currentIndex = idx);
                // Record view
                final id = _posts[idx]['id'];
                ApiClient.post('/reels/view/$id', {}).catchError((_) => null);
              },
              itemBuilder: (ctx, index) {
                final post = _posts[index];
                final bool isCurrent = index == _currentIndex;
                return _ReelItemView(
                  post: post,
                  isActive: isCurrent,
                  isMuted: _isMuted,
                  onToggleLike: () => _toggleLike(index),
                  onToggleFollow: () => _toggleFollow(index),
                  onShare: () => _sharePost(post),
                  onChat: () => _chatDeveloper(post),
                  onOpenProject: () => _openProjectOrProperty(post),
                  onMoreOptions: () => _showReelOptionsSheet(post),
                );
              },
            ),

          // ── TOP NAVIGATION BAR OVERLAY ──
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back Button
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                    ),
                  ),

                  // Feed Toggle Tabs (Following | Discover)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      children: [
                        _buildTabButton('Following', 'following'),
                        const SizedBox(width: 4),
                        _buildTabButton('Discover', 'discover'),
                      ],
                    ),
                  ),

                  // Mute / Unmute
                  InkWell(
                    onTap: () => setState(() => _isMuted = !_isMuted),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, String tabKey) {
    final bool isSelected = _selectedTab == tabKey;
    return InkWell(
      onTap: () {
        if (_selectedTab != tabKey) {
          setState(() => _selectedTab = tabKey);
          _fetchReels();
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF059669) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Single Reel Media & Interactive Overlay View
class _ReelItemView extends StatefulWidget {
  final Map<String, dynamic> post;
  final bool isActive;
  final bool isMuted;
  final VoidCallback onToggleLike;
  final VoidCallback onToggleFollow;
  final VoidCallback onShare;
  final VoidCallback onChat;
  final VoidCallback onOpenProject;
  final VoidCallback? onMoreOptions;

  const _ReelItemView({
    required this.post,
    required this.isActive,
    required this.isMuted,
    required this.onToggleLike,
    required this.onToggleFollow,
    required this.onShare,
    required this.onChat,
    required this.onOpenProject,
    this.onMoreOptions,
  });

  @override
  State<_ReelItemView> createState() => _ReelItemViewState();
}

class _ReelItemViewState extends State<_ReelItemView> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isPlaying = true;
  bool _showCaptionExpanded = false;

  @override
  void initState() {
    super.initState();
    if (widget.post['mediaType'] == 'VIDEO' || widget.post['mediaType'] == 'AUDIO') {
      _initVideo();
    }
  }

  @override
  void didUpdateWidget(covariant _ReelItemView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) {
      if (widget.isActive) {
        _videoController?.play();
      } else {
        _videoController?.pause();
      }
    }
    if (oldWidget.isMuted != widget.isMuted) {
      _videoController?.setVolume(widget.isMuted ? 0.0 : 1.0);
    }
  }

  void _initVideo() async {
    final String rawUrl = widget.post['mediaUrl'] ?? '';
    final String resolved = ImageHelper.resolveUrl(rawUrl) ?? rawUrl;

    _videoController = VideoPlayerController.networkUrl(Uri.parse(resolved))
      ..setLooping(true)
      ..setVolume(widget.isMuted ? 0.0 : 1.0)
      ..initialize().then((_) {
        if (mounted) {
          setState(() => _isVideoInitialized = true);
          if (widget.isActive) {
            _videoController?.play();
          }
        }
      }).catchError((_) {
        if (mounted) setState(() => _isVideoInitialized = false);
      });
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_videoController == null || !_isVideoInitialized) return;
    setState(() {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
        _isPlaying = false;
      } else {
        _videoController!.play();
        _isPlaying = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final dev = post['developer'] ?? {};
    final String mediaType = post['mediaType'] ?? 'VIDEO';
    final bool isLiked = post['isLiked'] ?? false;
    final int likesCount = post['likesCount'] ?? 0;
    final bool isFollowing = post['isFollowing'] ?? false;
    final String caption = post['caption'] ?? '';
    final String tagTitle = post['tagTitle'] ?? '';
    final String tagPrice = post['tagPrice'] ?? '';

    return Stack(
      fit: StackFit.expand,
      children: [
        // ── MEDIA LAYER ──
        GestureDetector(
          onTap: _togglePlayPause,
          child: Container(
            color: Colors.black,
            child: mediaType == 'VIDEO'
                ? (_isVideoInitialized && _videoController != null
                    ? Center(
                        child: AspectRatio(
                          aspectRatio: _videoController!.value.aspectRatio,
                          child: VideoPlayer(_videoController!),
                        ),
                      )
                    : Stack(
                        fit: StackFit.expand,
                        children: [
                          if (post['thumbnailUrl'] != null)
                            Image.network(
                              ImageHelper.resolveUrl(post['thumbnailUrl']) ?? '',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const SizedBox(),
                            ),
                          const Center(
                            child: CircularProgressIndicator(color: Color(0xFF059669)),
                          ),
                        ],
                      ))
                : mediaType == 'AUDIO'
                    ? Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF0F172A), Color(0xFF064E3B)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 110,
                                height: 110,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF059669).withValues(alpha: 0.2),
                                  border: Border.all(color: const Color(0xFF34D399), width: 3),
                                ),
                                child: const Center(
                                  child: Icon(Icons.graphic_eq_rounded, color: Color(0xFF34D399), size: 54),
                                ),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                dev['companyName'] ?? 'Developer Audio Update',
                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Audio Site Commentary / Voice Note 🎙️',
                                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Image.network(
                        ImageHelper.resolveUrl(post['mediaUrl']) ?? '',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.broken_image_rounded, color: Colors.white54, size: 48),
                        ),
                      ),
          ),
        ),

        // Pause Indicator Overlay
        if (!_isPlaying && (mediaType == 'VIDEO' || mediaType == 'AUDIO') && _isVideoInitialized)
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 48),
            ),
          ),

        // ── GRADIENT OVERLAYS ──
        // Top Gradient
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 120,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),

        // Bottom Gradient
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 280,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Colors.black.withValues(alpha: 0.85)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),

        // ── RIGHT ACTION COLUMN ──
        Positioned(
          right: 14,
          bottom: 120,
          child: Column(
            children: [
              // Developer Profile Avatar with Follow Badge
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.bottomCenter,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: ImageHelper.buildAvatar(
                      imageUrl: dev['logoUrl'],
                      size: 44,
                      fallbackName: dev['companyName'] ?? 'Developer',
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  if (!isFollowing)
                    Positioned(
                      bottom: -8,
                      child: InkWell(
                        onTap: widget.onToggleFollow,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Color(0xFF059669),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add_rounded, color: Colors.white, size: 14),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              // Like Button
              InkWell(
                onTap: widget.onToggleLike,
                child: Column(
                  children: [
                    Icon(
                      isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: isLiked ? const Color(0xFFEF4444) : Colors.white,
                      size: 32,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$likesCount',
                      style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Chat Developer Button
              InkWell(
                onTap: widget.onChat,
                child: const Column(
                  children: [
                    Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 30),
                    SizedBox(height: 4),
                    Text('Chat', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // WhatsApp Share
              InkWell(
                onTap: widget.onShare,
                child: const Column(
                  children: [
                    Icon(Icons.share_rounded, color: Colors.white, size: 28),
                    SizedBox(height: 4),
                    Text('Share', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // More Options (Edit / Delete / Report)
              InkWell(
                onTap: widget.onMoreOptions,
                child: const Column(
                  children: [
                    Icon(Icons.more_horiz_rounded, color: Colors.white, size: 28),
                    SizedBox(height: 4),
                    Text('More', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── BOTTOM INFO & CONVERSION CARD ──
        Positioned(
          left: 16,
          right: 74,
          bottom: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Developer Name & Verification Badge
              Row(
                children: [
                  Flexible(
                    child: Text(
                      dev['companyName'] ?? 'Certified Developer',
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.verified_rounded, color: Color(0xFF34D399), size: 16),
                  const SizedBox(width: 8),
                  if (isFollowing)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('Following', style: TextStyle(color: Color(0xFF34D399), fontSize: 9.5, fontWeight: FontWeight.w800)),
                    ),
                ],
              ),
              const SizedBox(height: 6),

              // Caption with expand/collapse
              if (caption.isNotEmpty)
                GestureDetector(
                  onTap: () => setState(() => _showCaptionExpanded = !_showCaptionExpanded),
                  child: Text(
                    caption,
                    maxLines: _showCaptionExpanded ? 5 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 12.5, height: 1.35),
                  ),
                ),

              const SizedBox(height: 12),

              // ── DIRECT CONVERSION CARD ──
              if (tagTitle.isNotEmpty)
                InkWell(
                  onTap: widget.onOpenProject,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.6)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.apartment_rounded, color: Color(0xFF34D399), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tagTitle,
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900),
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (tagPrice.isNotEmpty)
                                Text(
                                  tagPrice,
                                  style: const TextStyle(color: Color(0xFF34D399), fontSize: 11, fontWeight: FontWeight.w700),
                                ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF059669),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Text('View Units', style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w900)),
                              SizedBox(width: 2),
                              Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 9),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
