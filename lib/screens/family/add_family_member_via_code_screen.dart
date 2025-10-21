import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../providers/family_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/family_service.dart';

/// Screen to add family member using their unique family code
class AddFamilyMemberViaCodeScreen extends StatefulWidget {
  const AddFamilyMemberViaCodeScreen({super.key});

  @override
  State<AddFamilyMemberViaCodeScreen> createState() => _AddFamilyMemberViaCodeScreenState();
}

class _AddFamilyMemberViaCodeScreenState extends State<AddFamilyMemberViaCodeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _familyCodeController = TextEditingController();
  final _familyService = FamilyService();

  String? _selectedRelationship;
  bool _isLoading = false;
  String? _myFamilyCode;

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
    'Partner',
    'Guardian',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadMyFamilyCode();
  }

  Future<void> _loadMyFamilyCode() async {
    final code = await _familyService.getMyFamilyCode();
    setState(() {
      _myFamilyCode = code;
    });
  }

  @override
  void dispose() {
    _familyCodeController.dispose();
    super.dispose();
  }

  Future<void> _connectWithFamilyMember() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;

    if (currentUser == null) {
      Get.snackbar(
        'Error',
        'You must be logged in to add family members',
        backgroundColor: AppColors.error,
        colorText: AppColors.textWhite,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _familyService.connectWithFamilyCode(
        familyCode: _familyCodeController.text.trim().toUpperCase(),
        relationship: _selectedRelationship!,
        currentUserId: currentUser.id,
      );

      // Refresh family list and health summary
      if (mounted) {
        final familyProvider = Provider.of<FamilyProvider>(context, listen: false);
        await Future.wait([
          familyProvider.loadFamilyMembers(),
          familyProvider.loadFamilyMembersWithProfile(),
          familyProvider.loadHealthSummary(),
        ]);
      }

      Get.snackbar(
        'Success',
        'Successfully added ${result['targetUser'].fullName ?? 'family member'} to your family!',
        backgroundColor: AppColors.success,
        colorText: AppColors.textWhite,
        duration: const Duration(seconds: 3),
        icon: const Icon(Icons.check_circle, color: Colors.white),
      );

      Get.back();
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString().replaceAll('Exception: ', ''),
        backgroundColor: AppColors.error,
        colorText: AppColors.textWhite,
        duration: const Duration(seconds: 4),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _copyMyCode() {
    if (_myFamilyCode != null) {
      Clipboard.setData(ClipboardData(text: _myFamilyCode!));
      Get.snackbar(
        'Copied',
        'Your family code has been copied to clipboard',
        backgroundColor: AppColors.success,
        colorText: AppColors.textWhite,
        duration: const Duration(seconds: 2),
        icon: const Icon(Icons.check_circle, color: Colors.white),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Family Member'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // My Family Code Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.qr_code_2,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'My Family Code',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _myFamilyCode ?? 'Loading...',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 3,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _myFamilyCode != null ? _copyMyCode : null,
                          icon: const Icon(Icons.copy, color: Colors.white),
                          tooltip: 'Copy my code',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.white70, size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Share this code with family members so they can add you',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Instructions
              const Text(
                'Add a Family Member',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter their unique family code to connect and access their medical history (with permission)',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 24),

              // Family Code Input
              TextFormField(
                controller: _familyCodeController,
                decoration: InputDecoration(
                  labelText: 'Family Code',
                  hintText: 'Enter 8-character code',
                  prefixIcon: const Icon(Icons.family_restroom),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(8),
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
                ],
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  fontFamily: 'monospace',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a family code';
                  }
                  if (value.length != 8) {
                    return 'Family code must be exactly 8 characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Relationship Dropdown
              DropdownButtonFormField<String>(
                value: _selectedRelationship,
                decoration: InputDecoration(
                  labelText: 'Relationship',
                  prefixIcon: const Icon(Icons.people),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                items: _relationships.map((String relationship) {
                  return DropdownMenuItem<String>(
                    value: relationship,
                    child: Text(relationship),
                  );
                }).toList(),
                onChanged: (String? value) {
                  setState(() {
                    _selectedRelationship = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a relationship';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 32),

              // Benefits Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.accent.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.verified_user, color: AppColors.accent, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Benefits of Connecting',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildBenefitItem('View family medical history for genetic insights'),
                    _buildBenefitItem('Track chronic diseases in your family'),
                    _buildBenefitItem('Share medical information with doctors'),
                    _buildBenefitItem('Automatic updates when family updates their records'),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _connectWithFamilyMember,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textWhite,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_add),
                            SizedBox(width: 12),
                            Text(
                              'Add Family Member',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // Security Note
              Row(
                children: [
                  const Icon(Icons.lock, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'All medical data is encrypted and only accessible with permission',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, color: AppColors.success, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
