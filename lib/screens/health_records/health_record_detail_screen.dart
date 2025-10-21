import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../constants/app_colors.dart';
import '../../models/medical_document.dart';
import '../../providers/health_record_provider.dart';
import '../../services/health_record_service.dart';

/// Screen for viewing health record details
class HealthRecordDetailScreen extends StatefulWidget {
  final MedicalDocument document;

  const HealthRecordDetailScreen({
    super.key,
    required this.document,
  });

  @override
  State<HealthRecordDetailScreen> createState() => _HealthRecordDetailScreenState();
}

class _HealthRecordDetailScreenState extends State<HealthRecordDetailScreen> {
  final HealthRecordService _healthRecordService = HealthRecordService();
  String? _signedUrl;
  bool _isLoadingUrl = true;

  @override
  void initState() {
    super.initState();
    _loadSignedUrl();
  }

  Future<void> _loadSignedUrl() async {
    try {
      final url = await _healthRecordService.getSignedUrl(widget.document.fileUrl);
      if (mounted) {
        setState(() {
          _signedUrl = url;
          _isLoadingUrl = false;
        });
      }
    } catch (e) {
      print('ERROR: Failed to load signed URL: $e');
      if (mounted) {
        setState(() {
          _isLoadingUrl = false;
        });
      }
    }
  }

