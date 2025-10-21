import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:timeline_tile/timeline_tile.dart';

import '../../constants/app_colors.dart';
import '../../models/medical_history.dart';
import '../../models/medical_document.dart';
import '../../providers/medical_timeline_provider.dart';
import '../../providers/health_record_provider.dart';
import '../health_records/health_record_detail_screen.dart';
import 'add_medical_event_screen.dart';

class MedicalTimelineScreen extends StatefulWidget {
  const MedicalTimelineScreen({super.key});

  @override
  State<MedicalTimelineScreen> createState() => _MedicalTimelineScreenState();
}

class _MedicalTimelineScreenState extends State<MedicalTimelineScreen> {
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MedicalTimelineProvider>().loadTimelineEvents();
    });
  }

  List<MedicalHistory> _getFilteredTimeline(List<MedicalHistory> timeline) {
    if (_selectedFilter == 'all') return timeline;
    return timeline.where((item) => item.eventType == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MedicalTimelineProvider>(
      builder: (context, timelineProvider, child) {
        final filteredTimeline = _getFilteredTimeline(timelineProvider.timelineEvents);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Medical Timeline'),
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textWhite,
            actions: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: _showFilterDialog,
              ),
            ],
          ),
          body: timelineProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : timelineProvider.timelineEvents.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: () => timelineProvider.loadTimelineEvents(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredTimeline.length,
                        itemBuilder: (context, index) {
                          final item = filteredTimeline[index];
                          final isFirst = index == 0;
                          final isLast = index == filteredTimeline.length - 1;
                          return _buildTimelineItem(item, isFirst, isLast);
                        },
                      ),
                    ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _addMedicalEvent,
            icon: const Icon(Icons.add),
            label: const Text('Add Medical History'),
          ),
        );
      },
    );
  }

  Widget _buildTimelineItem(MedicalHistory item, bool isFirst, bool isLast) {
    return TimelineTile(
      isFirst: isFirst,
      isLast: isLast,
      indicatorStyle: IndicatorStyle(
        width: 40,
        height: 40,
        indicator: Container(
          decoration: BoxDecoration(
            color: _getEventColor(item.eventType),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getEventIcon(item.eventType),
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
      beforeLineStyle: LineStyle(
        color: AppColors.border,
        thickness: 2,
      ),
      endChild: Container(
        margin: const EdgeInsets.only(left: 16, bottom: 24),
        child: Card(
          child: InkWell(
            onTap: () => _showEventDetails(item),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          DateFormat('MMM dd, yyyy').format(item.eventDate),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ),
                      Chip(
                        label: Text(
                          item.eventType,
                          style: const TextStyle(fontSize: 11),
                        ),
                        backgroundColor: _getEventColor(item.eventType).withOpacity(0.2),
                        labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (item.disease != null)
                    Text(
                      item.disease!,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  if (item.symptoms != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.symptoms!,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (item.doctorName != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.person, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          'Dr. ${item.doctorName}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (item.doctorSpecialty != null) ...[
                          const Text(' • '),
                          Text(
                            item.doctorSpecialty!,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ],
                  if (item.hospital != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.local_hospital, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          item.hospital!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.timeline,
            size: 80,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 16),
          Text(
            'No medical events yet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first medical event to start tracking',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
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

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Timeline'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFilterOption('All Events', 'all'),
            _buildFilterOption('Diagnosis', 'diagnosis'),
            _buildFilterOption('Treatment', 'treatment'),
            _buildFilterOption('Surgery', 'surgery'),
            _buildFilterOption('Consultation', 'consultation'),
            _buildFilterOption('Emergency', 'emergency'),
            _buildFilterOption('Checkup', 'checkup'),
            _buildFilterOption('Vaccination', 'vaccination'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(String label, String value) {
    return RadioListTile<String>(
      title: Text(label),
      value: value,
      groupValue: _selectedFilter,
      onChanged: (val) {
        setState(() => _selectedFilter = val!);
        Navigator.pop(context);
      },
    );
  }

  void _showEventDetails(MedicalHistory item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.disease ?? 'Medical History'),
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
                ..._buildAttachedDocumentsList(item.documentIds!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _editEvent(item);
            },
            child: const Text('Edit'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteEvent(item);
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAttachedDocumentsList(List<String> documentIds) {
    final healthRecordProvider = context.read<HealthRecordProvider>();
    final documents = healthRecordProvider.healthRecords
        .where((doc) => documentIds.contains(doc.id))
        .toList();

    if (documents.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Documents not found',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ];
    }

    return documents.map((doc) {
      return InkWell(
        onTap: () => _viewDocument(doc),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Document thumbnail/image
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: doc.thumbnailUrl != null && doc.thumbnailUrl!.isNotEmpty
                      ? Image.network(
                          doc.thumbnailUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            // Try fileUrl if thumbnail fails
                            if (doc.fileUrl.isNotEmpty) {
                              return Image.network(
                                doc.fileUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(Icons.description, color: AppColors.primary, size: 20);
                                },
                              );
                            }
                            return const Icon(Icons.description, color: AppColors.primary, size: 20);
                          },
                        )
                      : (doc.fileUrl.isNotEmpty
                          ? Image.network(
                              doc.fileUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.description, color: AppColors.primary, size: 20);
                              },
                            )
                          : const Icon(Icons.description, color: AppColors.primary, size: 20)),
                ),
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
                    const SizedBox(height: 2),
                    Text(
                      doc.documentType,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  void _viewDocument(MedicalDocument document) {
    Get.to(() => HealthRecordDetailScreen(document: document));
  }

  void _editEvent(MedicalHistory event) {
    Get.to(() => AddMedicalEventScreen(event: event));
  }

  void _deleteEvent(MedicalHistory event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: Text(
          'Are you sure you want to delete this medical event? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              // Show loading indicator
              Get.dialog(
                const Center(
                  child: CircularProgressIndicator(),
                ),
                barrierDismissible: false,
              );

              try {
                final timelineProvider = context.read<MedicalTimelineProvider>();
                final success = await timelineProvider.deleteTimelineEvent(
                  event.id!,
                );

                // Close loading dialog
                Get.back();

                if (success) {
                  Get.snackbar(
                    'Deleted',
                    'Event deleted successfully',
                    backgroundColor: AppColors.success,
                    colorText: AppColors.textWhite,
                    snackPosition: SnackPosition.BOTTOM,
                  );
                } else {
                  Get.snackbar(
                    'Error',
                    'Failed to delete event',
                    backgroundColor: AppColors.error,
                    colorText: AppColors.textWhite,
                    snackPosition: SnackPosition.BOTTOM,
                  );
                }
              } catch (e) {
                // Close loading dialog
                Get.back();
                Get.snackbar(
                  'Error',
                  'Failed to delete event: $e',
                  backgroundColor: AppColors.error,
                  colorText: AppColors.textWhite,
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(value),
        ],
      ),
    );
  }

  void _addMedicalEvent() {
    Get.to(() => const AddMedicalEventScreen());
  }
}
