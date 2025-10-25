import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/family_provider.dart';
import '../../providers/health_record_provider.dart';
import '../../services/ai_service.dart';
import '../../screens/ai_chat/ai_chat_screen.dart';

/// AI-Powered Family Health Insights Widget
/// Shows personalized health insights and recommendations for the entire family
class FamilyHealthInsightsWidget extends StatefulWidget {
  const FamilyHealthInsightsWidget({super.key});

  @override
  State<FamilyHealthInsightsWidget> createState() => _FamilyHealthInsightsWidgetState();
}

class _FamilyHealthInsightsWidgetState extends State<FamilyHealthInsightsWidget> {
  String? _insights;
  bool _isLoading = false;
  DateTime? _lastUpdated;

  @override
  void initState() {
    super.initState();
    _loadInsights();
  }

  Future<void> _loadInsights() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final familyProvider = context.read<FamilyProvider>();
      final healthRecordProvider = context.read<HealthRecordProvider>();

      // Build user context
      final userContext = {
        'language': 'en', // Can be detected from user profile
        'familySize': familyProvider.familyMembers.length,
        'documentsCount': healthRecordProvider.healthRecords.length,
      };

      // Build today's metrics
      final todayMetrics = {
        'Family Members': familyProvider.familyMembers.length,
        'Health Records': healthRecordProvider.healthRecords.length,
        'Dashboard Access': DateTime.now().toString().split(' ')[0],
      };

      // Get AI insights
      final insights = await AIService.getDailyHealthInsights(
        userContext: userContext,
        todayMetrics: todayMetrics,
      );

      if (mounted) {
        setState(() {
          _insights = insights;
          _lastUpdated = DateTime.now();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading insights: $e');
      if (mounted) {
        setState(() {
          _insights = null;
          _isLoading = false;
        });
      }
    }
  }

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
              AppColors.healthBlue.withOpacity(0.05),
              AppColors.healthPurple.withOpacity(0.05),
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
                    gradient: LinearGradient(
                      colors: [
                        AppColors.healthBlue,
                        AppColors.healthPurple,
                      ],
                    ),
                  ),
                  child: const Icon(
                    Icons.psychology,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Health Insights',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (_lastUpdated != null)
                        Text(
                          'Updated ${_getTimeAgo(_lastUpdated!)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.refresh,
                    color: AppColors.primary,
                  ),
                  onPressed: _isLoading ? null : _loadInsights,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Insights content
            if (_isLoading)
              _buildLoadingState()
            else if (_insights != null)
              _buildInsightsContent()
            else
              _buildEmptyState(),

            const SizedBox(height: 16),

            // Action button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Get.to(() => const AiChatScreen()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text(
                  'Ask AI Doctor',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          const SizedBox(height: 12),
          Text(
            'Analyzing your family health data...',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsContent() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb,
                color: AppColors.warning,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Today\'s Recommendations',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _insights!,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(
            Icons.info_outline,
            color: AppColors.textSecondary,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'Get personalized health insights',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Our AI will analyze your family\'s health data\nand provide tailored recommendations',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
