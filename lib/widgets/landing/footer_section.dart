import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../../constants/app_colors.dart';

/// Footer section with links and information
class FooterSection extends StatelessWidget {
  const FooterSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;

    return Container(
      width: double.infinity,
      color: AppColors.textPrimary,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 48,
        vertical: isMobile ? 40 : 60,
      ),
      child: Column(
        children: [
          if (isMobile) ...[
            _buildMobileLayout(),
          ] else ...[
            _buildDesktopLayout(),
          ],
          const Divider(color: Colors.white24, height: 60),
          _buildBottomBar(isMobile),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBrandSection(),
        const SizedBox(height: 40),
        _buildProductLinks(),
        const SizedBox(height: 32),
        _buildCompanyLinks(),
        const SizedBox(height: 32),
        _buildSupportLinks(),
        const SizedBox(height: 32),
        _buildSocialLinks(),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 2, child: _buildBrandSection()),
        const SizedBox(width: 60),
        Expanded(child: _buildProductLinks()),
        Expanded(child: _buildCompanyLinks()),
        Expanded(child: _buildSupportLinks()),
        Expanded(child: _buildSocialLinks()),
      ],
    );
  }

  Widget _buildBrandSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.health_and_safety, color: Colors.white, size: 32),
            SizedBox(width: 12),
            Text(
              'mySahara',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Your personal health record management system. Secure, simple, and accessible from anywhere.',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildProductLinks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Product',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        _FooterLink(text: 'Features', onTap: () {}),
        _FooterLink(text: 'Download', onTap: () {}),
        _FooterLink(text: 'Pricing', onTap: () {}),
        _FooterLink(text: 'FAQ', onTap: () {}),
      ],
    );
  }

  Widget _buildCompanyLinks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Company',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        _FooterLink(text: 'About Us', onTap: () {}),
        _FooterLink(text: 'Blog', onTap: () {}),
        _FooterLink(text: 'Careers', onTap: () {}),
        _FooterLink(text: 'Contact', onTap: () {}),
      ],
    );
  }

  Widget _buildSupportLinks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Support',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        _FooterLink(text: 'Help Center', onTap: () {}),
        _FooterLink(text: 'Privacy Policy', onTap: () {}),
        _FooterLink(text: 'Terms of Service', onTap: () {}),
        _FooterLink(text: 'Security', onTap: () {}),
      ],
    );
  }

  Widget _buildSocialLinks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Connect',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            _SocialIcon(icon: Icons.facebook, onTap: () {}),
            const SizedBox(width: 12),
            _SocialIcon(icon: Icons.web, onTap: () {}), // Twitter/X
            const SizedBox(width: 12),
            _SocialIcon(icon: Icons.link, onTap: () {}), // LinkedIn
            const SizedBox(width: 12),
            _SocialIcon(icon: Icons.message, onTap: () {}), // Instagram
          ],
        ),
      ],
    );
  }

  Widget _buildBottomBar(bool isMobile) {
    return Column(
      children: [
        if (isMobile) ...[
          const Text(
            '© 2025 mySahara. All rights reserved.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white60,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Made with ❤️ for better healthcare',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white60,
              fontSize: 12,
            ),
          ),
        ] else ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                '© 2025 mySahara. All rights reserved.',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 14,
                ),
              ),
              Text(
                'Made with ❤️ for better healthcare',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _FooterLink({
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _SocialIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _SocialIcon({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
}
