import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../../constants/app_colors.dart';
import '../../screens/auth/signup_screen.dart';

/// Download section with app store links and QR codes
class DownloadSection extends StatelessWidget {
  const DownloadSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.secondary.withOpacity(0.1),
          ],
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 48,
        vertical: isMobile ? 60 : 100,
      ),
      child: Column(
        children: [
          // Section Header
          Text(
            'Download mySahara',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isMobile ? 32 : 48,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Available on all your devices',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isMobile ? 16 : 20,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 60),

          // Download Options
          if (isMobile) ...[
            _buildMobileLayout(),
          ] else ...[
            _buildDesktopLayout(),
          ],

          const SizedBox(height: 60),

          // Web App CTA
          _buildWebAppCTA(),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _DownloadCard(
          title: 'iOS',
          icon: Icons.apple,
          description: 'Download from App Store',
          color: Colors.black,
          onTap: () {
            // TODO: Add App Store link
          },
        ),
        const SizedBox(height: 24),
        _DownloadCard(
          title: 'Android',
          icon: Icons.android,
          description: 'Download from Google Play',
          color: Colors.green,
          onTap: () {
            // TODO: Add Play Store link
          },
        ),
        const SizedBox(height: 24),
        _DownloadCard(
          title: 'Web App',
          icon: Icons.web,
          description: 'Use directly in browser',
          color: AppColors.primary,
          onTap: () => Get.to(() => const SignupScreen()),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Expanded(
          child: _DownloadCard(
            title: 'iOS',
            icon: Icons.apple,
            description: 'Download from App Store',
            color: Colors.black,
            onTap: () {
              // TODO: Add App Store link
            },
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _DownloadCard(
            title: 'Android',
            icon: Icons.android,
            description: 'Download from Google Play',
            color: Colors.green,
            onTap: () {
              // TODO: Add Play Store link
            },
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _DownloadCard(
            title: 'Web App',
            icon: Icons.web,
            description: 'Use directly in browser',
            color: AppColors.primary,
            onTap: () => Get.to(() => const SignupScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildWebAppCTA() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.language,
            size: 64,
            color: Colors.white,
          ),
          const SizedBox(height: 24),
          const Text(
            'Start Using Web App Now',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No installation required. Access from any browser, anywhere.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Get.to(() => const SignupScreen()),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(
                horizontal: 48,
                vertical: 20,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 8,
            ),
            child: const Text(
              'Launch Web App',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DownloadCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _DownloadCard({
    required this.title,
    required this.icon,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  State<_DownloadCard> createState() => _DownloadCardState();
}

class _DownloadCardState extends State<_DownloadCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.identity()
            ..translate(0.0, _isHovered ? -8.0 : 0.0),
          child: Card(
            elevation: _isHovered ? 12 : 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.icon,
                      size: 64,
                      color: widget.color,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: widget.onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Download'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
