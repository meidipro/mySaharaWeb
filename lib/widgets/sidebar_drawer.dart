import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/medication/medication_management_screen.dart';
import '../screens/appointment/appointment_management_screen.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';

class SidebarDrawer extends StatelessWidget {
  const SidebarDrawer({super.key});

  /// Show logout confirmation dialog
  void _showLogoutConfirmation(BuildContext context, AuthProvider authProvider, LanguageProvider languageProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(languageProvider.tr('logout')),
          content: Text(languageProvider.tr('logout_confirmation') ?? 'Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: Text(languageProvider.tr('cancel') ?? 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close dialog
                await authProvider.signOut();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              child: Text(languageProvider.tr('logout')),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final languageProvider = context.watch<LanguageProvider>();
    final user = authProvider.user;

    return Drawer(
      child: Column(
        children: [
          // Compact Header
          Container(
            height: 120,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.secondary],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white,
                      backgroundImage: user?.profileImageUrl != null
                          ? NetworkImage(user!.profileImageUrl!)
                          : null,
                      child: user?.profileImageUrl == null
                          ? const Icon(
                              Icons.person,
                              size: 32,
                              color: AppColors.primary,
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            user?.fullName ?? languageProvider.tr('user'),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? '',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white70,
                            ),
                            maxLines: 1,
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

          // Menu Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _DrawerItem(
                  icon: Icons.medication,
                  title: 'Family Medication Tracking',
                  subtitle: 'Track medications for everyone',
                  onTap: () {
                    Navigator.pop(context);
                    Get.to(() => const MedicationManagementScreen());
                  },
                ),
                const Divider(),
                _DrawerItem(
                  icon: Icons.calendar_month,
                  title: 'Family Appointments',
                  subtitle: 'Manage appointments for all members',
                  onTap: () {
                    Navigator.pop(context);
                    Get.to(() => const AppointmentManagementScreen());
                  },
                ),
                const Divider(),
                _DrawerItem(
                  icon: Icons.settings,
                  title: languageProvider.tr('settings'),
                  subtitle: languageProvider.tr('profile_preferences'),
                  onTap: () {
                    Navigator.pop(context);
                    Get.to(() => const SettingsScreen());
                  },
                ),
                const Divider(),
                _DrawerItem(
                  icon: Icons.logout,
                  title: languageProvider.tr('logout'),
                  onTap: () {
                    Navigator.pop(context);
                    _showLogoutConfirmation(context, authProvider, languageProvider);
                  },
                  textColor: AppColors.error,
                ),

              ],
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Divider(),
                Text(
                  'My Sahara',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'For You & Your Family',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${languageProvider.tr("version")} 1.1.0',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[500],
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

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? textColor;

  const _DrawerItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: textColor ?? AppColors.primary,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            )
          : null,
      onTap: onTap,
      hoverColor: AppColors.primary.withOpacity(0.1),
    );
  }
}
