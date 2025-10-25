import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../../constants/app_colors.dart';
import '../../providers/family_provider.dart';
import '../../services/family_service.dart';
import '../family/add_family_member_screen.dart';
import '../home/home_screen.dart';

/// Family Setup Wizard - Guided flow to add first family member
class FamilySetupWizardScreen extends StatefulWidget {
  const FamilySetupWizardScreen({super.key});

  @override
  State<FamilySetupWizardScreen> createState() =>
      _FamilySetupWizardScreenState();
}

class _FamilySetupWizardScreenState extends State<FamilySetupWizardScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _setupYourself = false;
  bool _setupFamily = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skipToHome() {
    Get.offAll(() => const HomeScreen());
  }

  Future<void> _addYourselfAsFirst() async {
    setState(() {
      _setupYourself = true;
    });

    try {
      // Create "Me" as first family member
      final familyService = FamilyService();
      await familyService.createDefaultSelfMember();

      // Reload family members
      if (mounted) {
        await context.read<FamilyProvider>().loadFamilyMembers();
      }

      setState(() {
        _setupYourself = false;
      });

      _nextStep();
    } catch (e) {
      setState(() {
        _setupYourself = false;
      });

      if (mounted) {
        Get.snackbar(
          'Error',
          'Failed to create your profile. Please try again.',
          backgroundColor: AppColors.error,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }

  Future<void> _addFamilyMember() async {
    final result = await Get.to(() => const AddFamilyMemberScreen());

    if (result == true && mounted) {
      // Reload family members
      await context.read<FamilyProvider>().loadFamilyMembers();

      setState(() {
        _setupFamily = true;
      });

      // Show success message
      Get.snackbar(
        'Success',
        'Family member added successfully!',
        backgroundColor: AppColors.success,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _currentStep > 0
            ? IconButton(
                icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
                onPressed: _previousStep,
              )
            : null,
        actions: [
          if (_currentStep < 2)
            TextButton(
              onPressed: _skipToHome,
              child: Text(
                'Skip for now',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: List.generate(
                  3,
                  (index) => Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 4,
                      decoration: BoxDecoration(
                        color: index <= _currentStep
                            ? AppColors.primary
                            : AppColors.textSecondary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildWelcomeStep(context, isMobile),
                  _buildAddYourselfStep(context, isMobile),
                  _buildAddFamilyStep(context, isMobile),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeStep(BuildContext context, bool isMobile) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 48, vertical: 24),
      child: Column(
        children: [
          // Illustration
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.1),
                  AppColors.secondary.withOpacity(0.1),
                ],
              ),
            ),
            child: Icon(
              Icons.family_restroom,
              size: isMobile ? 100 : 150,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 40),

          // Title
          Text(
            'Welcome to Your Family\nHealth Hub!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isMobile ? 28 : 36,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),

          // Description
          Text(
            'Let\'s set up your family health profiles so you can start protecting everyone you care about.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isMobile ? 16 : 18,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 40),

          // Benefits cards
          _buildBenefitCard(
            icon: Icons.person_add,
            title: 'Add Up to 6 Family Members',
            description: 'Parents, children, grandparents - manage everyone\'s health in one place',
            color: AppColors.healthBlue,
          ),
          const SizedBox(height: 16),
          _buildBenefitCard(
            icon: Icons.folder_special,
            title: 'Store All Medical Records',
            description: 'Never lose important documents. Everything backed up securely.',
            color: AppColors.healthGreen,
          ),
          const SizedBox(height: 16),
          _buildBenefitCard(
            icon: Icons.insights,
            title: 'Track Genetic Patterns',
            description: 'AI analyzes family diseases and alerts you to genetic risks.',
            color: AppColors.healthPurple,
          ),
          const SizedBox(height: 40),

          // Get Started button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: const Text(
                'Let\'s Get Started',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddYourselfStep(BuildContext context, bool isMobile) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 48, vertical: 24),
      child: Column(
        children: [
          // Illustration
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(0.1),
            ),
            child: Icon(
              Icons.person,
              size: isMobile ? 100 : 150,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 40),

          // Title
          Text(
            'First, Let\'s Add You',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isMobile ? 28 : 36,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // Description
          Text(
            'We\'ll create your health profile so you can track your own records and medications.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isMobile ? 16 : 18,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 40),

          // Information about what's included
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                _buildInfoRow(Icons.check_circle, 'Your health records & documents'),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.check_circle, 'Your medications & reminders'),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.check_circle, 'Your health metrics (BMI, BMR)'),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.check_circle, 'Your medical timeline'),
              ],
            ),
          ),
          const SizedBox(height: 40),

          // Add yourself button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _setupYourself ? null : _addYourselfAsFirst,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: _setupYourself
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Create My Profile',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddFamilyStep(BuildContext context, bool isMobile) {
    final familyProvider = context.watch<FamilyProvider>();
    final familyCount = familyProvider.familyMembers.length;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 48, vertical: 24),
      child: Column(
        children: [
          // Illustration
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.healthGreen.withOpacity(0.1),
                  AppColors.healthBlue.withOpacity(0.1),
                ],
              ),
            ),
            child: Icon(
              Icons.group_add,
              size: isMobile ? 100 : 150,
              color: AppColors.healthGreen,
            ),
          ),
          const SizedBox(height: 40),

          // Title
          Text(
            'Now Add Your Family',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isMobile ? 28 : 36,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // Description
          Text(
            familyCount > 0
                ? 'Great! You\'ve added $familyCount ${familyCount == 1 ? 'member' : 'members'}. Add more family members to protect everyone.'
                : 'Add your parents, children, or anyone whose health you want to track and protect.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isMobile ? 16 : 18,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 40),

          // Who you can add
          _buildFamilyRoleCard(
            icon: Icons.elderly,
            title: 'Parents & Grandparents',
            description: 'Track chronic conditions, medications, and appointments',
          ),
          const SizedBox(height: 12),
          _buildFamilyRoleCard(
            icon: Icons.child_care,
            title: 'Children',
            description: 'Vaccination records, growth tracking, pediatric visits',
          ),
          const SizedBox(height: 12),
          _buildFamilyRoleCard(
            icon: Icons.favorite,
            title: 'Spouse & Siblings',
            description: 'Complete family health history for genetic insights',
          ),
          const SizedBox(height: 40),

          // Add family member button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _addFamilyMember,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.healthGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              icon: const Icon(Icons.person_add),
              label: const Text(
                'Add Family Member',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Continue to app button
          if (familyCount > 0)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _skipToHome,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: AppColors.primary),
                ),
                child: const Text(
                  'Continue to App',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _skipToHome,
              child: Text(
                'I\'ll add family members later',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBenefitCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFamilyRoleCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.textSecondary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
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
