import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../providers/medical_timeline_provider.dart';
import '../../screens/timeline/medical_timeline_screen.dart';

/// Family Health Activity Widget - Shows recent health activities across the family
class FamilyHealthActivityWidget extends StatelessWidget {
  const FamilyHealthActivityWidget({super.key});

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
              AppColors.healthOrange.withOpacity(0.05),
              AppColors.healthRed.withOpacity(0.05),
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
                    color: AppColors.healthOrange.withOpacity(0.2),
                  ),
                  child: Icon(
                    Icons.timeline,
                    color: AppColors.healthOrange,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Recent Health Activity',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Get.to(() => const MedicalTimelineScreen()),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Recent activities
            Consumer<MedicalTimelineProvider>(
              builder: (context, timelineProvider, child) {
                final recentEvents = timelineProvider.timelineEvents.take(3).toList();

                if (timelineProvider.isLoading) {
                  return _buildLoadingState();
                } else if (recentEvents.isEmpty) {
                  return _buildEmptyState();
                } else {
                  return _buildActivitiesList(recentEvents);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.healthOrange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.healthOrange.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.history_outlined,
            size: 40,
            color: AppColors.healthOrange,
          ),
          const SizedBox(height: 12),
          Text(
            'No Health Activity Yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start tracking your family\'s health journey',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitiesList(List events) {
    return Column(
      children: events.map((event) => _buildActivityItem(event)).toList(),
    );
  }

  Widget _buildActivityItem(dynamic event) {
    final eventType = event.eventType as String? ?? 'event';
    final description = event.description as String? ?? 'Health event';
    final createdAt = event.createdAt as DateTime?;
    final severity = event.severity as String?;

    final icon = _getEventIcon(eventType);
    final color = _getEventColor(eventType, severity);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.1),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatEventType(eventType),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Time
          if (createdAt != null)
            Text(
              _getTimeAgo(createdAt),
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textHint,
              ),
            ),
        ],
      ),
    );
  }

  IconData _getEventIcon(String eventType) {
    switch (eventType.toLowerCase()) {
      case 'doctor_visit':
      case 'appointment':
        return Icons.local_hospital;
      case 'medication':
        return Icons.medication;
      case 'test':
      case 'lab_test':
        return Icons.science;
      case 'vaccination':
      case 'vaccine':
        return Icons.vaccines;
      case 'surgery':
        return Icons.healing;
      case 'symptom':
        return Icons.sick;
      case 'allergy':
        return Icons.warning;
      default:
        return Icons.event_note;
    }
  }

  Color _getEventColor(String eventType, String? severity) {
    if (severity != null) {
      switch (severity.toLowerCase()) {
        case 'high':
        case 'severe':
          return AppColors.error;
        case 'medium':
        case 'moderate':
          return AppColors.warning;
        case 'low':
        case 'mild':
          return AppColors.success;
      }
    }

    switch (eventType.toLowerCase()) {
      case 'doctor_visit':
      case 'appointment':
        return AppColors.healthPurple;
      case 'medication':
        return AppColors.healthGreen;
      case 'test':
      case 'lab_test':
        return AppColors.healthBlue;
      case 'vaccination':
      case 'vaccine':
        return AppColors.success;
      case 'surgery':
        return AppColors.error;
      case 'symptom':
        return AppColors.warning;
      case 'allergy':
        return AppColors.healthRed;
      default:
        return AppColors.healthOrange;
    }
  }

  String _formatEventType(String eventType) {
    return eventType
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}w';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()}mo';
    } else {
      return '${(difference.inDays / 365).floor()}y';
    }
  }
}
