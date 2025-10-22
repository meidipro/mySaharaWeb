import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../../constants/app_colors.dart';
import '../../screens/auth/signup_screen.dart';

/// Hero section with gradient background and call-to-action
class HeroSection extends StatelessWidget {
  const HeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;
    final isTablet = ResponsiveBreakpoints.of(context).isTablet;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
            AppColors.secondary,
          ],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 24 : 48,
          vertical: isMobile ? 60 : 100,
        ),
        child: isMobile || isTablet
            ? _buildMobileLayout(context)
            : _buildDesktopLayout(context),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        _buildTextContent(context, isMobile: true),
        const SizedBox(height: 48),
        _buildAppPreview(isMobile: true),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: _buildTextContent(context, isMobile: false),
        ),
        const SizedBox(width: 60),
        Expanded(
          flex: 1,
          child: _buildAppPreview(isMobile: false),
        ),
      ],
    );
  }

  Widget _buildTextContent(BuildContext context, {required bool isMobile}) {
    return Column(
      crossAxisAlignment:
          isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          'Your Health,\nYour Records,\nAll in One Place',
          textAlign: isMobile ? TextAlign.center : TextAlign.left,
          style: TextStyle(
            fontSize: isMobile ? 36 : 56,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Store, manage, and share your medical documents securely. Track medications, schedule appointments, and keep your family\'s health records organized.',
          textAlign: isMobile ? TextAlign.center : TextAlign.left,
          style: TextStyle(
            fontSize: isMobile ? 16 : 20,
            color: Colors.white.withOpacity(0.9),
            height: 1.6,
          ),
        ),
        const SizedBox(height: 40),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment:
              isMobile ? WrapAlignment.center : WrapAlignment.start,
          children: [
            ElevatedButton(
              onPressed: () => Get.to(() => const SignupScreen()),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 20,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 8,
              ),
              child: const Text(
                'Get Started Free',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            OutlinedButton(
              onPressed: () {
                // Scroll to download section
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white, width: 2),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 20,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Download App',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 40),
        _buildTrustBadges(isMobile: isMobile),
      ],
    );
  }

  Widget _buildAppPreview({required bool isMobile}) {
    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isMobile ? 300 : 500,
          maxHeight: isMobile ? 400 : 600,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 30,
              spreadRadius: 5,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            color: Colors.white,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.phone_android,
                  size: isMobile ? 100 : 150,
                  color: AppColors.primary.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'App Screenshot\nPlaceholder',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 18,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrustBadges({required bool isMobile}) {
    return Wrap(
      spacing: 24,
      runSpacing: 16,
      alignment: isMobile ? WrapAlignment.center : WrapAlignment.start,
      children: [
        _TrustBadge(
          icon: Icons.security,
          text: 'Secure & Encrypted',
          isMobile: isMobile,
        ),
        _TrustBadge(
          icon: Icons.cloud_done,
          text: 'Cloud Backup',
          isMobile: isMobile,
        ),
        _TrustBadge(
          icon: Icons.verified_user,
          text: 'HIPAA Compliant',
          isMobile: isMobile,
        ),
      ],
    );
  }
}

class _TrustBadge extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isMobile;

  const _TrustBadge({
    required this.icon,
    required this.text,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: isMobile ? 20 : 24,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontSize: isMobile ? 14 : 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
