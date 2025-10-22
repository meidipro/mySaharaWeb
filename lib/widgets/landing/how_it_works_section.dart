import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../../constants/app_colors.dart';

/// How It Works section with step-by-step guide
class HowItWorksSection extends StatelessWidget {
  const HowItWorksSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 48,
        vertical: isMobile ? 60 : 100,
      ),
      child: Column(
        children: [
          // Section Header
          Text(
            'How It Works',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isMobile ? 32 : 48,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Get started in 3 simple steps',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isMobile ? 16 : 20,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 60),

          // Steps
          _buildSteps(isMobile),
        ],
      ),
    );
  }

  Widget _buildSteps(bool isMobile) {
    final steps = [
      _StepData(
        number: '1',
        title: 'Create Your Account',
        description:
            'Sign up for free in seconds. No credit card required. Start with web app or download mobile app.',
        icon: Icons.person_add,
        color: AppColors.primary,
      ),
      _StepData(
        number: '2',
        title: 'Upload Your Records',
        description:
            'Take photos or upload PDF files of your medical documents. Our AI automatically organizes and extracts key information.',
        icon: Icons.cloud_upload,
        color: Colors.green,
      ),
      _StepData(
        number: '3',
        title: 'Share & Manage',
        description:
            'Generate QR codes to share with doctors. Track medications, schedule appointments, and keep your family healthy.',
        icon: Icons.qr_code,
        color: Colors.purple,
      ),
    ];

    if (isMobile) {
      return Column(
        children: steps
            .map((step) => Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: _StepCard(step: step, isMobile: true),
                ))
            .toList(),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: steps
          .asMap()
          .entries
          .map((entry) {
            final index = entry.key;
            final step = entry.value;
            return Expanded(
              child: Row(
                children: [
                  Expanded(child: _StepCard(step: step, isMobile: false)),
                  if (index < steps.length - 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Icon(
                        Icons.arrow_forward,
                        size: 32,
                        color: AppColors.textSecondary.withOpacity(0.3),
                      ),
                    ),
                ],
              ),
            );
          })
          .toList(),
    );
  }
}

class _StepData {
  final String number;
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  _StepData({
    required this.number,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

class _StepCard extends StatelessWidget {
  final _StepData step;
  final bool isMobile;

  const _StepCard({
    required this.step,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Number Circle
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [step.color, step.color.withOpacity(0.7)],
            ),
            boxShadow: [
              BoxShadow(
                color: step.color.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Text(
              step.number,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Icon
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: step.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            step.icon,
            size: 48,
            color: step.color,
          ),
        ),
        const SizedBox(height: 24),

        // Title
        Text(
          step.title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),

        // Description
        Text(
          step.description,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textSecondary,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}
