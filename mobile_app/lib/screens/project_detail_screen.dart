import 'package:flutter/material.dart';
import '../core/constants/colors.dart';
import '../core/utils/currency_formatter.dart';
import '../models/project_model.dart';

class ProjectDetailScreen extends StatelessWidget {
  final ProjectModel project;

  const ProjectDetailScreen({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Text(
          project.name,
          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 16),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Project Hero Image
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(
                  image: NetworkImage(project.firstImage),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              project.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              '${project.address}, ${project.area}, ${project.city}',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),

            // Milestone Timeline Section
            const Text(
              'Construction Milestone Progress',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            ...project.milestones.map((m) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(m.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        Text('${m.percentage}%', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.emeraldText, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: m.percentage / 100,
                      backgroundColor: AppColors.background,
                      valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    if (m.verifiedBy != null) ...[
                      const SizedBox(height: 6),
                      Text('Verified by: ${m.verifiedBy}', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                    ],
                  ],
                ),
              );
            }).toList(),

            const SizedBox(height: 20),
            // Units Section
            const Text(
              'Available Unit Types',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            ...project.units.map((unit) {
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
                        Text(unit.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                        Text(CurrencyFormatter.format(unit.price), style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary, fontSize: 15)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Initial Deposit: ${CurrencyFormatter.format(unit.initialDeposit)} • ${unit.durationMonths} Mos @ ${CurrencyFormatter.format(unit.monthlyInstalment)}/mo',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
