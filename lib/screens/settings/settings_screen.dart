import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../profile/edit_profile_screen.dart';
import '../profile/health_calculator_screen.dart';
import '../profile/change_password_screen.dart';
import 'language_screen.dart';
import '../auth/login_screen.dart';

/// Unified Settings screen with profile and all settings options
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final languageProvider = context.watch<LanguageProvider>();
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Compact App bar with profile
          SliverAppBar(
            expandedHeight: 120,
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
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
                    child: Row(
                      children: [
                        // Profile picture
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.white,
                          backgroundImage: user?.profileImageUrl != null
                              ? NetworkImage(user!.profileImageUrl!)
                              : null,
                          child: user?.profileImageUrl == null
                              ? const Icon(
                                  Icons.person,
                                  size: 30,
                                  color: AppColors.primary,
                                )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        // User info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                user?.fullName ?? languageProvider.tr('user'),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user?.email ?? '',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Colors.white70,
                                    ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Profile Section
                _buildSectionTitle(context, languageProvider.tr('profile')),
                const SizedBox(height: 8),
                _buildMenuCard(
                  context,
                  children: [
                    _buildMenuItem(
                      context,
                      icon: Icons.person_outline,
                      title: languageProvider.tr('edit_profile'),
                      subtitle: languageProvider.tr('update_personal_info'),
                      onTap: () {
                        Get.to(() => const EditProfileScreen());
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Security Section
                _buildSectionTitle(context, languageProvider.tr('security')),
                const SizedBox(height: 8),
                _buildMenuCard(
                  context,
                  children: [
                    _buildMenuItem(
                      context,
                      icon: Icons.lock_outline,
                      title: languageProvider.tr('change_password'),
                      subtitle: languageProvider.tr('update_password'),
                      onTap: () {
                        Get.to(() => const ChangePasswordScreen());
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Preferences Section
                _buildSectionTitle(context, languageProvider.tr('preferences')),
                const SizedBox(height: 8),
                _buildMenuCard(
                  context,
                  children: [
                    _buildMenuItem(
                      context,
                      icon: Icons.language,
                      title: languageProvider.tr('language'),
                      subtitle: languageProvider.currentLanguage.nativeName,
                      onTap: () {
                        Get.to(() => const LanguageScreen());
                      },
                      trailing: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // About Section
                _buildSectionTitle(context, languageProvider.tr('about')),
                const SizedBox(height: 8),
                _buildMenuCard(
                  context,
                  children: [
                    _buildMenuItem(
                      context,
                      icon: Icons.info_outline,
                      title: languageProvider.tr('about_app'),
                      subtitle: languageProvider.tr('version') + ' 1.0.0',
                      onTap: () {
                        _showAboutDialog(context, languageProvider);
                      },
                    ),
                    const Divider(height: 1),
                    _buildMenuItem(
                      context,
                      icon: Icons.help_outline,
                      title: languageProvider.tr('help_support'),
                      subtitle: languageProvider.tr('contact_us'),
                      onTap: () {
                        _showHelpDialog(context, languageProvider);
                      },
                    ),
                    const Divider(height: 1),
                    _buildMenuItem(
                      context,
                      icon: Icons.privacy_tip_outlined,
                      title: languageProvider.tr('privacy_policy'),
                      subtitle: languageProvider.tr('data_protection'),
                      onTap: () {
                        _showPrivacyDialog(context, languageProvider);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Logout Button
                ElevatedButton.icon(
                  onPressed: () {
                    _showLogoutDialog(context, authProvider, languageProvider);
                  },
                  icon: const Icon(Icons.logout),
                  label: Text(languageProvider.tr('logout')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 16),

                // App version footer
                Center(
                  child: Text(
                    'mySahara ${languageProvider.tr("version")} 1.0.0',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ),
                const SizedBox(height: 16),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  /// Build section title
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
    );
  }

  /// Build menu card container
  Widget _buildMenuCard(BuildContext context, {required List<Widget> children}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  /// Build menu item
  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 24,
          color: AppColors.primary,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            )
          : null,
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _showAboutDialog(BuildContext context, LanguageProvider languageProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(languageProvider.tr('about_app')),
        content: Text(languageProvider.tr('about_description')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(languageProvider.tr('ok')),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context, LanguageProvider languageProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(languageProvider.tr('help_support')),
        content: Text(languageProvider.tr('help_description')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(languageProvider.tr('ok')),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context, LanguageProvider languageProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(languageProvider.tr('privacy_policy')),
        content: SingleChildScrollView(
          child: Text(languageProvider.tr('privacy_description')),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(languageProvider.tr('ok')),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(
    BuildContext context,
    AuthProvider authProvider,
    LanguageProvider languageProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(languageProvider.tr('logout')),
        content: Text(languageProvider.tr('logout_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(languageProvider.tr('cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              authProvider.signOut();
              Get.offAll(() => const LoginScreen());
            },
            child: Text(languageProvider.tr('logout')),
          ),
        ],
      ),
    );
  }
}
