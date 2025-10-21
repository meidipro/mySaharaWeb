import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:timeline_tile/timeline_tile.dart';

import '../../constants/app_colors.dart';
import '../../models/medical_history.dart';
import '../../models/medical_document.dart';
import '../../services/medical_history_share_service.dart';
import '../health_records/health_record_detail_screen.dart';

class ViewSharedHistoryScreen extends StatefulWidget {
  final String shareCode;

  const ViewSharedHistoryScreen({
    super.key,
    required this.shareCode,
  });

  @override
  State<ViewSharedHistoryScreen> createState() =>
      _ViewSharedHistoryScreenState();
}

class _ViewSharedHistoryScreenState extends State<ViewSharedHistoryScreen> {
  final MedicalHistoryShareService _shareService =
      MedicalHistoryShareService();

  bool _isLoading = true;
  String? _error;
  List<MedicalHistory> _histories = [];
  List<MedicalDocument> _documents = [];

  @override
  void initState() {
    super.initState();
    _loadSharedHistory();
  }

  Future<void> _loadSharedHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('DEBUG: Loading shared history for code: ${widget.shareCode}');

      // Load histories and documents in parallel
      final historiesFuture =
          _shareService.getSharedMedicalHistories(widget.shareCode);
      final documentsFuture =
          _shareService.getSharedDocuments(widget.shareCode);

      final results = await Future.wait([historiesFuture, documentsFuture]);

      print('DEBUG: Loaded ${(results[0] as List).length} histories');
      print('DEBUG: Loaded ${(results[1] as List).length} documents');

      setState(() {
        _histories = results[0] as List<MedicalHistory>;
        _documents = results[1] as List<MedicalDocument>;
        _isLoading = false;
      });
    } catch (e) {
      print('DEBUG: Error loading shared history: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Medical History'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : _buildHistoryList(),
    );
  }

  Widget _buildErrorState() {
    final isExpired = _error?.contains('expired') ?? false;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isExpired ? Icons.timer_off : Icons.error_outline,
              size: 80,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              isExpired ? 'Share Code Expired' : 'Access Denied',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isExpired
                  ? 'This QR code has expired. Please ask the patient to generate a new one.'
                  : _error ?? 'Unable to access medical history',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Get.back(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textWhite,
              ),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList() {
    if (_histories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox,
              size: 80,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 16),
            Text(
              'No Medical History Shared',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'The patient has not shared any medical history',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSharedHistory,
      child: CustomScrollView(
        slivers: [
          // Info banner
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Viewing Shared Medical History',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'This information is confidential. Handle with care.',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Timeline
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final history = _histories[index];
                  final isFirst = index == 0;
                  final isLast = index == _histories.length - 1;
                  return _buildTimelineItem(history, isFirst, isLast);
                },
                childCount: _histories.length,
              ),
            ),
          ),

          // Bottom spacing
          const SliverToBoxAdapter(
            child: SizedBox(height: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
      MedicalHistory item, bool isFirst, bool isLast) {
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
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                      ),
                      Chip(
                        label: Text(
                          item.eventType,
                          style: const TextStyle(fontSize: 11),
                        ),
                        backgroundColor:
                            _getEventColor(item.eventType).withOpacity(0.2),
                        labelPadding:
                            const EdgeInsets.symmetric(horizontal: 8),
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
                        const Icon(Icons.person,
                            size: 16, color: AppColors.textSecondary),
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
                        const Icon(Icons.local_hospital,
                            size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          item.hospital!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                  if (item.documentIds != null &&
                      item.documentIds!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.attach_file,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${item.documentIds!.length} ${item.documentIds!.length == 1 ? 'document' : 'documents'} attached',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
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
              _buildDetailRow(
                  'Date', DateFormat('MMM dd, yyyy').format(item.eventDate)),
              _buildDetailRow('Type', item.eventType),
              if (item.symptoms != null)
                _buildDetailRow('Symptoms', item.symptoms!),
              if (item.doctorName != null)
                _buildDetailRow('Doctor', 'Dr. ${item.doctorName}'),
              if (item.doctorSpecialty != null)
                _buildDetailRow('Specialty', item.doctorSpecialty!),
              if (item.hospital != null)
                _buildDetailRow('Hospital', item.hospital!),
              if (item.treatment != null)
                _buildDetailRow('Treatment', item.treatment!),
              if (item.medications != null)
                _buildDetailRow('Medications', item.medications!),
              if (item.notes != null) _buildDetailRow('Notes', item.notes!),

              // Attached Documents Section
              if (item.documentIds != null &&
                  item.documentIds!.isNotEmpty) ...[
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
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

  List<Widget> _buildAttachedDocumentsList(List<String> documentIds) {
    final documents =
        _documents.where((doc) => documentIds.contains(doc.id)).toList();

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
                  child: doc.thumbnailUrl != null &&
                          doc.thumbnailUrl!.isNotEmpty
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
                                  return const Icon(Icons.description,
                                      color: AppColors.primary, size: 20);
                                },
                              );
                            }
                            return const Icon(Icons.description,
                                color: AppColors.primary, size: 20);
                          },
                        )
                      : (doc.fileUrl.isNotEmpty
                          ? Image.network(
                              doc.fileUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.description,
                                    color: AppColors.primary, size: 20);
                              },
                            )
                          : const Icon(Icons.description,
                              color: AppColors.primary, size: 20)),
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
}
