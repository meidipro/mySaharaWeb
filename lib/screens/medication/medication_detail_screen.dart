import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import '../../services/medication_notification_service.dart';

/// Medication Detail Screen - Shows medication details and logs
class MedicationDetailScreen extends StatelessWidget {
  final Map<String, dynamic> medication;

  const MedicationDetailScreen({super.key, required this.medication});

  @override
  Widget build(BuildContext context) {
    final name = medication['name'] as String;
    final dosageAmount = medication['dosage_amount'];
    final dosageUnit = medication['dosage_unit'] as String;
    final form = medication['form'] as String;
    final instructions = medication['instructions'] as String?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medication Details'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Navigate to edit screen
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$dosageAmount $dosageUnit • $form',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (instructions != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.healthBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: AppColors.healthBlue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              instructions,
                              style: TextStyle(color: AppColors.healthBlue),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Reminder Settings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.alarm, color: AppColors.primary),
                  title: const Text('Daily Reminder'),
                  subtitle: const Text('Set 3 times a day (Morning, Afternoon, Evening)'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showQuickReminderSetup(context, name, dosageAmount, dosageUnit),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.schedule, color: AppColors.healthBlue),
                  title: const Text('Custom Schedule'),
                  subtitle: const Text('Set specific times and frequency'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showCustomReminderSetup(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.notification_add, color: AppColors.success),
                  title: const Text('Test Notification'),
                  subtitle: const Text('Send a test reminder now'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _sendTestNotification(context, name, dosageAmount, dosageUnit),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showQuickReminderSetup(BuildContext context, String name, dynamic dosageAmount, String dosageUnit) {
    final instructions = medication['instructions'] as String?;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quick Setup - 3 Times Daily'),
        content: const Text(
          'Set reminders for:\n\n'
          '🌅 Morning (8:00 AM)\n'
          '☀️ Afternoon (2:00 PM)\n'
          '🌙 Evening (8:00 PM)',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final notificationService = MedicationNotificationService();
              final medicationId = medication['id'];

              await notificationService.scheduleDailyReminder(
                medicationId: '$medicationId-morning',
                medicationName: name,
                dosage: '$dosageAmount $dosageUnit',
                hour: 8,
                minute: 0,
                instructions: instructions,
              );

              await notificationService.scheduleDailyReminder(
                medicationId: '$medicationId-afternoon',
                medicationName: name,
                dosage: '$dosageAmount $dosageUnit',
                hour: 14,
                minute: 0,
                instructions: instructions,
              );

              await notificationService.scheduleDailyReminder(
                medicationId: '$medicationId-evening',
                medicationName: name,
                dosage: '$dosageAmount $dosageUnit',
                hour: 20,
                minute: 0,
                instructions: instructions,
              );

              Navigator.pop(context);
              Get.snackbar(
                'Reminders Set!',
                '3 daily reminders scheduled successfully',
                backgroundColor: AppColors.success,
                colorText: Colors.white,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Set Reminders', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showCustomReminderSetup(BuildContext context) {
    TimeOfDay selectedTime = const TimeOfDay(hour: 8, minute: 0);
    String frequency = 'daily';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Custom Reminder'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: frequency,
                decoration: const InputDecoration(labelText: 'Frequency'),
                items: const [
                  DropdownMenuItem(value: 'daily', child: Text('Daily')),
                  DropdownMenuItem(value: 'interval_6', child: Text('Every 6 hours')),
                  DropdownMenuItem(value: 'interval_8', child: Text('Every 8 hours')),
                  DropdownMenuItem(value: 'interval_12', child: Text('Every 12 hours')),
                ],
                onChanged: (value) => setState(() => frequency = value!),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Time'),
                subtitle: Text('${selectedTime.hour}:${selectedTime.minute.toString().padLeft(2, '0')}'),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: selectedTime,
                  );
                  if (time != null) setState(() => selectedTime = time);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final notificationService = MedicationNotificationService();
                final medicationId = medication['id'];
                final name = medication['name'];
                final dosageAmount = medication['dosage_amount'];
                final dosageUnit = medication['dosage_unit'];
                final instructions = medication['instructions'];

                if (frequency == 'daily') {
                  await notificationService.scheduleDailyReminder(
                    medicationId: medicationId,
                    medicationName: name,
                    dosage: '$dosageAmount $dosageUnit',
                    hour: selectedTime.hour,
                    minute: selectedTime.minute,
                    instructions: instructions,
                  );
                } else if (frequency.startsWith('interval_')) {
                  final hours = int.parse(frequency.split('_')[1]);
                  await notificationService.scheduleIntervalReminder(
                    medicationId: medicationId,
                    medicationName: name,
                    dosage: '$dosageAmount $dosageUnit',
                    intervalHours: hours,
                    instructions: instructions,
                  );
                }

                Navigator.pop(context);
                Get.snackbar(
                  'Reminder Set!',
                  'Notification scheduled successfully',
                  backgroundColor: AppColors.success,
                  colorText: Colors.white,
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _sendTestNotification(BuildContext context, String name, dynamic dosageAmount, String dosageUnit) async {
    final notificationService = MedicationNotificationService();
    final instructions = medication['instructions'] as String?;

    await notificationService.showImmediateNotification(
      medicationName: name,
      dosage: '$dosageAmount $dosageUnit',
      instructions: instructions,
    );

    Get.snackbar(
      'Test Sent!',
      'Check your notifications',
      backgroundColor: AppColors.success,
      colorText: Colors.white,
    );
  }
}
