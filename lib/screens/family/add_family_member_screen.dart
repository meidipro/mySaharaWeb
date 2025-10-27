import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../constants/app_colors.dart';
import '../../models/family_member.dart';
import '../../providers/family_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/chronic_disease_detector.dart';

class AddFamilyMemberScreen extends StatefulWidget {
  final FamilyMember? member; // For editing existing member

  const AddFamilyMemberScreen({super.key, this.member});

  @override
  State<AddFamilyMemberScreen> createState() => _AddFamilyMemberScreenState();
}

class _AddFamilyMemberScreenState extends State<AddFamilyMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final _chronicDiseasesController = TextEditingController();
  final _medicationsController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedRelationship;
  String? _selectedGender;
  String? _selectedBloodGroup;
  DateTime? _selectedDate;
  bool _isLoading = false;
  DiseaseAnalysisResult? _diseaseAnalysis;

  final List<String> _relationships = [
    'Father',
    'Mother',
    'Brother',
    'Sister',
    'Son',
    'Daughter',
    'Spouse',
    'Grandfather',
    'Grandmother',
    'Grandson',
    'Granddaughter',
    'Uncle',
    'Aunt',
    'Nephew',
    'Niece',
    'Cousin',
    'Other',
  ];

  final List<String> _genders = ['Male', 'Female', 'Other'];

  final List<String> _bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];

  @override
  void initState() {
    super.initState();

    // Add listener for real-time disease detection
    _chronicDiseasesController.addListener(_analyzeDiseases);

    if (widget.member != null) {
      _loadExistingMemberData();
    }
  }

  /// Analyze diseases in real-time as user types
  void _analyzeDiseases() {
    final text = _chronicDiseasesController.text;
    setState(() {
      _diseaseAnalysis = ChronicDiseaseDetector.analyzeDiseasesString(text);
    });
  }

  void _loadExistingMemberData() {
    final member = widget.member!;
    _fullNameController.text = member.fullName;
    _selectedRelationship = member.relationship;
    _selectedGender = member.gender;
    _selectedBloodGroup = member.bloodGroup;
    _chronicDiseasesController.text = member.chronicDiseases ?? '';
    _medicationsController.text = member.medications ?? '';
    _allergiesController.text = member.allergies ?? '';
    _notesController.text = member.notes ?? '';

    if (member.dateOfBirth != null) {
      _selectedDate = DateTime.parse(member.dateOfBirth!);
      _dateOfBirthController.text = DateFormat('MMM dd, yyyy').format(_selectedDate!);
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _dateOfBirthController.dispose();
    _chronicDiseasesController.dispose();
    _medicationsController.dispose();
    _allergiesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateOfBirthController.text = DateFormat('MMM dd, yyyy').format(picked);
      });
    }
  }

  Future<void> _saveFamilyMember() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final familyProvider = context.read<FamilyProvider>();

    if (authProvider.user == null) {
      setState(() => _isLoading = false);
      Get.snackbar(
        'Error',
        'User not authenticated',
        backgroundColor: AppColors.error,
        colorText: AppColors.textWhite,
      );
      return;
    }

    final member = FamilyMember(
      id: widget.member?.id,
      userId: authProvider.user!.id,
      fullName: _fullNameController.text.trim(),
      relationship: _selectedRelationship!,
      dateOfBirth: _selectedDate?.toIso8601String(),
      gender: _selectedGender,
      bloodGroup: _selectedBloodGroup,
      chronicDiseases: _chronicDiseasesController.text.trim().isEmpty
          ? null
          : _chronicDiseasesController.text.trim(),
      medications: _medicationsController.text.trim().isEmpty
          ? null
          : _medicationsController.text.trim(),
      allergies: _allergiesController.text.trim().isEmpty
          ? null
          : _allergiesController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      createdAt: widget.member?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    bool success;
    if (widget.member == null) {
      success = await familyProvider.addFamilyMember(member);
    } else {
      success = await familyProvider.updateFamilyMember(member);
    }

    setState(() => _isLoading = false);

    if (success) {
      Get.back();
      Get.snackbar(
        'Success',
        widget.member == null
            ? 'Family member added successfully'
            : 'Family member updated successfully',
        backgroundColor: AppColors.success,
        colorText: AppColors.textWhite,
        snackPosition: SnackPosition.BOTTOM,
      );
      familyProvider.loadFamilyMembersWithProfile();
    } else {
      Get.snackbar(
        'Error',
        familyProvider.errorMessage ?? 'Failed to save family member',
        backgroundColor: AppColors.error,
        colorText: AppColors.textWhite,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.member == null ? 'Add Family Member' : 'Edit Family Member'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Full Name
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter full name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Relationship
              DropdownButtonFormField<String>(
                value: _selectedRelationship,
                decoration: const InputDecoration(
                  labelText: 'Relationship',
                  prefixIcon: Icon(Icons.family_restroom),
                  border: OutlineInputBorder(),
                ),
                items: _relationships
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (value) {
                  setState(() => _selectedRelationship = value);
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select relationship';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Date of Birth
              TextFormField(
                controller: _dateOfBirthController,
                decoration: const InputDecoration(
                  labelText: 'Date of Birth (Optional)',
                  prefixIcon: Icon(Icons.cake),
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 16),

              // Gender
              DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: const InputDecoration(
                  labelText: 'Gender (Optional)',
                  prefixIcon: Icon(Icons.wc),
                  border: OutlineInputBorder(),
                ),
                items: _genders
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (value) {
                  setState(() => _selectedGender = value);
                },
              ),
              const SizedBox(height: 16),

              // Blood Group
              DropdownButtonFormField<String>(
                value: _selectedBloodGroup,
                decoration: const InputDecoration(
                  labelText: 'Blood Group (Optional)',
                  prefixIcon: Icon(Icons.bloodtype),
                  border: OutlineInputBorder(),
                ),
                items: _bloodGroups
                    .map((bg) => DropdownMenuItem(value: bg, child: Text(bg)))
                    .toList(),
                onChanged: (value) {
                  setState(() => _selectedBloodGroup = value);
                },
              ),
              const SizedBox(height: 16),

              // Diseases
              TextFormField(
                controller: _chronicDiseasesController,
                decoration: const InputDecoration(
                  labelText: 'Diseases (Optional)',
                  hintText: 'Enter diseases separated by commas',
                  helperText: 'e.g., Diabetes, Hypertension, Asthma',
                  prefixIcon: Icon(Icons.medical_services),
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),

              // Disease Detection Results
              if (_diseaseAnalysis != null && _diseaseAnalysis!.totalCount > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _diseaseAnalysis!.hasChronicDiseases
                        ? AppColors.error.withOpacity(0.1)
                        : AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _diseaseAnalysis!.hasChronicDiseases
                          ? AppColors.error.withOpacity(0.3)
                          : AppColors.success.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Summary
                      Row(
                        children: [
                          Icon(
                            _diseaseAnalysis!.hasChronicDiseases
                                ? Icons.warning_amber_rounded
                                : Icons.check_circle,
                            color: _diseaseAnalysis!.hasChronicDiseases
                                ? AppColors.error
                                : AppColors.success,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              ChronicDiseaseDetector.getSummaryMessage(_diseaseAnalysis!),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _diseaseAnalysis!.hasChronicDiseases
                                    ? AppColors.error
                                    : AppColors.success,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Chronic Diseases
                      if (_diseaseAnalysis!.chronicDiseases.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Chronic Conditions:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _diseaseAnalysis!.chronicDiseases.map((disease) {
                            return Chip(
                              avatar: CircleAvatar(
                                backgroundColor: AppColors.error,
                                child: Icon(Icons.medical_services, size: 14, color: Colors.white),
                              ),
                              label: Text(disease),
                              backgroundColor: AppColors.error.withOpacity(0.15),
                              labelStyle: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppColors.error,
                              ),
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            );
                          }).toList(),
                        ),
                      ],

                      // Acute Diseases
                      if (_diseaseAnalysis!.acuteDiseases.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Acute/Temporary Conditions:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _diseaseAnalysis!.acuteDiseases.map((disease) {
                            return Chip(
                              avatar: CircleAvatar(
                                backgroundColor: AppColors.success,
                                child: Icon(Icons.check, size: 14, color: Colors.white),
                              ),
                              label: Text(disease),
                              backgroundColor: AppColors.success.withOpacity(0.15),
                              labelStyle: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppColors.success,
                              ),
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // Medications
              TextFormField(
                controller: _medicationsController,
                decoration: const InputDecoration(
                  labelText: 'Current Medications (Optional)',
                  prefixIcon: Icon(Icons.medication),
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Aspirin, Metformin',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // Allergies
              TextFormField(
                controller: _allergiesController,
                decoration: const InputDecoration(
                  labelText: 'Allergies (Optional)',
                  prefixIcon: Icon(Icons.warning_amber),
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Penicillin, Peanuts',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // Notes
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Additional Notes (Optional)',
                  prefixIcon: Icon(Icons.notes),
                  border: OutlineInputBorder(),
                  hintText: 'Any other important information',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Save Button
              ElevatedButton(
                onPressed: _isLoading ? null : _saveFamilyMember,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textWhite,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textWhite,
                        ),
                      )
                    : Text(
                        widget.member == null ? 'Add Family Member' : 'Update Family Member',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
