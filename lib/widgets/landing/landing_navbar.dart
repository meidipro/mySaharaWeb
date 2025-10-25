import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../../constants/app_colors.dart';

/// Landing page navigation bar
class LandingNavbar extends StatelessWidget {
  final bool isScrolled;
  final VoidCallback onLoginTap;
  final VoidCallback onSignupTap;

  const LandingNavbar({
    super.key,
    required this.isScrolled,
    required this.onLoginTap,
    required this.onSignupTap,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 70,
      decoration: BoxDecoration(
        color: isScrolled ? Colors.white : Colors.transparent,
        boxShadow: isScrolled
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 48),
        child: Row(
          children: [
            // Logo
            Row(
              children: [
                Icon(
                  Icons.health_and_safety,
                  color: AppColors.primary,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Sahara',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isScrolled ? AppColors.primary : Colors.white,
                      ),
                    ),
                    Text(
                      'For You & Your Family',
                      style: TextStyle(
                        fontSize: 10,
                        color: (isScrolled ? AppColors.primary : Colors.white).withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const Spacer(),

            // Navigation Links (Desktop only)
            if (!isMobile) ...[
              _NavLink(
                text: 'Features',
                isScrolled: isScrolled,
                onTap: () {
                  // Scroll to features section
                },
              ),
              const SizedBox(width: 32),
              _NavLink(
                text: 'How It Works',
                isScrolled: isScrolled,
                onTap: () {
                  // Scroll to how it works section
                },
              ),
              const SizedBox(width: 32),
              _NavLink(
                text: 'Download',
                isScrolled: isScrolled,
                onTap: () {
                  // Scroll to download section
                },
              ),
              const SizedBox(width: 32),
            ],

            // Auth Buttons
            if (!isMobile) ...[
              TextButton(
                onPressed: onLoginTap,
                child: Text(
                  'Login',
                  style: TextStyle(
                    color: isScrolled ? AppColors.primary : Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: onSignupTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Get Started'),
              ),
            ],

            // Mobile Menu Button
            if (isMobile)
              IconButton(
                icon: Icon(
                  Icons.menu,
                  color: isScrolled ? AppColors.primary : Colors.white,
                ),
                onPressed: () {
                  // Show mobile menu
                  _showMobileMenu(context);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showMobileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Features'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('How It Works'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Download'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              title: const Text('Login'),
              onTap: () {
                Navigator.pop(context);
                onLoginTap();
              },
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                onSignupTap();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('Get Started'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavLink extends StatelessWidget {
  final String text;
  final bool isScrolled;
  final VoidCallback onTap;

  const _NavLink({
    required this.text,
    required this.isScrolled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Text(
        text,
        style: TextStyle(
          color: isScrolled ? AppColors.textPrimary : Colors.white,
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
      ),
    );
  }
}
