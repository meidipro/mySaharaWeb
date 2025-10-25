import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../../constants/app_colors.dart';
import '../../providers/family_provider.dart';
import '../../providers/health_record_provider.dart';

/// Family Health Score Widget - Gamified health tracking
class FamilyHealthScoreWidget extends StatelessWidget {
  const FamilyHealthScoreWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final familyProvider = context.watch<FamilyProvider>();
    final healthRecordProvider = context.watch<HealthRecordProvider>();

    // Calculate family health score (0-100)
    final score = _calculateFamilyHealthScore(
      familyProvider.familyMembers.length,
      healthRecordProvider.healthRecords.length,
    );

    final scoreColor = _getScoreColor(score);
    final scoreLabel = _getScoreLabel(score);
    final nextGoal = _getNextGoal(score);

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
              scoreColor.withOpacity(0.1),
              scoreColor.withOpacity(0.05),
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
                    color: scoreColor.withOpacity(0.2),
                  ),
                  child: Icon(
                    Icons.health_and_safety,
                    color: scoreColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Family Health Score',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      scoreLabel,
                      style: TextStyle(
                        fontSize: 13,
                        color: scoreColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                _buildScoreBadge(score, scoreColor),
              ],
            ),
            const SizedBox(height: 20),

            // Progress bar
            _buildProgressBar(score, scoreColor),
            const SizedBox(height: 16),

            // Next goal
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.stars, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      nextGoal,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreBadge(int score, Color color) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withOpacity(0.7)],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              score.toString(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Text(
              '/100',
              style: TextStyle(
                fontSize: 10,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(int score, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Overall Health Progress',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$score%',
              style: TextStyle(
                fontSize: 13,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: score / 100,
            minHeight: 12,
            backgroundColor: AppColors.textSecondary.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  int _calculateFamilyHealthScore(int familyCount, int documentCount) {
    // Base score calculation:
    // - Having family members: 40 points (10 per member, max 40)
    // - Having health records: 30 points (5 per document, max 30)
    // - Base participation: 30 points

    int score = 30; // Base score for signing up

    // Family members (10 points each, max 40)
    score += math.min(familyCount * 10, 40);

    // Health records (5 points each, max 30)
    score += math.min(documentCount * 5, 30);

    return math.min(score, 100);
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return AppColors.success;
    if (score >= 60) return AppColors.healthGreen;
    if (score >= 40) return AppColors.warning;
    return AppColors.healthOrange;
  }

  String _getScoreLabel(int score) {
    if (score >= 80) return 'Excellent! 🌟';
    if (score >= 60) return 'Great Progress! 💪';
    if (score >= 40) return 'Getting Started 🚀';
    return 'Let\'s Begin! ✨';
  }

  String _getNextGoal(int score) {
    if (score < 40) {
      return 'Next Goal: Add 2 more family members to reach 40 points!';
    } else if (score < 60) {
      return 'Next Goal: Upload 3 more health records to reach 60 points!';
    } else if (score < 80) {
      return 'Next Goal: Complete all family profiles to reach 80 points!';
    } else if (score < 100) {
      return 'Next Goal: Add vaccination records to reach 100 points!';
    } else {
      return 'Perfect Score! You\'re protecting your family excellently! 🏆';
    }
  }
}
