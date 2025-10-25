import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import '../../providers/family_provider.dart';
import '../../screens/family/family_dashboard_screen.dart';

/// Family Chronic Diseases Widget - Shows family members with chronic conditions
class FamilyChronicDiseasesWidget extends StatelessWidget {
  const FamilyChronicDiseasesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final familyProvider = context.watch<FamilyProvider>();
    final membersWithDiseases = familyProvider.familyMembers
        .where((member) =>
            member.chronicDiseases != null &&
            member.chronicDiseases!.trim().isNotEmpty)
        .toList();

    // Calculate total unique diseases across family
    final allDiseases = <String>{};
    for (var member in membersWithDiseases) {
      final diseases = member.chronicDiseases!
          .split(',')
          .map((d) => d.trim())
          .where((d) => d.isNotEmpty);
      allDiseases.addAll(diseases);
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.healthRed.withOpacity(0.05),
              AppColors.healthOrange.withOpacity(0.05),
            ],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.healthRed.withOpacity(0.2),
                  ),
                  child: Icon(
                    Icons.monitor_heart,
                    color: AppColors.healthRed,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chronic Conditions',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (membersWithDiseases.isNotEmpty)
                        Text(
                          '${membersWithDiseases.length} member${membersWithDiseases.length > 1 ? 's' : ''} • ${allDiseases.length} condition${allDiseases.length > 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                if (membersWithDiseases.isNotEmpty)
                  TextButton(
                    onPressed: () => Get.to(() => const FamilyDashboardScreen()),
                    child: const Text('Manage'),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Content
            if (membersWithDiseases.isEmpty)
              _buildEmptyState()
            else
              _buildDiseasesList(membersWithDiseases),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.success.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.success.withOpacity(0.1),
            ),
            child: Icon(
              Icons.check_circle_outline,
              color: AppColors.success,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No Chronic Conditions',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your family members have no chronic conditions tracked',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiseasesList(List members) {
    return Column(
      children: members.take(3).map((member) {
        return _buildMemberDiseaseCard(member);
      }).toList(),
    );
  }

  Widget _buildMemberDiseaseCard(dynamic member) {
    final name = member.fullName as String? ?? 'Unknown';
    final relationship = member.relationship as String? ?? '';
    final diseases = (member.chronicDiseases as String? ?? '')
        .split(',')
        .map((d) => d.trim())
        .where((d) => d.isNotEmpty)
        .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.healthRed.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Member info
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.healthRed.withOpacity(0.1),
                ),
                child: Icon(
                  Icons.person,
                  color: AppColors.healthRed,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      relationship,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.healthRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${diseases.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.healthRed,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Diseases
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: diseases.take(4).map((disease) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.healthRed.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.healthRed.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.local_hospital,
                      size: 12,
                      color: AppColors.healthRed,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      disease,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          if (diseases.length > 4) ...[
            const SizedBox(height: 6),
            Text(
              '+${diseases.length - 4} more',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textHint,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
