import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../models/project_model.dart';
import '../widgets/persistent_bottom_nav.dart';
import 'create_project_screen.dart';
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateProjectScreen(onProjectCreated: _fetchProjects),
      ),
    ).then((val) {
      if (val == true) _fetchProjects();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const PersistentBottomNav(activeIndex: 1),
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
