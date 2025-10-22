import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../constants/app_colors.dart';
import '../../widgets/landing/landing_navbar.dart';
import '../../widgets/landing/hero_section.dart';
import '../../widgets/landing/features_section.dart';
import '../../widgets/landing/how_it_works_section.dart';
import '../../widgets/landing/download_section.dart';
import '../../widgets/landing/testimonials_section.dart';
import '../../widgets/landing/footer_section.dart';
import '../auth/login_screen.dart';
import '../auth/signup_screen.dart';

/// Landing page for web application
/// Shows marketing content, features, and download options
class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.offset > 50 && !_isScrolled) {
      setState(() => _isScrolled = true);
    } else if (_scrollController.offset <= 50 && _isScrolled) {
      setState(() => _isScrolled = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Main content
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                // Add padding for fixed navbar
                const SizedBox(height: 70),

                // Hero Section
                const HeroSection(),

                // Features Section
                const FeaturesSection(),

                // How It Works Section
                const HowItWorksSection(),

                // Download Section
                const DownloadSection(),

                // Testimonials Section
                const TestimonialsSection(),

                // Footer
                const FooterSection(),
              ],
            ),
          ),

          // Fixed Navigation Bar
          LandingNavbar(
            isScrolled: _isScrolled,
            onLoginTap: () => Get.to(() => const LoginScreen()),
            onSignupTap: () => Get.to(() => const SignupScreen()),
          ),
        ],
      ),
    );
  }
}
