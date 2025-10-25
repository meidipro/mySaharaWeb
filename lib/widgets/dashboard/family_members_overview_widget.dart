import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/family_provider.dart';
import '../../screens/family/family_dashboard_screen.dart';
import '../../screens/family/add_family_member_screen.dart';

/// Family Members Overview Widget - Quick access to family profiles
class FamilyMembersOverviewWidget extends StatelessWidget {
  const FamilyMembersOverviewWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final familyProvider = context.watch<FamilyProvider>();
    final familyMembers = familyProvider.familyMembers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.family_restroom, color: AppColors.primary, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Your Family',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            if (familyMembers.isNotEmpty)
              TextButton(
                onPressed: () => Get.to(() => const FamilyDashboardScreen()),
                child: const Text('View All'),
              ),
          ],
        ),
        const SizedBox(height: 16),

        // Family members grid or empty state
        if (familyMembers.isEmpty)
          _buildEmptyState(context)
        else
          _buildFamilyMembersGrid(context, familyMembers),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.05),
            AppColors.secondary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 2,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(0.1),
            ),
            child: Icon(
              Icons.group_add,
              size: 48,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Start Building Your\nFamily Health Hub',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Add your parents, children, or anyone whose\nhealth you want to track and protect.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Get.to(() => const AddFamilyMemberScreen()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.person_add),
            label: const Text(
              'Add Your First Family Member',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyMembersGrid(BuildContext context, List familyMembers) {
    // Show up to 4 family members + "Add More" card
    final displayCount = familyMembers.length > 3 ? 3 : familyMembers.length;
    final members = familyMembers.take(displayCount).toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: members.length + 1, // +1 for "Add More" card
      itemBuilder: (context, index) {
        if (index == members.length) {
          return _buildAddMoreCard(context);
        }
        return _buildFamilyMemberCard(context, members[index]);
      },
    );
  }

  Widget _buildFamilyMemberCard(BuildContext context, dynamic member) {
    final String name = member.fullName ?? 'Unknown';
    final String relationship = member.relationship ?? '';
    final String? gender = member.gender;

    // Choose icon based on relationship and gender
    IconData icon = Icons.person;
    Color iconColor = AppColors.primary;

    if (relationship.toLowerCase() == 'me') {
      icon = Icons.account_circle;
      iconColor = AppColors.healthBlue;
    } else if (relationship.toLowerCase().contains('mother') ||
               relationship.toLowerCase().contains('grandmother')) {
      icon = Icons.elderly_woman;
      iconColor = AppColors.healthPink;
    } else if (relationship.toLowerCase().contains('father') ||
               relationship.toLowerCase().contains('grandfather')) {
      icon = Icons.elderly;
      iconColor = AppColors.healthPurple;
    } else if (relationship.toLowerCase().contains('child') ||
               relationship.toLowerCase().contains('son') ||
               relationship.toLowerCase().contains('daughter')) {
      icon = Icons.child_care;
      iconColor = AppColors.healthOrange;
    } else if (gender?.toLowerCase() == 'female') {
      icon = Icons.face_3;
      iconColor = AppColors.healthPink;
    } else if (gender?.toLowerCase() == 'male') {
      icon = Icons.face;
      iconColor = AppColors.healthBlue;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // Navigate to family member detail
          Get.to(() => const FamilyDashboardScreen());
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: iconColor.withOpacity(0.1),
                ),
                child: Icon(icon, color: iconColor, size: 32),
              ),
              const SizedBox(height: 8),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                relationship,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddMoreCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: AppColors.primary.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () => Get.to(() => const AddFamilyMemberScreen()),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.1),
              ),
              child: Icon(
                Icons.person_add,
                color: AppColors.primary,
                size: 32,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add Member',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
