import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../../constants/app_colors.dart';

/// Features section showcasing app capabilities
class FeaturesSection extends StatelessWidget {
  const FeaturesSection({super.key});

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
            'Powerful Features',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isMobile ? 32 : 48,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Everything you need to manage your health records efficiently',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isMobile ? 16 : 20,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 60),

          // Features Grid
          _buildFeaturesGrid(isMobile),
        ],
      ),
    );
  }

  Widget _buildFeaturesGrid(bool isMobile) {
    final features = [
      _FeatureData(
        icon: Icons.folder_open,
        title: 'Document Management',
        description:
            'Store and organize all your medical documents, lab reports, and prescriptions in one secure place.',
        color: AppColors.primary,
      ),
      _FeatureData(
        icon: Icons.qr_code_scanner,
        title: 'QR Code Sharing',
        description:
            'Share your medical history instantly with doctors using secure QR codes. No more carrying physical documents.',
        color: Colors.purple,
      ),
      _FeatureData(
        icon: Icons.medication,
        title: 'Medication Tracking',
        description:
            'Keep track of all your medications, set reminders, and never miss a dose. Manage prescriptions effortlessly.',
        color: Colors.green,
      ),
      _FeatureData(
        icon: Icons.calendar_month,
        title: 'Appointment Management',
        description:
            'Schedule and manage doctor appointments. Get reminders and keep track of your medical visits.',
        color: Colors.orange,
      ),
      _FeatureData(
        icon: Icons.family_restroom,
        title: 'Family Health Records',
        description:
            'Manage health records for your entire family. Add family members and keep everyone\'s health organized.',
        color: Colors.pink,
      ),
      _FeatureData(
        icon: Icons.smart_toy,
        title: 'AI Health Assistant',
        description:
            'Get instant answers to health questions with our AI-powered chat assistant. Available 24/7.',
        color: Colors.blue,
      ),
      _FeatureData(
        icon: Icons.timeline,
        title: 'Medical Timeline',
        description:
            'View your complete medical history in a beautiful timeline. Track your health journey over time.',
        color: Colors.teal,
      ),
      _FeatureData(
        icon: Icons.cloud_upload,
        title: 'AI Document Analysis',
        description:
            'Upload any medical document and get instant AI-powered analysis and insights about your health data.',
        color: Colors.indigo,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 1;
        if (constraints.maxWidth > 1200) {
          crossAxisCount = 4;
        } else if (constraints.maxWidth > 800) {
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
            childAspectRatio: 0.85,
          ),
          itemCount: features.length,
          itemBuilder: (context, index) {
            return _FeatureCard(feature: features[index]);
          },
        );
      },
    );
  }
}

class _FeatureData {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  _FeatureData({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}

class _FeatureCard extends StatefulWidget {
  final _FeatureData feature;

  const _FeatureCard({required this.feature});

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.identity()
          ..translate(0.0, _isHovered ? -8.0 : 0.0),
        child: Card(
          elevation: _isHovered ? 12 : 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: widget.feature.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    widget.feature.icon,
                    size: 40,
                    color: widget.feature.color,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  widget.feature.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Text(
                    widget.feature.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
