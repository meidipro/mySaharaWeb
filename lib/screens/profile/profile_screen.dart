import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import 'edit_profile_screen.dart';

/// Profile screen to view user information
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.user;

          return CustomScrollView(
            slivers: [
              // App bar with gradient
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textWhite,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.primary, AppColors.secondary],
                      ),
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          // Profile picture
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.white,
                            backgroundImage: user?.profileImageUrl != null
                                ? NetworkImage(user!.profileImageUrl!)
                                : null,
                            child: user?.profileImageUrl == null
                                ? const Icon(
                                    Icons.person,
                                    size: 50,
                                    color: AppColors.primary,
                                  )
                                : null,
                          ),
                          const SizedBox(height: 12),
                          // User name
                          Text(
                            user?.fullName ?? 'User',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          // User email
                          Text(
                            user?.email ?? '',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.white70,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      Get.to(() => const EditProfileScreen());
                    },
                    tooltip: 'Edit Profile',
                  ),
                ],
              ),

              // Content
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Personal Information Section
                    _buildSectionTitle(context, 'Personal Information'),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      context,
                      children: [
                        _buildInfoRow(
                          context,
                          icon: Icons.person_outline,
                          label: 'Full Name',
                          value: user?.fullName ?? 'Not set',
                        ),
                        const Divider(),
                        _buildInfoRow(
                          context,
                          icon: Icons.email_outlined,
                          label: 'Email',
                          value: user?.email ?? 'Not set',
                        ),
                        const Divider(),
                        _buildInfoRow(
                          context,
                          icon: Icons.phone_outlined,
                          label: 'Phone Number',
                          value: user?.phoneNumber ?? 'Not set',
                        ),
                        const Divider(),
                        _buildInfoRow(
                          context,
                          icon: Icons.cake_outlined,
                          label: 'Date of Birth',
                          value: user?.dateOfBirth != null
                              ? DateFormat('MMM dd, yyyy').format(
                                  DateTime.parse(user!.dateOfBirth!),
                                )
                              : 'Not set',
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Health Information Section
                    _buildSectionTitle(context, 'Health Information'),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      context,
                      children: [
                        _buildInfoRow(
                          context,
                          icon: Icons.wc_outlined,
                          label: 'Gender',
                          value: user?.gender != null
                              ? user!.gender![0].toUpperCase() +
                                  user.gender!.substring(1)
                              : 'Not set',
                        ),
                        const Divider(),
                        _buildInfoRow(
                          context,
                          icon: Icons.bloodtype_outlined,
                          label: 'Blood Group',
                          value: user?.bloodGroup ?? 'Not set',
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Account Information Section
                    _buildSectionTitle(context, 'Account Information'),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      context,
                      children: [
                        _buildInfoRow(
                          context,
                          icon: Icons.calendar_today_outlined,
                          label: 'Member Since',
                          value: user?.createdAt != null
                              ? DateFormat('MMM dd, yyyy').format(user!.createdAt!)
                              : 'Not available',
                        ),
                        const Divider(),
                        _buildInfoRow(
                          context,
                          icon: Icons.update_outlined,
                          label: 'Last Updated',
                          value: user?.updatedAt != null
                              ? DateFormat('MMM dd, yyyy').format(user!.updatedAt!)
                              : 'Not available',
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Edit Profile Button
                    ElevatedButton.icon(
                      onPressed: () {
                        Get.to(() => const EditProfileScreen());
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit Profile'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Build section title
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
    );
  }

  /// Build info card container
  Widget _buildInfoCard(BuildContext context, {required List<Widget> children}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  /// Build info row
  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
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
