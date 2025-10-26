import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/medication_service.dart';

/// Add Medication Screen with comprehensive form
class AddMedicationScreen extends StatefulWidget {
  final Map<String, dynamic>? medication; // For editing existing medication
  final String? familyMemberId; // Optional: for family member's medications
  final String? familyMemberName; // Optional: for display

  const AddMedicationScreen({
    super.key,
    this.medication,
    this.familyMemberId,
    this.familyMemberName,
  });

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final MedicationService _medicationService = MedicationService();

  // Controllers
  final _nameController = TextEditingController();
  final _genericNameController = TextEditingController();
  final _brandNameController = TextEditingController();
  final _dosageAmountController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _totalQuantityController = TextEditingController();
  final _prescribingDoctorController = TextEditingController();
  final _notesController = TextEditingController();

  // Dropdowns
  String _selectedDosageUnit = 'mg';
  String _selectedForm = 'Tablet';
  bool _isOngoing = true;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;

  bool _isSaving = false;

  final List<String> _dosageUnits = ['mg', 'ml', 'mcg', 'g', 'IU', 'units'];
  final List<String> _medicationForms = [
    'Tablet',
    'Capsule',
    'Syrup',
    'Liquid',
    'Injection',
    'Inhaler',
    'Cream',
    'Ointment',
    'Drops',
    'Patch',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.medication != null) {
      _loadMedicationData();
    }
  }

  void _loadMedicationData() {
    final med = widget.medication!;
    _nameController.text = med['name'] ?? '';
    _genericNameController.text = med['generic_name'] ?? '';
    _brandNameController.text = med['brand_name'] ?? '';
    _dosageAmountController.text = med['dosage_amount']?.toString() ?? '';
    _selectedDosageUnit = med['dosage_unit'] ?? 'mg';
    _selectedForm = med['form'] ?? 'Tablet';
    _instructionsController.text = med['instructions'] ?? '';
    _totalQuantityController.text = med['total_quantity']?.toString() ?? '';
    _prescribingDoctorController.text = med['prescribing_doctor'] ?? '';
    _notesController.text = med['notes'] ?? '';
    _isOngoing = med['is_ongoing'] ?? true;

    if (med['start_date'] != null) {
      _startDate = DateTime.parse(med['start_date']);
    }
    if (med['end_date'] != null) {
      _endDate = DateTime.parse(med['end_date']);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _genericNameController.dispose();
    _brandNameController.dispose();
    _dosageAmountController.dispose();
    _instructionsController.dispose();
    _totalQuantityController.dispose();
    _prescribingDoctorController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveMedication() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;

    if (user == null) {
      Get.snackbar('Error', 'User not found');
      setState(() => _isSaving = false);
      return;
    }

    final dosageAmount = double.tryParse(_dosageAmountController.text);
    final totalQuantity = double.tryParse(_totalQuantityController.text);

    if (dosageAmount == null) {
      Get.snackbar('Error', 'Invalid dosage amount');
      setState(() => _isSaving = false);
      return;
    }

    final result = await _medicationService.addMedication(
      userId: user.id,
      familyMemberId: widget.familyMemberId, // Include family member ID if provided
      name: _nameController.text.trim(),
      genericName: _genericNameController.text.trim().isEmpty
          ? null
          : _genericNameController.text.trim(),
      brandName: _brandNameController.text.trim().isEmpty
          ? null
          : _brandNameController.text.trim(),
      dosageAmount: dosageAmount,
      dosageUnit: _selectedDosageUnit,
      form: _selectedForm,
      prescribingDoctor: _prescribingDoctorController.text.trim().isEmpty
          ? null
          : _prescribingDoctorController.text.trim(),
      totalQuantity: totalQuantity,
      remainingQuantity: totalQuantity,
      startDate: _startDate,
      endDate: _endDate,
      isOngoing: _isOngoing,
      instructions: _instructionsController.text.trim().isEmpty
          ? null
          : _instructionsController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    setState(() => _isSaving = false);

    if (result != null) {
      Get.back(result: true);
      Get.snackbar(
        'Success',
        'Medication added successfully',
        backgroundColor: AppColors.success,
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        'Error',
        'Failed to add medication',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.medication != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Medication' : 'Add Medication'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Basic Information Section
            _buildSectionTitle('Basic Information'),
            const SizedBox(height: 12),

            // Medication Name
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Medication Name *',
                hintText: 'e.g., Paracetamol',
                prefixIcon: const Icon(Icons.medication),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter medication name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Generic Name (Optional)
            TextFormField(
              controller: _genericNameController,
              decoration: InputDecoration(
                labelText: 'Generic Name',
                hintText: 'e.g., Acetaminophen',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Brand Name (Optional)
            TextFormField(
              controller: _brandNameController,
              decoration: InputDecoration(
                labelText: 'Brand Name',
                hintText: 'e.g., Napa, Ace',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Dosage Section
            _buildSectionTitle('Dosage Details'),
            const SizedBox(height: 12),

            // Dosage Amount and Unit
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _dosageAmountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Amount *',
                      hintText: '500',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Required';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Invalid';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    value: _selectedDosageUnit,
                    decoration: InputDecoration(
                      labelText: 'Unit *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: _dosageUnits.map((unit) {
                      return DropdownMenuItem(
                        value: unit,
                        child: Text(unit),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedDosageUnit = value!);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Medication Form
            DropdownButtonFormField<String>(
              value: _selectedForm,
              decoration: InputDecoration(
                labelText: 'Form *',
                prefixIcon: const Icon(Icons.category),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: _medicationForms.map((form) {
                return DropdownMenuItem(
                  value: form,
                  child: Text(form),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedForm = value!);
              },
            ),
            const SizedBox(height: 24),

            // Inventory Section
            _buildSectionTitle('Inventory'),
            const SizedBox(height: 12),

            TextFormField(
              controller: _totalQuantityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Total Quantity',
                hintText: 'e.g., 30 tablets',
                prefixIcon: const Icon(Icons.inventory_2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Schedule Section
            _buildSectionTitle('Schedule'),
            const SizedBox(height: 12),

            // Start Date
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              leading: const Icon(Icons.calendar_today),
              title: const Text('Start Date'),
              subtitle: Text(
                '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (date != null) {
                  setState(() => _startDate = date);
                }
              },
            ),
            const SizedBox(height: 12),

            // Ongoing Switch
            SwitchListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              title: const Text('Ongoing Medication'),
              subtitle: const Text('No end date'),
              value: _isOngoing,
              onChanged: (value) {
                setState(() {
                  _isOngoing = value;
                  if (value) _endDate = null;
                });
              },
            ),

            if (!_isOngoing) ...[
              const SizedBox(height: 12),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                leading: const Icon(Icons.event),
                title: const Text('End Date'),
                subtitle: Text(
                  _endDate != null
                      ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                      : 'Select end date',
                  style: TextStyle(
                    fontWeight: _endDate != null ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _endDate ?? _startDate.add(const Duration(days: 30)),
                    firstDate: _startDate,
                    lastDate: DateTime(2030),
                  );
                  if (date != null) {
                    setState(() => _endDate = date);
                  }
                },
              ),
            ],
            const SizedBox(height: 24),

            // Instructions Section
            _buildSectionTitle('Instructions'),
            const SizedBox(height: 12),

            TextFormField(
              controller: _instructionsController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Instructions',
                hintText: 'e.g., Take with food, Before bed, Avoid milk',
                prefixIcon: const Icon(Icons.info_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Additional Info Section
            _buildSectionTitle('Additional Information'),
            const SizedBox(height: 12),

            TextFormField(
              controller: _prescribingDoctorController,
              decoration: InputDecoration(
                labelText: 'Prescribing Doctor',
                hintText: 'Dr. Name',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Notes',
                hintText: 'Any additional notes',
                prefixIcon: const Icon(Icons.note),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Save Button
            ElevatedButton(
              onPressed: _isSaving ? null : _saveMedication,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      isEditing ? 'Update Medication' : 'Save Medication',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }
}
