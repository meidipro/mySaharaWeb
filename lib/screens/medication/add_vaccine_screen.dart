import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/medication_service.dart';

/// Add Vaccine Screen - Form to add new vaccine record
class AddVaccineScreen extends StatefulWidget {
  const AddVaccineScreen({super.key});

  @override
  State<AddVaccineScreen> createState() => _AddVaccineScreenState();
}

class _AddVaccineScreenState extends State<AddVaccineScreen> {
  final _formKey = GlobalKey<FormState>();
  final MedicationService _medicationService = MedicationService();

  // Form controllers
  final _vaccineNameController = TextEditingController();
  final _vaccineTypeController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();

  // Form values
  int _doseNumber = 1;
  int? _totalDoses;
  DateTime? _administeredDate;
  DateTime? _nextDueDate;
  String _status = 'completed';
  bool _isLoading = false;

  @override
  void dispose() {
    _vaccineNameController.dispose();
    _vaccineTypeController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveVaccine() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;

    if (user == null) {
      Get.snackbar(
        'Error',
        'Please log in to add vaccines',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
      setState(() => _isLoading = false);
      return;
    }

    final result = await _medicationService.addVaccine(
      userId: user.id,
      vaccineName: _vaccineNameController.text.trim(),
      vaccineType: _vaccineTypeController.text.trim().isEmpty ? null : _vaccineTypeController.text.trim(),
      doseNumber: _doseNumber,
      totalDoses: _totalDoses,
      administeredDate: _administeredDate,
      nextDueDate: _nextDueDate,
      location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
      status: _status,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (result != null) {
      Get.snackbar(
        'Success',
        'Vaccine record added successfully',
        backgroundColor: AppColors.success,
        colorText: Colors.white,
      );
      Get.back(result: true);
    } else {
      Get.snackbar(
        'Error',
        'Failed to add vaccine record',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Vaccine'),
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
                  // Vaccine Information Section
                  _buildSectionHeader('Vaccine Information'),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _vaccineNameController,
                    decoration: InputDecoration(
                      labelText: 'Vaccine Name *',
                      hintText: 'e.g., COVID-19, Hepatitis B',
                      prefixIcon: const Icon(Icons.vaccines),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter vaccine name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _vaccineTypeController,
                    decoration: InputDecoration(
                      labelText: 'Vaccine Type',
                      hintText: 'e.g., mRNA, Inactivated',
                      prefixIcon: const Icon(Icons.category),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _locationController,
                    decoration: InputDecoration(
                      labelText: 'Location',
                      hintText: 'Where vaccine was administered',
                      prefixIcon: const Icon(Icons.location_on),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Dose Information Section
                  _buildSectionHeader('Dose Information'),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _doseNumber,
                          decoration: InputDecoration(
                            labelText: 'Dose Number *',
                            prefixIcon: const Icon(Icons.filter_1),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          items: List.generate(10, (index) => index + 1)
                              .map((num) => DropdownMenuItem(
                                    value: num,
                                    child: Text('Dose $num'),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() => _doseNumber = value!);
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<int?>(
                          value: _totalDoses,
                          decoration: InputDecoration(
                            labelText: 'Total Doses',
                            prefixIcon: const Icon(Icons.format_list_numbered),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('Not specified')),
                            ...List.generate(10, (index) => index + 1)
                                .map((num) => DropdownMenuItem(
                                      value: num,
                                      child: Text('$num doses'),
                                    ))
                                .toList(),
                          ],
                          onChanged: (value) {
                            setState(() => _totalDoses = value);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    value: _status,
                    decoration: InputDecoration(
                      labelText: 'Status *',
                      prefixIcon: const Icon(Icons.check_circle),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'completed', child: Text('Completed')),
                      DropdownMenuItem(value: 'scheduled', child: Text('Scheduled')),
                      DropdownMenuItem(value: 'overdue', child: Text('Overdue')),
                    ],
                    onChanged: (value) {
                      setState(() => _status = value!);
                    },
                  ),
                  const SizedBox(height: 24),

                  // Dates Section
                  _buildSectionHeader('Dates'),
                  const SizedBox(height: 12),

                  ListTile(
                    title: const Text('Date Administered'),
                    subtitle: Text(
                      _administeredDate != null
                          ? '${_administeredDate!.day}/${_administeredDate!.month}/${_administeredDate!.year}'
                          : 'Not set',
                    ),
                    leading: const Icon(Icons.calendar_today),
                    trailing: const Icon(Icons.edit),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _administeredDate ?? DateTime.now(),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() => _administeredDate = date);
                      }
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  const SizedBox(height: 12),

                  ListTile(
                    title: const Text('Next Due Date'),
                    subtitle: Text(
                      _nextDueDate != null
                          ? '${_nextDueDate!.day}/${_nextDueDate!.month}/${_nextDueDate!.year}'
                          : 'Not set',
                    ),
                    leading: const Icon(Icons.event),
                    trailing: const Icon(Icons.edit),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _nextDueDate ?? DateTime.now().add(const Duration(days: 30)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (date != null) {
                        setState(() => _nextDueDate = date);
                      }
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Notes Section
                  _buildSectionHeader('Additional Notes'),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      labelText: 'Notes',
                      hintText: 'Any additional information or side effects',
                      prefixIcon: const Icon(Icons.notes),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 32),

                  // Save Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveVaccine,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Save Vaccine Record',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
