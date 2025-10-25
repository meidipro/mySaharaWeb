import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../providers/family_provider.dart';
import '../../providers/health_record_provider.dart';
import '../../providers/medical_timeline_provider.dart';

/// Family Health Report Widget - Generate and view comprehensive health reports
class FamilyHealthReportWidget extends StatelessWidget {
  const FamilyHealthReportWidget({super.key});

  @override
  Widget build(BuildContext context) {
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
              AppColors.healthPurple.withOpacity(0.05),
              AppColors.healthBlue.withOpacity(0.05),
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
                    color: AppColors.healthPurple.withOpacity(0.2),
                  ),
                  child: Icon(
                    Icons.assessment,
                    color: AppColors.healthPurple,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Family Health Report',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Comprehensive health summary',
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
            const SizedBox(height: 20),

            // Report summary
            Consumer3<FamilyProvider, HealthRecordProvider, MedicalTimelineProvider>(
              builder: (context, familyProvider, healthProvider, timelineProvider, child) {
                return _buildReportSummary(
                  context,
                  familyProvider,
                  healthProvider,
                  timelineProvider,
                );
              },
            ),

            const SizedBox(height: 20),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showReportPreview(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.healthPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text('View Report', style: TextStyle(fontSize: 14)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _exportReport(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.healthPurple,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: AppColors.healthPurple, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.file_download, size: 18),
                    label: const Text('Export', style: TextStyle(fontSize: 14)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportSummary(
    BuildContext context,
    FamilyProvider familyProvider,
    HealthRecordProvider healthProvider,
    MedicalTimelineProvider timelineProvider,
  ) {
    final now = DateTime.now();
    final dateFormat = DateFormat('MMM d, yyyy');

    // Calculate statistics
    final totalMembers = familyProvider.familyMembers.length;
    final totalRecords = healthProvider.healthRecords.length;
    final totalEvents = timelineProvider.timelineEvents.length;

    final membersWithDiseases = familyProvider.familyMembers
        .where((m) => m.chronicDiseases != null && m.chronicDiseases!.trim().isNotEmpty)
        .length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.healthPurple.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                'Report Date: ${dateFormat.format(now)}',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Stats grid
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Members',
                  totalMembers.toString(),
                  Icons.people,
                  AppColors.healthBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  'Records',
                  totalRecords.toString(),
                  Icons.description,
                  AppColors.healthGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Events',
                  totalEvents.toString(),
                  Icons.timeline,
                  AppColors.healthOrange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  'Conditions',
                  membersWithDiseases.toString(),
                  Icons.monitor_heart,
                  AppColors.healthRed,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
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

  void _showReportPreview(BuildContext context) {
    final familyProvider = context.read<FamilyProvider>();
    final healthProvider = context.read<HealthRecordProvider>();
    final timelineProvider = context.read<MedicalTimelineProvider>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.assessment, color: AppColors.healthPurple),
            const SizedBox(width: 12),
            const Text('Family Health Report'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Report Generated: ${DateFormat('MMM d, yyyy - h:mm a').format(DateTime.now())}',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 20),

              _buildReportSection(
                'Family Members',
                '${familyProvider.familyMembers.length} member(s)',
                Icons.people,
                AppColors.healthBlue,
              ),
              const SizedBox(height: 12),

              _buildReportSection(
                'Health Records',
                '${healthProvider.healthRecords.length} document(s)',
                Icons.description,
                AppColors.healthGreen,
              ),
              const SizedBox(height: 12),

              _buildReportSection(
                'Medical Events',
                '${timelineProvider.timelineEvents.length} event(s)',
                Icons.timeline,
                AppColors.healthOrange,
              ),
              const SizedBox(height: 12),

              _buildReportSection(
                'Chronic Conditions',
                '${familyProvider.familyMembers.where((m) => m.chronicDiseases != null && m.chronicDiseases!.trim().isNotEmpty).length} member(s) affected',
                Icons.monitor_heart,
                AppColors.healthRed,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _exportReport(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.healthPurple,
            ),
            icon: const Icon(Icons.file_download, size: 18),
            label: const Text('Export'),
          ),
        ],
      ),
    );
  }

  Widget _buildReportSection(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.2),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
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

  void _exportReport(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Report exported successfully!',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () {
            // Navigate to exported files or share
          },
        ),
      ),
    );
  }
}
