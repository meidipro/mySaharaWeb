import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/medication_service.dart';
import '../../services/medication_notification_service.dart';

/// Simplified Add Medication Screen
class AddMedicationScreenSimple extends StatefulWidget {
  final String? familyMemberId;
  final String? familyMemberName;

  const AddMedicationScreenSimple({
    super.key,
    this.familyMemberId,
    this.familyMemberName,
  });

  @override
  State<AddMedicationScreenSimple> createState() => _AddMedicationScreenSimpleState();
}

class _AddMedicationScreenSimpleState extends State<AddMedicationScreenSimple> {
  final _formKey = GlobalKey<FormState>();
  final MedicationService _medicationService = MedicationService();
  final MedicationNotificationService _notificationService =
      MedicationNotificationService();

  // Form controllers
  final _nameController = TextEditingController();
  final _dosageAmountController = TextEditingController();
  final _quantityController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _notesController = TextEditingController();

  // Form values
  String _form = 'tablet';
  String _dosageUnit = 'mg';
  int _frequencyPerDay = 1;
  Set<String> _selectedTimings = {};
  Map<String, TimeOfDay> _reminderTimes = {};
  String _foodTiming = 'anytime';
  DateTime? _startDate;
  bool _isOngoing = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _dosageAmountController.dispose();
    _quantityController.dispose();
    _instructionsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveMedication() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedTimings.isEmpty) {
      Get.snackbar(
        'Required',
        'Please select at least one timing (Morning, Afternoon, Evening, or Night)',
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
        'Please log in to add medications',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
      setState(() => _isLoading = false);
      return;
    }

    // Prepare reminder times list
    final reminderTimesList = _reminderTimes.entries
        .map((e) => '${e.value.hour.toString().padLeft(2, '0')}:${e.value.minute.toString().padLeft(2, '0')}')
        .toList();

    // Determine food timing booleans
    final takeWithFood = _foodTiming == 'with_food';
    final takeOnEmptyStomach = _foodTiming == 'empty_stomach';
    final takeBeforeMeal = _foodTiming == 'before_meal';
    final takeAfterMeal = _foodTiming == 'after_meal';

    // For topical medications (cream/ointment), use default dosage values
    final isTopical = _isTopicalMedication();
    final dosageAmount = isTopical ? 1.0 : double.parse(_dosageAmountController.text.trim());
    final dosageUnit = isTopical ? 'application' : _dosageUnit;

    final result = await _medicationService.addMedication(
      userId: user.id,
      familyMemberId: widget.familyMemberId,
      name: _nameController.text.trim(),
      form: _form,
      dosageAmount: dosageAmount,
      dosageUnit: dosageUnit,
      frequencyPerDay: _frequencyPerDay,
      timing: _selectedTimings.toList(),
      reminderTimes: reminderTimesList.isEmpty ? null : reminderTimesList,
      takeWithFood: takeWithFood,
      takeOnEmptyStomach: takeOnEmptyStomach,
      takeBeforeMeal: takeBeforeMeal,
      takeAfterMeal: takeAfterMeal,
      startDate: _startDate ?? DateTime.now(),
      isOngoing: _isOngoing,
      totalQuantity: _quantityController.text.isEmpty
          ? null
          : double.parse(_quantityController.text),
      instructions: _instructionsController.text.isEmpty
          ? null
          : _instructionsController.text.trim(),
      notes: _notesController.text.isEmpty
          ? null
          : _notesController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (result != null) {
      // Schedule notifications for each reminder time
      for (var entry in _reminderTimes.entries) {
        final timing = entry.key;
        final time = entry.value;

        // Build dosage string for notification
        final dosageString = isTopical
            ? 'Apply as directed'
            : '${_dosageAmountController.text} $_dosageUnit';

        await _notificationService.scheduleDailyReminder(
          medicationId: '$result-$timing',
          medicationName: _nameController.text.trim(),
          dosage: dosageString,
          hour: time.hour,
          minute: time.minute,
          instructions: _getFoodTimingInstruction(),
        );
      }

      // Navigate back first, then show success
      Get.back(result: true);

      Future.delayed(const Duration(milliseconds: 300), () {
        Get.snackbar(
          'Success',
          'Medication added successfully',
          backgroundColor: AppColors.success,
          colorText: Colors.white,
        );
      });
    } else {
      Get.snackbar(
        'Error',
        'Failed to add medication',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }

  String _getFoodTimingInstruction() {
    switch (_foodTiming) {
      case 'empty_stomach':
        return 'Take with empty stomach - Don\'t eat for 30 minutes after';
      case 'with_food':
        return 'Take with food';
      case 'before_meal':
        return 'Take before meal';
      case 'after_meal':
        return 'Take after meal';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Medication'),
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
                  // Medicine Name
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Medicine Name *',
                      hintText: 'e.g., Napa, Esomeprazole',
                      prefixIcon: const Icon(Icons.medication),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter medicine name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Form (Type)
                  DropdownButtonFormField<String>(
                    value: _form,
                    decoration: InputDecoration(
                      labelText: 'Form *',
                      prefixIcon: const Icon(Icons.category),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'tablet', child: Text('Tablet')),
                      DropdownMenuItem(value: 'capsule', child: Text('Capsule')),
                      DropdownMenuItem(value: 'syrup', child: Text('Syrup')),
                      DropdownMenuItem(value: 'liquid', child: Text('Liquid')),
                      DropdownMenuItem(value: 'drops', child: Text('Drops')),
                      DropdownMenuItem(value: 'inhaler', child: Text('Inhaler')),
                      DropdownMenuItem(value: 'injection', child: Text('Injection')),
                      DropdownMenuItem(value: 'cream', child: Text('Cream')),
                      DropdownMenuItem(value: 'ointment', child: Text('Ointment')),
                    ],
                    onChanged: (value) {
                      setState(() => _form = value!);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Dosage (optional for cream/ointment)
                  if (!_isTopicalMedication())
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _dosageAmountController,
                            decoration: InputDecoration(
                              labelText: 'Amount *',
                              hintText: '500',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (_isTopicalMedication()) return null; // Skip validation for topical
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Invalid number';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            value: _dosageUnit,
                            decoration: InputDecoration(
                              labelText: 'Unit *',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'mg', child: Text('mg')),
                              DropdownMenuItem(value: 'g', child: Text('g')),
                              DropdownMenuItem(value: 'ml', child: Text('ml')),
                              DropdownMenuItem(value: 'mcg', child: Text('mcg')),
                              DropdownMenuItem(value: 'IU', child: Text('IU')),
                              DropdownMenuItem(value: 'drops', child: Text('drops')),
                              DropdownMenuItem(value: 'puffs', child: Text('puffs')),
                            ],
                            onChanged: (value) {
                            setState(() => _dosageUnit = value!);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Frequency per day
                  Text(
                    'How many times per day? *',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildFrequencyChip('1 time', 1),
                      const SizedBox(width: 8),
                      _buildFrequencyChip('2 times', 2),
                      const SizedBox(width: 8),
                      _buildFrequencyChip('3 times', 3),
                      const SizedBox(width: 8),
                      _buildFrequencyChip('4 times', 4),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Timing selection
                  Text(
                    'When to take? *',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildTimingChip('Morning', 'morning'),
                      _buildTimingChip('Afternoon', 'afternoon'),
                      _buildTimingChip('Evening', 'evening'),
                      _buildTimingChip('Night', 'night'),
                      _buildTimingChip('Before Sleep', 'before_sleep'),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Set specific times
                  if (_selectedTimings.isNotEmpty) ...[
                    Text(
                      'Set Reminder Times (Optional)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._selectedTimings.map((timing) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text(_getTimingLabel(timing)),
                          subtitle: Text(
                            _reminderTimes[timing] != null
                                ? _reminderTimes[timing]!.format(context)
                                : 'Tap to set time',
                          ),
                          leading: Icon(Icons.access_time, color: AppColors.primary),
                          trailing: const Icon(Icons.edit),
                          onTap: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: _reminderTimes[timing] ?? _getDefaultTime(timing),
                            );
                            if (time != null) {
                              setState(() => _reminderTimes[timing] = time);
                            }
                          },
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 24),
                  ],

                  // Food timing
                  Text(
                    'Food Timing *',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...[
                    _buildFoodTimingRadio('Anytime', 'anytime'),
                    _buildFoodTimingRadio('With food', 'with_food'),
                    _buildFoodTimingRadio('On empty stomach', 'empty_stomach'),
                    _buildFoodTimingRadio('Before meal', 'before_meal'),
                    _buildFoodTimingRadio('After meal', 'after_meal'),
                  ],
                  const SizedBox(height: 24),

                  // Start date
                  ListTile(
                    title: const Text('Start Date *'),
                    subtitle: Text(
                      _startDate != null
                          ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                          : 'Today',
                    ),
                    leading: Icon(Icons.calendar_today, color: AppColors.primary),
                    trailing: const Icon(Icons.edit),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _startDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2030),
                      );
                      if (date != null) {
                        setState(() => _startDate = date);
                      }
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Ongoing checkbox
                  CheckboxListTile(
                    title: const Text('Ongoing (no end date)'),
                    value: _isOngoing,
                    onChanged: (value) {
                      setState(() => _isOngoing = value!);
                    },
                    activeColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Quantity
                  TextFormField(
                    controller: _quantityController,
                    decoration: InputDecoration(
                      labelText: 'Total Quantity (Optional)',
                      hintText: '30',
                      helperText: 'Number of tablets/doses you have',
                      prefixIcon: const Icon(Icons.inventory),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),

                  // Instructions
                  TextFormField(
                    controller: _instructionsController,
                    decoration: InputDecoration(
                      labelText: 'Special Instructions (Optional)',
                      hintText: 'e.g., Apply on affected skin, Shake well',
                      prefixIcon: const Icon(Icons.info_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),

                  // Notes
                  TextFormField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      labelText: 'Notes (Optional)',
                      hintText: 'Any additional notes',
                      prefixIcon: const Icon(Icons.notes),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 32),

                  // Save button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveMedication,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Save Medication',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  Widget _buildFrequencyChip(String label, int value) {
    final isSelected = _frequencyPerDay == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _frequencyPerDay = value);
      },
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
      ),
    );
  }

  Widget _buildTimingChip(String label, String value) {
    final isSelected = _selectedTimings.contains(value);
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedTimings.add(value);
            // Set default time if not set
            if (!_reminderTimes.containsKey(value)) {
              _reminderTimes[value] = _getDefaultTime(value);
            }
          } else {
            _selectedTimings.remove(value);
            _reminderTimes.remove(value);
          }
        });
      },
      selectedColor: AppColors.primary,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
      ),
    );
  }

  Widget _buildFoodTimingRadio(String label, String value) {
    return RadioListTile<String>(
      title: Text(label),
      value: value,
      groupValue: _foodTiming,
      onChanged: (value) {
        setState(() => _foodTiming = value!);
      },
      activeColor: AppColors.primary,
    );
  }

  String _getTimingLabel(String timing) {
    switch (timing) {
      case 'morning':
        return 'Morning';
      case 'afternoon':
        return 'Afternoon';
      case 'evening':
        return 'Evening';
      case 'night':
        return 'Night';
      case 'before_sleep':
        return 'Before Sleep';
      default:
        return timing;
    }
  }

  TimeOfDay _getDefaultTime(String timing) {
    switch (timing) {
      case 'morning':
        return const TimeOfDay(hour: 8, minute: 0);
      case 'afternoon':
        return const TimeOfDay(hour: 14, minute: 0);
      case 'evening':
        return const TimeOfDay(hour: 18, minute: 0);
      case 'night':
        return const TimeOfDay(hour: 21, minute: 0);
      case 'before_sleep':
        return const TimeOfDay(hour: 22, minute: 0);
      default:
        return const TimeOfDay(hour: 12, minute: 0);
    }
  }

  /// Check if the selected form is a topical medication (cream/ointment)
  bool _isTopicalMedication() {
    return _form == 'cream' || _form == 'ointment';
  }
}
