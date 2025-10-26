import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/appointment_service.dart';
import '../../services/appointment_notification_service.dart';
import 'package:url_launcher/url_launcher.dart';

/// Add Appointment Screen - Form to add new appointment
class AddAppointmentScreen extends StatefulWidget {
  final Map<String, dynamic>? existingAppointment;
  final String? familyMemberId; // Optional: for family member's appointments
  final String? familyMemberName; // Optional: for display

  const AddAppointmentScreen({
    super.key,
    this.existingAppointment,
    this.familyMemberId,
    this.familyMemberName,
  });

  @override
  State<AddAppointmentScreen> createState() => _AddAppointmentScreenState();
}

class _AddAppointmentScreenState extends State<AddAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final AppointmentService _appointmentService = AppointmentService();
  final AppointmentNotificationService _notificationService =
      AppointmentNotificationService();

  // Form controllers
  final _doctorNameController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _locationController = TextEditingController();
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();

  // Form values
  DateTime? _appointmentDate;
  TimeOfDay? _appointmentTime;
  String _visitType = 'in-person';
  String _status = 'scheduled';
  bool _reminder24h = true;
  bool _reminder1h = true;
  int _durationMinutes = 30;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  void _loadExistingData() {
    if (widget.existingAppointment != null) {
      final apt = widget.existingAppointment!;
      _doctorNameController.text = apt['doctor_name'] ?? '';
      _specialtyController.text = apt['specialty'] ?? '';
      _locationController.text = apt['location'] ?? '';
      _reasonController.text = apt['reason_for_visit'] ?? '';
      _notesController.text = apt['notes'] ?? '';

      if (apt['appointment_date'] != null) {
        final dateTime = DateTime.parse(apt['appointment_date']);
        _appointmentDate = dateTime;
        _appointmentTime = TimeOfDay.fromDateTime(dateTime);
      }

      _visitType = apt['visit_type'] ?? 'in-person';
      _status = apt['status'] ?? 'scheduled';
      _reminder24h = apt['reminder_24h'] ?? true;
      _reminder1h = apt['reminder_1h'] ?? true;
      _durationMinutes = apt['duration_minutes'] ?? 30;
    }
  }

  @override
  void dispose() {
    _doctorNameController.dispose();
    _specialtyController.dispose();
    _locationController.dispose();
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveAppointment() async {
    if (!_formKey.currentState!.validate()) return;

    if (_appointmentDate == null || _appointmentTime == null) {
      Get.snackbar(
        'Required',
        'Please select appointment date and time',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
      return;
    }

    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;

    if (user == null) {
      Get.snackbar(
        'Error',
        'Please log in to add appointments',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
      setState(() => _isLoading = false);
      return;
    }

    // Combine date and time
    final fullDateTime = DateTime(
      _appointmentDate!.year,
      _appointmentDate!.month,
      _appointmentDate!.day,
      _appointmentTime!.hour,
      _appointmentTime!.minute,
    );

    String? result;

    if (widget.existingAppointment != null) {
      // Update existing appointment
      final success = await _appointmentService.updateAppointment(
        appointmentId: widget.existingAppointment!['id'],
        doctorName: _doctorNameController.text.trim(),
        specialty: _specialtyController.text.trim().isEmpty
            ? null
            : _specialtyController.text.trim(),
        appointmentDate: fullDateTime,
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        reasonForVisit: _reasonController.text.trim().isEmpty
            ? null
            : _reasonController.text.trim(),
        visitType: _visitType,
        status: _status,
        reminder24h: _reminder24h,
        reminder1h: _reminder1h,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        durationMinutes: _durationMinutes,
      );

      if (success) {
        result = widget.existingAppointment!['id'];
      }
    } else {
      // Add new appointment
      result = await _appointmentService.addAppointment(
        userId: user.id,
        familyMemberId: widget.familyMemberId, // Include family member ID if provided
        doctorName: _doctorNameController.text.trim(),
        specialty: _specialtyController.text.trim().isEmpty
            ? null
            : _specialtyController.text.trim(),
        appointmentDate: fullDateTime,
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        reasonForVisit: _reasonController.text.trim().isEmpty
            ? null
            : _reasonController.text.trim(),
        visitType: _visitType,
        status: _status,
        reminder24h: _reminder24h,
        reminder1h: _reminder1h,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        durationMinutes: _durationMinutes,
      );
    }

    // Schedule notifications
    if (result != null && _status == 'scheduled') {
      if (_reminder24h) {
        await _notificationService.schedule24HourReminder(
          appointmentId: result,
          doctorName: _doctorNameController.text.trim(),
          appointmentDate: fullDateTime,
          specialty: _specialtyController.text.trim().isEmpty
              ? null
              : _specialtyController.text.trim(),
        );
      }

      if (_reminder1h) {
        await _notificationService.schedule1HourReminder(
          appointmentId: result,
          doctorName: _doctorNameController.text.trim(),
          appointmentDate: fullDateTime,
          specialty: _specialtyController.text.trim().isEmpty
              ? null
              : _specialtyController.text.trim(),
          location: _locationController.text.trim().isEmpty
              ? null
              : _locationController.text.trim(),
        );
      }
    }

    setState(() => _isLoading = false);

    if (result != null) {
      // Navigate back first, then show success message
      Get.back(result: true);

      // Show success message after navigation
      Future.delayed(const Duration(milliseconds: 300), () {
        Get.snackbar(
          'Success',
          widget.existingAppointment != null
              ? 'Appointment updated successfully'
              : 'Appointment added successfully',
          backgroundColor: AppColors.success,
          colorText: Colors.white,
        );
      });
    } else {
      Get.snackbar(
        'Error',
        'Failed to save appointment',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingAppointment != null
            ? 'Edit Appointment'
            : 'Add Appointment'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Doctor Information Section
                  _buildSectionHeader('Doctor Information'),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _doctorNameController,
                    decoration: InputDecoration(
                      labelText: 'Doctor/Provider Name *',
                      hintText: 'e.g., Dr. John Smith',
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter doctor name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _specialtyController,
                    decoration: InputDecoration(
                      labelText: 'Specialty',
                      hintText: 'e.g., Cardiologist, Dentist',
                      prefixIcon: const Icon(Icons.medical_services),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Appointment Details Section
                  _buildSectionHeader('Appointment Details'),
                  const SizedBox(height: 12),

                  // Date picker
                  ListTile(
                    title: const Text('Date *'),
                    subtitle: Text(
                      _appointmentDate != null
                          ? DateFormat('EEE, MMM d, yyyy')
                              .format(_appointmentDate!)
                          : 'Select date',
                    ),
                    leading: Icon(Icons.calendar_today, color: AppColors.primary),
                    trailing: const Icon(Icons.edit),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _appointmentDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2030),
                      );
                      if (date != null) {
                        setState(() => _appointmentDate = date);
                      }
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Time picker
                  ListTile(
                    title: const Text('Time *'),
                    subtitle: Text(
                      _appointmentTime != null
                          ? _appointmentTime!.format(context)
                          : 'Select time',
                    ),
                    leading: Icon(Icons.access_time, color: AppColors.primary),
                    trailing: const Icon(Icons.edit),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: _appointmentTime ?? TimeOfDay.now(),
                      );
                      if (time != null) {
                        setState(() => _appointmentTime = time);
                      }
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Duration
                  DropdownButtonFormField<int>(
                    value: _durationMinutes,
                    decoration: InputDecoration(
                      labelText: 'Duration',
                      prefixIcon: const Icon(Icons.timer),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 15, child: Text('15 minutes')),
                      DropdownMenuItem(value: 30, child: Text('30 minutes')),
                      DropdownMenuItem(value: 45, child: Text('45 minutes')),
                      DropdownMenuItem(value: 60, child: Text('1 hour')),
                      DropdownMenuItem(value: 90, child: Text('1.5 hours')),
                      DropdownMenuItem(value: 120, child: Text('2 hours')),
                    ],
                    onChanged: (value) {
                      setState(() => _durationMinutes = value!);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Visit Type
                  DropdownButtonFormField<String>(
                    value: _visitType,
                    decoration: InputDecoration(
                      labelText: 'Visit Type',
                      prefixIcon: const Icon(Icons.location_on),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'in-person', child: Text('In-Person')),
                      DropdownMenuItem(
                          value: 'online', child: Text('Online Consultation')),
                      DropdownMenuItem(
                          value: 'home-visit', child: Text('Home Visit')),
                    ],
                    onChanged: (value) {
                      setState(() => _visitType = value!);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Location
                  TextFormField(
                    controller: _locationController,
                    decoration: InputDecoration(
                      labelText: 'Location',
                      hintText: 'Hospital, clinic, or address',
                      prefixIcon: const Icon(Icons.place),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),

                  // Reason for Visit
                  TextFormField(
                    controller: _reasonController,
                    decoration: InputDecoration(
                      labelText: 'Reason for Visit',
                      hintText: 'e.g., Routine check-up, Follow-up',
                      prefixIcon: const Icon(Icons.notes),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),

                  // Reminders Section
                  _buildSectionHeader('Reminders'),
                  const SizedBox(height: 12),

                  SwitchListTile(
                    title: const Text('24-hour reminder'),
                    subtitle: const Text('Remind me 1 day before appointment'),
                    value: _reminder24h,
                    onChanged: (value) {
                      setState(() => _reminder24h = value);
                    },
                    activeColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  const SizedBox(height: 8),

                  SwitchListTile(
                    title: const Text('1-hour reminder'),
                    subtitle: const Text('Remind me 1 hour before appointment'),
                    value: _reminder1h,
                    onChanged: (value) {
                      setState(() => _reminder1h = value);
                    },
                    activeColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Additional Notes Section
                  _buildSectionHeader('Additional Notes'),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      labelText: 'Notes',
                      hintText: 'Any additional information',
                      prefixIcon: const Icon(Icons.description),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 32),

                  // Save Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveAppointment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      widget.existingAppointment != null
                          ? 'Update Appointment'
                          : 'Save Appointment',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
