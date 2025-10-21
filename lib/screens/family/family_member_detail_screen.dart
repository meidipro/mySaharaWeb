import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../constants/app_colors.dart';
import '../../models/family_member.dart';
import '../../providers/family_provider.dart';
import 'add_family_member_screen.dart';

class FamilyMemberDetailScreen extends StatelessWidget {
  final String memberId;
  final FamilyMemberWithProfile? memberProfile;

  const FamilyMemberDetailScreen({
    super.key,
    required this.memberId,
    this.memberProfile,
  });

  @override
  Widget build(BuildContext context) {
    final member = memberProfile?.member;
    final isLinked = member?.linkedUserId != null && member!.linkedUserId!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(member?.fullName ?? 'Family Member'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              if (member != null) {
                Get.to(() => AddFamilyMemberScreen(member: member));
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: member == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Card
                  _buildHeaderCard(context, member, isLinked),

                  // Basic Information
                  _buildSection(
                    context,
                    title: 'Basic Information',
                    children: [
                      if (member.dateOfBirth != null)
                        _buildInfoTile(
                          context,
                          icon: Icons.cake,
                          label: 'Date of Birth',
                          value: DateFormat('MMM dd, yyyy')
                              .format(DateTime.parse(member.dateOfBirth!)),
                        ),
                      if (member.gender != null)
                        _buildInfoTile(
                          context,
                          icon: Icons.wc,
                          label: 'Gender',
                          value: member.gender!,
                        ),
                      if (member.bloodGroup != null)
                        _buildInfoTile(
                          context,
                          icon: Icons.bloodtype,
                          label: 'Blood Group',
                          value: member.bloodGroup!,
                        ),
                      _buildInfoTile(
                        context,
                        icon: Icons.family_restroom,
                        label: 'Relationship',
                        value: member.relationship,
                      ),
                      if (memberProfile?.email != null)
                        _buildInfoTile(
                          context,
                          icon: Icons.email,
                          label: 'Email',
                          value: memberProfile!.email!,
                        ),
                    ],
                  ),

                  // Medical Information
                  if (member.chronicDiseases != null ||
                      member.medications != null ||
                      member.allergies != null)
                    _buildSection(
                      context,
                      title: 'Medical Information',
                      children: [
                        if (member.chronicDiseases != null)
                          _buildInfoTile(
                            context,
                            icon: Icons.medical_services,
                            label: 'Chronic Diseases',
                            value: member.chronicDiseases!,
                            isMultiline: true,
                          ),
                        if (member.medications != null)
                          _buildInfoTile(
                            context,
                            icon: Icons.medication,
                            label: 'Current Medications',
                            value: member.medications!,
                            isMultiline: true,
                          ),
                        if (member.allergies != null)
                          _buildInfoTile(
                            context,
                            icon: Icons.warning_amber,
                            label: 'Allergies',
                            value: member.allergies!,
                            isMultiline: true,
                            color: AppColors.error,
                          ),
                      ],
                    ),

                  // Health Summary (for linked accounts)
                  if (isLinked && memberProfile != null)
                    _buildSection(
                      context,
                      title: 'Health Summary',
                      children: [
                        _buildStatCard(
                          context,
                          icon: Icons.description,
                          label: 'Medical Documents',
                          value: '${memberProfile?.documentCount ?? 0}',
                          color: AppColors.healthBlue,
                        ),
                        _buildStatCard(
                          context,
                          icon: Icons.timeline,
                          label: 'Timeline Events',
                          value: '${memberProfile?.timelineEventCount ?? 0}',
                          color: AppColors.healthGreen,
                        ),
                        if (memberProfile?.recentDiseases != null &&
                            memberProfile!.recentDiseases!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Recent Conditions',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: (memberProfile?.recentDiseases ?? []).map((disease) {
                                    return Chip(
                                      label: Text(disease),
                                      backgroundColor: AppColors.healthRed.withOpacity(0.1),
                                      labelStyle: TextStyle(
                                        color: AppColors.healthRed,
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),

                  // Notes
                  if (member.notes != null)
                    _buildSection(
                      context,
                      title: 'Additional Notes',
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            member.notes!,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),

                  // Account Link Status
                  _buildSection(
                    context,
                    title: 'Account Status',
                    children: [
                      ListTile(
                        leading: Icon(
                          isLinked ? Icons.link : Icons.link_off,
                          color: isLinked ? AppColors.success : AppColors.textSecondary,
                        ),
                        title: Text(
                          isLinked
                              ? 'Connected to App Account'
                              : 'Not Connected to App',
                        ),
                        subtitle: Text(
                          isLinked
                              ? 'This family member has their own account and you can view their health summary'
                              : 'This family member does not have an app account yet',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, FamilyMember member, bool isLinked) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: AppColors.textWhite.withOpacity(0.2),
            backgroundImage: member.profileImageUrl != null
                ? NetworkImage(member.profileImageUrl!)
                : null,
            child: member.profileImageUrl == null
                ? Text(
                    member.fullName[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textWhite,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            member.fullName,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.textWhite,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.textWhite.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              member.relationship,
              style: const TextStyle(
                color: AppColors.textWhite,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (isLinked) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.link, size: 16, color: AppColors.textWhite),
                  SizedBox(width: 4),
                  Text(
                    'Linked Account',
                    style: TextStyle(
                      color: AppColors.textWhite,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildInfoTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    bool isMultiline = false,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.primary),
      title: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
      ),
      subtitle: Text(
        value,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
      ),
      isThreeLine: isMultiline,
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Family Member'),
        content: Text(
          'Are you sure you want to delete ${memberProfile?.member.fullName ?? 'this family member'}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              // Show loading
              Get.dialog(
                const Center(child: CircularProgressIndicator()),
                barrierDismissible: false,
              );

              final familyProvider = context.read<FamilyProvider>();
              final success = await familyProvider.deleteFamilyMember(memberId);

              Get.back(); // Close loading

              if (success) {
                Get.back(); // Close detail screen
                Get.snackbar(
                  'Deleted',
                  'Family member deleted successfully',
                  backgroundColor: AppColors.success,
                  colorText: AppColors.textWhite,
                  snackPosition: SnackPosition.BOTTOM,
                );
                familyProvider.loadFamilyMembersWithProfile();
              } else {
                Get.snackbar(
                  'Error',
                  familyProvider.errorMessage ?? 'Failed to delete family member',
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
