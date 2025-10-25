import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import '../../providers/family_provider.dart';
import '../../providers/health_record_provider.dart';
import '../../providers/medical_timeline_provider.dart';
import '../../screens/family/family_dashboard_screen.dart';
import '../../screens/health_records/health_records_list_screen.dart';
import '../../screens/timeline/medical_timeline_screen.dart';

/// Smart Search Bar Widget - Quick search across family, records, and events
class SmartSearchBarWidget extends StatefulWidget {
  const SmartSearchBarWidget({super.key});

  @override
  State<SmartSearchBarWidget> createState() => _SmartSearchBarWidgetState();
}

class _SmartSearchBarWidgetState extends State<SmartSearchBarWidget> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  List<SearchResult> _searchResults = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    final familyProvider = context.read<FamilyProvider>();
    final healthRecordProvider = context.read<HealthRecordProvider>();
    final timelineProvider = context.read<MedicalTimelineProvider>();

    final results = <SearchResult>[];
    final lowerQuery = query.toLowerCase();

    // Search family members
    for (var member in familyProvider.familyMembers) {
      final name = (member.fullName as String? ?? '').toLowerCase();
      final relationship = (member.relationship as String? ?? '').toLowerCase();

      if (name.contains(lowerQuery) || relationship.contains(lowerQuery)) {
        results.add(SearchResult(
          title: member.fullName ?? 'Unknown',
          subtitle: member.relationship ?? '',
          type: SearchResultType.family,
          icon: Icons.person,
          color: AppColors.healthBlue,
          onTap: () => Get.to(() => const FamilyDashboardScreen()),
        ));
      }
    }

    // Search health records
    for (var record in healthRecordProvider.healthRecords) {
      final title = (record.title as String? ?? '').toLowerCase();
      final description = (record.description as String? ?? '').toLowerCase();

      if (title.contains(lowerQuery) || description.contains(lowerQuery)) {
        results.add(SearchResult(
          title: record.title ?? 'Health Record',
          subtitle: record.description ?? '',
          type: SearchResultType.record,
          icon: Icons.description,
          color: AppColors.healthGreen,
          onTap: () => Get.to(() => const HealthRecordsListScreen()),
        ));
      }
    }

    // Search timeline events
    for (var event in timelineProvider.timelineEvents) {
      final eventType = (event.eventType as String? ?? '').toLowerCase();
      final notes = (event.notes as String? ?? '').toLowerCase();
      final disease = (event.disease as String? ?? '').toLowerCase();
      final symptoms = (event.symptoms as String? ?? '').toLowerCase();

      if (eventType.contains(lowerQuery) ||
          notes.contains(lowerQuery) ||
          disease.contains(lowerQuery) ||
          symptoms.contains(lowerQuery)) {
        final subtitle = event.disease ?? event.symptoms ?? event.notes ?? eventType;
        results.add(SearchResult(
          title: _formatEventType(event.eventType as String? ?? ''),
          subtitle: subtitle,
          type: SearchResultType.event,
          icon: Icons.timeline,
          color: AppColors.healthOrange,
          onTap: () => Get.to(() => const MedicalTimelineScreen()),
        ));
      }
    }

    setState(() {
      _searchResults = results.take(5).toList(); // Limit to 5 results
      _isSearching = false;
    });
  }

  String _formatEventType(String eventType) {
    return eventType
        .split('_')
        .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Search input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: TextField(
              controller: _searchController,
              onChanged: _performSearch,
              decoration: InputDecoration(
                hintText: 'Search family, records, events...',
                hintStyle: TextStyle(color: AppColors.textHint),
                prefixIcon: Icon(Icons.search, color: AppColors.primary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: AppColors.textSecondary),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // Search results
          if (_isSearching)
            Padding(
              padding: const EdgeInsets.all(20),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            )
          else if (_searchResults.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _searchResults.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: AppColors.divider,
                ),
                itemBuilder: (context, index) {
                  final result = _searchResults[index];
                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: result.color.withOpacity(0.1),
                      ),
                      child: Icon(result.icon, color: result.color, size: 20),
                    ),
                    title: Text(
                      result.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      result.subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: AppColors.textHint,
                    ),
                    onTap: () {
                      result.onTap();
                      _searchController.clear();
                      _performSearch('');
                    },
                  );
                },
              ),
            )
          else if (_searchController.text.isNotEmpty && _searchResults.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.search_off,
                    size: 48,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No results found',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Try a different search term',
                    style: TextStyle(
                      fontSize: 13,
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
}

enum SearchResultType { family, record, event }

class SearchResult {
  final String title;
  final String subtitle;
  final SearchResultType type;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  SearchResult({
    required this.title,
    required this.subtitle,
    required this.type,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}
