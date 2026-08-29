import 'package:flutter/material.dart';

class DeveloperSiteGalleryScreen extends StatefulWidget {
  const DeveloperSiteGalleryScreen({super.key});

  @override
  State<DeveloperSiteGalleryScreen> createState() => _DeveloperSiteGalleryScreenState();
}

class _DeveloperSiteGalleryScreenState extends State<DeveloperSiteGalleryScreen> {
  final List<Map<String, dynamic>> _milestoneGalleries = [
    {
      'stage': 'Stage 1: Substructure & Foundation (100% Verified)',
      'date': 'Aug 14, 2026',
      'inspector': 'Engr. D. Adeleke (COREN/R.38491)',
      'status': 'VERIFIED_PASSED',
      'photos': [
        {
          'url': 'https://images.unsplash.com/photo-1541888946425-d0fbb18f15f6?w=1200&q=80',
          'caption': 'Excavation & Ground Beam Rebar Reinforcement',
          'geotag': '6.4474° N, 3.4731° E • Ikate, Lagos',
        },
        {
          'url': 'https://images.unsplash.com/photo-1504307651254-35680f356dfd?w=1200&q=80',
          'caption': 'DPC German Floor Slab Casting (ReadyMix 30N)',
          'geotag': '6.4474° N, 3.4731° E • Ikate, Lagos',
        },
      ],
    },
    {
      'stage': 'Stage 2: Structural Columns & Suspended Slab (75% Done)',
      'date': 'Aug 26, 2026',
      'inspector': 'Site Engineer Inspection Pending',
      'status': 'IN_PROGRESS',
      'photos': [
        {
          'url': 'https://images.unsplash.com/photo-1590381105924-c72589b9ef3f?w=1200&q=80',
          'caption': '1st Floor Suspended Slab Formwork & Rebar Placement',
          'geotag': '6.4474° N, 3.4731° E • Ikate, Lagos',
        },
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Site Drone & Progress Gallery', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 17)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_a_photo_rounded, color: Color(0xFF059669)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Site photo upload initialized with automatic EXIF timestamp & GPS geotagging.'),
                  backgroundColor: Color(0xFF059669),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _milestoneGalleries.length,
        itemBuilder: (context, index) {
          final gallery = _milestoneGalleries[index];
          final photos = (gallery['photos'] as List?) ?? [];

          return Container(
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        gallery['stage'] ?? 'Stage',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        gallery['status'] ?? 'VERIFIED',
                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF059669)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Certified by: ${gallery['inspector']} • ${gallery['date']}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 14),

                ...photos.map((photo) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.network(
                          photo['url'] ?? '',
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 180,
                            color: const Color(0xFFE2E8F0),
                            child: const Center(child: Icon(Icons.broken_image_rounded, color: Color(0xFF94A3B8))),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                photo['caption'] ?? '',
                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.pin_drop_rounded, size: 12, color: Color(0xFF059669)),
                                  const SizedBox(width: 4),
                                  Text(
                                    photo['geotag'] ?? '',
                                    style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}
