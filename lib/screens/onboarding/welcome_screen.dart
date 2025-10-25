import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../../constants/app_colors.dart';
import 'family_setup_wizard_screen.dart';

/// Welcome screen for first-time users with family-first messaging
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingPage> _pages = [
    _OnboardingPage(
      title: 'পুরো পরিবারের স্বাস্থ্য\nএকজনের হাতে',
      subtitle: 'Entire Family\'s Health\nin One Hand',
      description: 'Manage health records for parents, children, grandparents - everyone in your family, all from one app.',
      icon: Icons.family_restroom,
      color: AppColors.primary,
      lottieAsset: null, // You can add Lottie animations later
    ),
    _OnboardingPage(
      title: 'Never Lose Important\nMedical Documents',
      subtitle: null,
      description: 'Store prescriptions, lab reports, and medical records for every family member securely in the cloud.',
      icon: Icons.folder_special,
      color: AppColors.healthBlue,
      lottieAsset: null,
    ),
    _OnboardingPage(
      title: 'Smart Family\nHealth Tracking',
      subtitle: null,
      description: 'Track medications, appointments, and health metrics for each family member. Get reminders so no one misses their dose.',
      icon: Icons.health_and_safety,
      color: AppColors.healthGreen,
      lottieAsset: null,
    ),
    _OnboardingPage(
      title: 'Share Family History\nwith Doctors Instantly',
      subtitle: null,
      description: 'Generate QR codes with family medical history, including genetic risks. Doctors get complete context in one scan.',
      icon: Icons.qr_code_2,
      color: AppColors.healthPurple,
      lottieAsset: null,
    ),
    _OnboardingPage(
      title: 'AI That Understands\nYour Family',
      subtitle: null,
      description: 'Ask "আব্বুর ডায়াবেটিস কেমন?" - Our AI understands family context in Bangla and English. Get insights about genetic patterns.',
      icon: Icons.smart_toy,
      color: AppColors.secondary,
      lottieAsset: null,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _startFamilySetup();
    }
  }

  void _skipToSetup() {
    _startFamilySetup();
  }

  void _startFamilySetup() {
    Get.to(
      () => const FamilySetupWizardScreen(),
      transition: Transition.cupertino,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Logo
                  Row(
                    children: [
                      Icon(
                        Icons.health_and_safety,
                        color: AppColors.primary,
                        size: 28,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'My Sahara',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  // Skip button
                  if (_currentPage < _pages.length - 1)
                    TextButton(
                      onPressed: _skipToSetup,
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(context, _pages[index], isMobile);
                },
              ),
            ),

            // Page indicator and buttons
            Padding(
              padding: EdgeInsets.all(isMobile ? 24 : 32),
              child: Column(
                children: [
                  // Page indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? _pages[index].color
                              : AppColors.textSecondary.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Next/Get Started button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _pages[_currentPage].color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        _currentPage == _pages.length - 1
                            ? 'Start Protecting Your Family'
                            : 'Next',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
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

  Widget _buildPage(BuildContext context, _OnboardingPage page, bool isMobile) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon or Lottie animation
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: page.color.withOpacity(0.1),
            ),
            child: Icon(
              page.icon,
              size: isMobile ? 80 : 120,
              color: page.color,
            ),
          ),
          const SizedBox(height: 48),

          // Title
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isMobile ? 28 : 36,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              height: 1.2,
            ),
          ),

          // Subtitle (if exists)
          if (page.subtitle != null) ...[
            const SizedBox(height: 12),
            Text(
              page.subtitle!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isMobile ? 24 : 30,
                fontWeight: FontWeight.w600,
                color: page.color,
                height: 1.2,
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Description
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isMobile ? 16 : 18,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage {
  final String title;
  final String? subtitle;
  final String description;
  final IconData icon;
  final Color color;
  final String? lottieAsset;

  _OnboardingPage({
    required this.title,
    this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
    this.lottieAsset,
  });
}
