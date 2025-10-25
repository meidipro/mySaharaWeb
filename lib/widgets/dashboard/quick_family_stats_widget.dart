import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/family_provider.dart';
import '../../providers/health_record_provider.dart';
import '../../providers/medical_timeline_provider.dart';

/// Quick Family Stats Widget - Shows key family health metrics at a glance
class QuickFamilyStatsWidget extends StatelessWidget {
  const QuickFamilyStatsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final familyProvider = context.watch<FamilyProvider>();
    final healthRecordProvider = context.watch<HealthRecordProvider>();
    final timelineProvider = context.watch<MedicalTimelineProvider>();

    final familyMembersCount = familyProvider.familyMembers.length;
    final documentsCount = healthRecordProvider.healthRecords.length;
    final timelineEventsCount = timelineProvider.timelineEvents.length;

    // Count members with chronic diseases
    final membersWithDiseases = familyProvider.familyMembers
        .where((member) =>
            member.chronicDiseases != null &&
            member.chronicDiseases!.trim().isNotEmpty)
        .length;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Title
          Row(
            children: [
              Icon(
                Icons.dashboard,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 10),
              Text(
                'Family Health Overview',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Stats Grid
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.people,
                  value: familyMembersCount.toString(),
                  label: 'Family\nMembers',
                  color: Colors.white.withOpacity(0.95),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.description,
                  value: documentsCount.toString(),
                  label: 'Health\nRecords',
                  color: Colors.white.withOpacity(0.95),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.timeline,
                  value: timelineEventsCount.toString(),
                  label: 'Timeline\nEvents',
                  color: Colors.white.withOpacity(0.95),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.monitor_heart,
                  value: membersWithDiseases.toString(),
                  label: 'Chronic\nConditions',
                  color: Colors.white.withOpacity(0.95),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: AppColors.primary,
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
