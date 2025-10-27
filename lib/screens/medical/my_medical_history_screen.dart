import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../constants/app_colors.dart';
import '../../models/medical_history.dart';
import '../../providers/medical_timeline_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/health_record_provider.dart';
import '../timeline/add_medical_event_screen.dart';
import '../timeline/medical_timeline_screen.dart';
import '../health_records/health_record_detail_screen.dart';

class MyMedicalHistoryScreen extends StatefulWidget {
  const MyMedicalHistoryScreen({super.key});

  @override
  State<MyMedicalHistoryScreen> createState() => _MyMedicalHistoryScreenState();
}

class _MyMedicalHistoryScreenState extends State<MyMedicalHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MedicalTimelineProvider>().loadTimelineEvents();
    });
  }

  Color _getEventColor(String eventType) {
    switch (eventType.toLowerCase()) {
      case 'diagnosis':
        return AppColors.healthRed;
      case 'treatment':
        return AppColors.healthGreen;
      case 'surgery':
        return AppColors.healthOrange;
      case 'consultation':
        return AppColors.healthBlue;
      case 'emergency':
        return AppColors.error;
      case 'checkup':
        return AppColors.success;
      case 'vaccination':
        return AppColors.healthPurple;
      default:
        return AppColors.primary;
    }
  }

  IconData _getEventIcon(String eventType) {
    switch (eventType.toLowerCase()) {
      case 'diagnosis':
        return Icons.medical_services;
      case 'treatment':
        return Icons.healing;
      case 'surgery':
        return Icons.cut;
      case 'consultation':
        return Icons.chat;
      case 'emergency':
        return Icons.emergency;
      case 'checkup':
        return Icons.check_circle;
      case 'vaccination':
        return Icons.vaccines;
      default:
        return Icons.event;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      body: Consumer<MedicalTimelineProvider>(
        builder: (context, timelineProvider, child) {
          // Filter to show only user's own medical history
          final myHistories = timelineProvider.timelineEvents
              .where((h) => h.familyMemberId == null)
              .toList();

          return CustomScrollView(
            slivers: [
              // Beautiful Header
              SliverAppBar(
                expandedHeight: 180,
                floating: false,
                pinned: true,
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                title: const Text(
                  'My Medical History',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withOpacity(0.8),
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 70, 20, 20),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.white,
                              child: Icon(
                                Icons.person,
                                size: 32,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    authProvider.user?.fullName ?? 'User',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${myHistories.length} Medical Events',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Statistics Cards
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          context,
                          'Total Events',
                          '${myHistories.length}',
                          Icons.event_note,
                          AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          context,
                          'This Year',
                          '${myHistories.where((h) => h.eventDate.year == DateTime.now().year).length}',
                          Icons.calendar_today,
                          AppColors.success,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          context,
                          'Last 30 Days',
                          '${myHistories.where((h) => h.eventDate.isAfter(DateTime.now().subtract(const Duration(days: 30)))).length}',
                          Icons.access_time,
                          AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Medical History List
              if (myHistories.isEmpty)
                SliverFillRemaining(
                  child: _buildEmptyState(),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final history = myHistories[index];
                        final eventColor = _getEventColor(history.eventType);
                        final eventIcon = _getEventIcon(history.eventType);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: InkWell(
                            onTap: () {
                              _showEventDetails(context, history);
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: eventColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          eventIcon,
                                          color: eventColor,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              history.disease ?? history.eventType,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.calendar_today,
                                                  size: 14,
                                                  color: AppColors.textSecondary,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  DateFormat('MMM dd, yyyy').format(history.eventDate),
                                                  style: TextStyle(
                                                    color: AppColors.textSecondary,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: eventColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          history.eventType.toUpperCase(),
                                          style: TextStyle(
                                            color: eventColor,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (history.doctorName != null || history.hospital != null) ...[
                                    const SizedBox(height: 12),
                                    const Divider(),
                                    const SizedBox(height: 8),
                                    if (history.doctorName != null)
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.person,
                                            size: 16,
                                            color: AppColors.textSecondary,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Dr. ${history.doctorName}',
                                            style: TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    if (history.hospital != null) ...[
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.local_hospital,
                                            size: 16,
                                            color: AppColors.textSecondary,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              history.hospital!,
                                              style: TextStyle(
                                                color: AppColors.textSecondary,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: myHistories.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Get.to(() => AddMedicalEventScreen());
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Add Event'),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.medical_services_outlined,
                size: 80,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Medical History Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Start tracking your health journey by adding your first medical event.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Get.to(() => AddMedicalEventScreen());
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Medical Event'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show event details in a dialog
  void _showEventDetails(BuildContext context, MedicalHistory item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.disease ?? 'Medical Event'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Date', DateFormat('MMM dd, yyyy').format(item.eventDate)),
              _buildDetailRow('Type', item.eventType),
              if (item.symptoms != null) _buildDetailRow('Symptoms', item.symptoms!),
              if (item.doctorName != null) _buildDetailRow('Doctor', 'Dr. ${item.doctorName}'),
              if (item.doctorSpecialty != null) _buildDetailRow('Specialty', item.doctorSpecialty!),
              if (item.hospital != null) _buildDetailRow('Hospital', item.hospital!),
              if (item.treatment != null) _buildDetailRow('Treatment', item.treatment!),
              if (item.medications != null) _buildDetailRow('Medications', item.medications!),
              if (item.notes != null) _buildDetailRow('Notes', item.notes!),

              // Attached Documents Section
              if (item.documentIds != null && item.documentIds!.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Attached Documents (${item.documentIds!.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Consumer<HealthRecordProvider>(
                  builder: (context, healthRecordProvider, child) {
                    final documents = healthRecordProvider.healthRecords
                        .where((doc) => item.documentIds!.contains(doc.id))
                        .toList();

                    if (documents.isEmpty) {
                      return Text(
                        'No documents found',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      );
                    }

                    return Column(
                      children: documents.map((doc) {
                        return InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            Get.to(() => HealthRecordDetailScreen(document: doc));
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _getDocumentIcon(doc.documentType),
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        doc.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                      if (doc.description != null)
                                        Text(
                                          doc.description!,
                                          style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 12,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Build detail row
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  /// Get document icon based on type
  IconData _getDocumentIcon(String type) {
    switch (type.toLowerCase()) {
      case 'prescription':
        return Icons.medication;
      case 'test_report':
      case 'blood_report':
        return Icons.biotech;
      case 'xray_report':
      case 'ct_scan':
      case 'mri_report':
        return Icons.image;
      case 'doctor_notes':
        return Icons.notes;
      default:
        return Icons.description;
    }
  }
}