  /// Get color for document type
  Color _getDocumentTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'prescription':
        return AppColors.prescription;
      case 'testreport':
        return AppColors.testReport;
      case 'mrireport':
        return AppColors.mriReport;
      case 'xrayreport':
        return AppColors.xrayReport;
      case 'bloodreport':
        return AppColors.bloodReport;
      default:
        return AppColors.primary;
    }
  }

  /// Format document type for display
  String _formatDocumentType(String type) {
    return type
        .replaceAllMapped(
          RegExp(r'([A-Z])'),
          (match) => ' ${match.group(0)}',
        )
        .trim()
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    final color = _getDocumentTypeColor(widget.document.documentType);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Document Details'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              _handleShare(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              _showMoreOptions(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Document image/preview
            _buildDocumentPreview(context),

            // Document details
            Padding(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Document type chip
                  Chip(
                    avatar: CircleAvatar(
                      backgroundColor: color,
                      child: Icon(
                        Icons.description,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    label: Text(_formatDocumentType(widget.document.documentType)),
                    backgroundColor: color.withOpacity(0.1),
                    labelStyle: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Text(
                    widget.document.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 24),

                  // Document information
                  _buildInfoCard(context, [
                    _InfoItem(
                      icon: Icons.calendar_today,
                      label: 'Document Date',
                      value: dateFormat.format(widget.document.documentDate),
                    ),
                    if (widget.document.doctorName != null)
                      _InfoItem(
                        icon: Icons.person,
                        label: 'Doctor',
                        value: widget.document.doctorName!,
                      ),
                    if (widget.document.hospital != null)
                      _InfoItem(
                        icon: Icons.local_hospital,
                        label: 'Hospital/Clinic',
                        value: widget.document.hospital!,
                      ),
                    if (widget.document.disease != null)
                      _InfoItem(
                        icon: Icons.medical_information,
                        label: 'Disease/Condition',
                        value: widget.document.disease!,
                      ),
                  ]),
                  const SizedBox(height: 16),

                  // Description
                  if (widget.document.description != null &&
                      widget.document.description!.isNotEmpty) ...[
                    _buildSectionTitle(context, 'Description'),
                    const SizedBox(height: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          widget.document.description!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // OCR Data
                  if (widget.document.ocrData != null &&
                      widget.document.ocrData!['text'] != null) ...[
                    _buildSectionTitle(context, 'Extracted Text (OCR)'),
                    const SizedBox(height: 8),
                    Card(
                      child: ExpansionTile(
                        title: const Text('View extracted text'),
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              widget.document.ocrData!['text'],
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Metadata
                  _buildSectionTitle(context, 'Metadata'),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildMetadataRow(
                            context,
                            'Created',
                            DateFormat('MMM d, yyyy • h:mm a')
                                .format(widget.document.createdAt),
                          ),
                          if (widget.document.updatedAt != null) ...[
                            const Divider(),
                            _buildMetadataRow(
                              context,
                              'Last Updated',
                              DateFormat('MMM d, yyyy • h:mm a')
                                  .format(widget.document.updatedAt!),
                            ),
                          ],
                          const Divider(),
                          _buildMetadataRow(
                            context,
                            'Document ID',
                            widget.document.id ?? 'N/A',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Action buttons
                  _buildActionButtons(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build document preview section
  Widget _buildDocumentPreview(BuildContext context) {
    return Container(
      height: 300,
      color: AppColors.background,
      child: _isLoadingUrl
          ? const Center(child: CircularProgressIndicator())
          : _signedUrl != null
              ? GestureDetector(
                  onTap: () {
                    _viewFullImage(context);
                  },
                  child: Hero(
                    tag: 'document_${widget.document.id}',
                    child: CachedNetworkImage(
                      imageUrl: _signedUrl!,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      errorWidget: (context, url, error) => Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.broken_image,
                              size: 64,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Failed to load image',
                              style:
                                  Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.description,
                        size: 64,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No preview available',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
    );
  }

  /// Build info card with multiple items
  Widget _buildInfoCard(BuildContext context, List<_InfoItem> items) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: items.map((item) {
            final isLast = item == items.last;
            return Column(
              children: [
                _buildInfoRow(context, item),
                if (!isLast) const Divider(height: 24),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Build single info row
  Widget _buildInfoRow(BuildContext context, _InfoItem item) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          item.icon,
          size: 20,
          color: AppColors.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                item.value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build section title
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  /// Build metadata row
  Widget _buildMetadataRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }

  /// Build action buttons
  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              _handleDownload(context);
            },
            icon: const Icon(Icons.download),
            label: const Text('Download'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              _handleShare(context);
            },
            icon: const Icon(Icons.share),
            label: const Text('Share'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  /// View full image
  void _viewFullImage(BuildContext context) {
    if (_signedUrl == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: const Text('Document'),
          ),
          body: Center(
            child: InteractiveViewer(
              child: Hero(
                tag: 'document_${widget.document.id}',
                child: CachedNetworkImage(
                  imageUrl: _signedUrl!,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Handle share
  void _handleShare(BuildContext context) {
    // TODO: Implement sharing functionality
    Get.snackbar(
      'Share',
      'Sharing functionality coming soon',
      backgroundColor: AppColors.info,
      colorText: AppColors.textWhite,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  /// Handle download
  void _handleDownload(BuildContext context) {
    // TODO: Implement download functionality
    Get.snackbar(
      'Download',
      'Download functionality coming soon',
      backgroundColor: AppColors.info,
      colorText: AppColors.textWhite,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  /// Show more options
  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: AppColors.primary),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to edit screen
                Get.snackbar(
                  'Edit',
                  'Edit functionality coming soon',
                  backgroundColor: AppColors.info,
                  colorText: AppColors.textWhite,
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.print, color: AppColors.primary),
              title: const Text('Print'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement print
                Get.snackbar(
                  'Print',
                  'Print functionality coming soon',
                  backgroundColor: AppColors.info,
                  colorText: AppColors.textWhite,
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppColors.error),
              title: const Text('Delete', style: TextStyle(color: AppColors.error)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Confirm deletion
  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text(
          'Are you sure you want to delete "${widget.document.title}"? This action cannot be undone.',
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
                // Delete document
                final healthRecordProvider = context.read<HealthRecordProvider>();
                final success = await healthRecordProvider.deleteHealthRecord(
                  widget.document.id!,
                );

                // Close loading dialog
                Get.back();

                if (success) {
                  // Close detail screen
                  Get.back();
                  Get.snackbar(
                    'Deleted',
                    'Document deleted successfully',
                    backgroundColor: AppColors.success,
                    colorText: AppColors.textWhite,
                    snackPosition: SnackPosition.BOTTOM,
                  );
                } else {
                  Get.snackbar(
                    'Error',
                    'Failed to delete document',
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
                  'Failed to delete document: $e',
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
}

/// Info item model
class _InfoItem {
  final IconData icon;
  final String label;
  final String value;

  _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });
}
