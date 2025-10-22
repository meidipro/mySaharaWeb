import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../../constants/app_colors.dart';

/// Testimonials section with user reviews
class TestimonialsSection extends StatelessWidget {
  const TestimonialsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;

    return Container(
      width: double.infinity,
      color: Colors.grey[50],
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 48,
        vertical: isMobile ? 60 : 100,
      ),
      child: Column(
        children: [
          // Section Header
          Text(
            'What Our Users Say',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isMobile ? 32 : 48,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Join thousands of satisfied users managing their health records',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isMobile ? 16 : 20,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 60),

          // Testimonials Grid
          _buildTestimonialsGrid(isMobile),
        ],
      ),
    );
  }

  Widget _buildTestimonialsGrid(bool isMobile) {
    final testimonials = [
      _TestimonialData(
        name: 'Sarah Johnson',
        role: 'Patient',
        comment:
            'mySahara has completely changed how I manage my medical records. The QR code feature is brilliant - I can share my history with doctors instantly!',
        rating: 5,
        avatar: Icons.person,
      ),
      _TestimonialData(
        name: 'Dr. Michael Chen',
        role: 'Physician',
        comment:
            'As a doctor, I appreciate when patients use mySahara. It saves time and gives me instant access to their complete medical history.',
        rating: 5,
        avatar: Icons.person,
      ),
      _TestimonialData(
        name: 'Emily Rodriguez',
        role: 'Family Caregiver',
        comment:
            'Managing health records for my entire family has never been easier. The medication reminders are a lifesaver!',
        rating: 5,
        avatar: Icons.person,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 1;
        if (constraints.maxWidth > 900) {
          crossAxisCount = 3;
        } else if (constraints.maxWidth > 600) {
          crossAxisCount = 2;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 24,
            mainAxisSpacing: 24,
            childAspectRatio: 0.9,
          ),
          itemCount: testimonials.length,
          itemBuilder: (context, index) {
            return _TestimonialCard(testimonial: testimonials[index]);
          },
        );
      },
    );
  }
}

class _TestimonialData {
  final String name;
  final String role;
  final String comment;
  final int rating;
  final IconData avatar;

  _TestimonialData({
    required this.name,
    required this.role,
    required this.comment,
    required this.rating,
    required this.avatar,
  });
}

class _TestimonialCard extends StatelessWidget {
  final _TestimonialData testimonial;

  const _TestimonialCard({required this.testimonial});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stars
            Row(
              children: List.generate(
                testimonial.rating,
                (index) => const Icon(
                  Icons.star,
                  color: Colors.amber,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Comment
            Expanded(
              child: Text(
                '"${testimonial.comment}"',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textPrimary,
                  height: 1.6,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // User Info
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.2),
                  child: Icon(
                    testimonial.avatar,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      testimonial.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      testimonial.role,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
