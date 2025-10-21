import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

/// Vaccine Management Screen - Shows vaccine records
class VaccineManagementScreen extends StatelessWidget {
  final List<Map<String, dynamic>>? vaccines;
  final VoidCallback? onRefresh;

  const VaccineManagementScreen({super.key, this.vaccines, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final vaccineList = vaccines ?? [];

    if (vaccineList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.vaccines_outlined,
              size: 80,
              color: AppColors.primary.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No Vaccines Yet',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your vaccine records to track immunization',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: vaccineList.length,
      itemBuilder: (context, index) {
        final vaccine = vaccineList[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Icon(Icons.vaccines, color: AppColors.primary),
            ),
            title: Text(vaccine['vaccine_name'] ?? 'Unknown Vaccine'),
            subtitle: Text('Dose ${vaccine['dose_number']}${vaccine['total_doses'] != null ? '/${vaccine['total_doses']}' : ''}'),
            trailing: Text(
              vaccine['status'] ?? 'Unknown',
              style: TextStyle(
                color: vaccine['status'] == 'completed' ? AppColors.success : AppColors.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      },
    );
  }
}
