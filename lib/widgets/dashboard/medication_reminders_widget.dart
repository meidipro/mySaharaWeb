import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/medication_service.dart';
import '../../screens/medication/medication_management_screen.dart';
import '../../screens/medication/add_medication_screen_simple.dart';

/// Medication Reminders Widget - Shows today's medications
class MedicationRemindersWidget extends StatefulWidget {
  const MedicationRemindersWidget({super.key});

  @override
  State<MedicationRemindersWidget> createState() => _MedicationRemindersWidgetState();
}

class _MedicationRemindersWidgetState extends State<MedicationRemindersWidget> {
  final MedicationService _medicationService = MedicationService();
  List<Map<String, dynamic>> _todayMedications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTodayMedications();
  }

  Future<void> _loadTodayMedications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.user?.id;

      if (userId != null) {
        final medications = await _medicationService.getMedications(userId);

        // Filter active medications
        final activeMeds = medications.where((med) {
          final isOngoing = med['is_ongoing'] as bool? ?? false;
          return isOngoing;
        }).toList();

        if (mounted) {
          setState(() {
            _todayMedications = activeMeds.take(3).toList(); // Show up to 3
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading medications: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.healthGreen.withOpacity(0.05),
              AppColors.healthBlue.withOpacity(0.05),
            ],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.healthGreen.withOpacity(0.2),
                  ),
                  child: Icon(
                    Icons.medication,
                    color: AppColors.healthGreen,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Today\'s Medications',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Get.to(() => const MedicationManagementScreen()),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Medications list
            if (_isLoading)
              _buildLoadingState()
            else if (_todayMedications.isEmpty)
              _buildEmptyState()
            else
              _buildMedicationsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.healthGreen.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.healthGreen.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.healthGreen.withOpacity(0.1),
            ),
            child: Icon(
              Icons.medical_services_outlined,
              size: 40,
              color: AppColors.healthGreen,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No Active Medications',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Track your family\'s medications and\nget timely reminders',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => Get.to(() => const AddMedicationScreenSimple()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.healthGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.add),
            label: const Text(
              'Add Medication',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationsList() {
    return Column(
      children: [
        ..._todayMedications.map((med) => _buildMedicationCard(med)),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Get.to(() => const AddMedicationScreenSimple()),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.healthGreen,
              side: BorderSide(color: AppColors.healthGreen, width: 2),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.add),
            label: const Text(
              'Add Medication',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMedicationCard(Map<String, dynamic> medication) {
    final name = medication['name'] as String? ?? 'Unknown Medication';
    final dosageAmount = medication['dosage_amount']?.toString() ?? '';
    final dosageUnit = medication['dosage_unit'] as String? ?? '';
    final form = medication['form'] as String? ?? '';
    final frequencyPerDay = medication['frequency_per_day'] as int? ?? 0;
    final reminderTimes = medication['reminder_times'] as List<dynamic>? ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.healthGreen.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Medication icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.healthGreen.withOpacity(0.1),
            ),
            child: Icon(
              _getMedicationIcon(form),
              color: AppColors.healthGreen,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),

          // Medication details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$dosageAmount $dosageUnit • $frequencyPerDay times daily',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (reminderTimes.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        reminderTimes.take(3).join(', '),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Checkbox
          Icon(
            Icons.check_circle_outline,
            color: AppColors.textHint,
            size: 28,
          ),
        ],
      ),
    );
  }

  IconData _getMedicationIcon(String form) {
    switch (form.toLowerCase()) {
      case 'tablet':
      case 'pill':
        return Icons.medication;
      case 'capsule':
        return Icons.medication_liquid;
      case 'syrup':
      case 'liquid':
        return Icons.local_drink;
      case 'injection':
        return Icons.vaccines;
      case 'cream':
      case 'ointment':
        return Icons.healing;
      case 'drops':
        return Icons.water_drop;
      case 'inhaler':
        return Icons.air;
      default:
        return Icons.medical_services;
    }
  }
}
