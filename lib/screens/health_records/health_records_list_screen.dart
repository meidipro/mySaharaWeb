import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:intl/intl.dart';

import '../../constants/app_colors.dart';
import '../../models/medical_document.dart';
import '../../providers/health_record_provider.dart';
import 'add_health_record_screen.dart';
import 'health_record_detail_screen.dart';

/// Screen displaying list of all health records with filtering
class HealthRecordsListScreen extends StatefulWidget {
  const HealthRecordsListScreen({super.key});

  @override
  State<HealthRecordsListScreen> createState() =>
      _HealthRecordsListScreenState();
}

class _HealthRecordsListScreenState extends State<HealthRecordsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';
  String _searchQuery = '';

  final List<String> _filterOptions = [
    'All',
    'prescription',
    'testReport',
    'mriReport',
    'xrayReport',
    'bloodReport',
    'other',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  /// Get icon for document type
  IconData _getDocumentTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'prescription':
        return Icons.medication;
      case 'testreport':
        return Icons.science;
      case 'mrireport':
      case 'xrayreport':
        return Icons.medical_services;
      case 'bloodreport':
        return Icons.bloodtype;
      default:
        return Icons.description;
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
    final healthRecordProvider = context.watch<HealthRecordProvider>();
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;

    // Filter documents based on search and filter
    List<MedicalDocument> filteredDocs = healthRecordProvider.healthRecords;

    if (_selectedFilter != 'All') {
      filteredDocs = filteredDocs
          .where((doc) =>
              doc.documentType.toLowerCase() == _selectedFilter.toLowerCase())
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      filteredDocs = filteredDocs.where((doc) {
        return doc.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            doc.documentType.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (doc.doctorName?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
                false) ||
            (doc.hospital?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
                false);
      }).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Records'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () {
              _showSortOptions(context, healthRecordProvider);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and filter section
          Container(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            color: AppColors.surface,
            child: Column(
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search records...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 12),

                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filterOptions.map((filter) {
                      final isSelected = _selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(_formatDocumentType(filter)),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedFilter = filter;
                            });
                          },
                          backgroundColor: AppColors.surface,
                          selectedColor: AppColors.primary.withOpacity(0.2),
                          checkmarkColor: AppColors.primary,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Documents list
          Expanded(
            child: healthRecordProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredDocs.isEmpty
                    ? _buildEmptyState(context)
                    : RefreshIndicator(
                        onRefresh: () async {
                          await healthRecordProvider.loadHealthRecords();
                        },
                        child: isMobile
                            ? _buildListView(filteredDocs)
                            : _buildGridView(filteredDocs),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Get.to(() => const AddHealthRecordScreen());
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Record'),
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open,
              size: 100,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              _searchQuery.isNotEmpty || _selectedFilter != 'All'
                  ? 'No records found'
                  : 'No health records yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty || _selectedFilter != 'All'
                  ? 'Try adjusting your search or filters'
                  : 'Add your first health record to get started',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 24),
            if (_searchQuery.isEmpty && _selectedFilter == 'All')
              ElevatedButton.icon(
                onPressed: () {
                  Get.to(() => const AddHealthRecordScreen());
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Record'),
              ),
          ],
        ),
      ),
    );
  }

  /// Build list view for mobile
  Widget _buildListView(List<MedicalDocument> documents) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: documents.length,
      itemBuilder: (context, index) {
        final document = documents[index];
        return _buildDocumentCard(document);
      },
    );
  }

  /// Build grid view for larger screens
  Widget _buildGridView(List<MedicalDocument> documents) {
    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
      ),
      itemCount: documents.length,
      itemBuilder: (context, index) {
        final document = documents[index];
        return _buildDocumentCard(document);
      },
    );
  }

  /// Build document card
  Widget _buildDocumentCard(MedicalDocument document) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final color = _getDocumentTypeColor(document.documentType);
    final icon = _getDocumentTypeIcon(document.documentType);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Get.to(() => HealthRecordDetailScreen(document: document));
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Document type icon
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 12),

                  // Document info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          document.title,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDocumentType(document.documentType),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: color,
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                      ],
                    ),
                  ),

                  // More options
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () {
                      _showDocumentOptions(context, document);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Additional info
              if (document.doctorName != null) ...[
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        document.doctorName!,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],

              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    dateFormat.format(document.documentDate),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show sort options
  void _showSortOptions(
    BuildContext context,
    HealthRecordProvider provider,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sort By',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Date (Newest First)'),
              onTap: () {
                // TODO: Implement sorting
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Date (Oldest First)'),
              onTap: () {
                // TODO: Implement sorting
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.sort_by_alpha),
              title: const Text('Title (A-Z)'),
              onTap: () {
                // TODO: Implement sorting
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.category),
              title: const Text('Type'),
              onTap: () {
                // TODO: Implement sorting
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Show document options
  void _showDocumentOptions(BuildContext context, MedicalDocument document) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.visibility),
              title: const Text('View'),
              onTap: () {
                Navigator.pop(context);
                Get.to(() => HealthRecordDetailScreen(document: document));
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement sharing
              },
            ),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Download'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement download
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppColors.error),
              title: const Text(
                'Delete',
                style: TextStyle(color: AppColors.error),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context, document);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Confirm document deletion
  void _confirmDelete(BuildContext context, MedicalDocument document) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text(
          'Are you sure you want to delete "${document.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final provider = context.read<HealthRecordProvider>();
              await provider.deleteHealthRecord(document.id!);

              if (context.mounted) {
                Get.snackbar(
                  'Deleted',
                  'Document deleted successfully',
                  backgroundColor: AppColors.success,
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
