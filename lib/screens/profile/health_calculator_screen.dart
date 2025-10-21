import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';

class HealthCalculatorScreen extends StatefulWidget {
  const HealthCalculatorScreen({super.key});

  @override
  State<HealthCalculatorScreen> createState() => _HealthCalculatorScreenState();
}

class _HealthCalculatorScreenState extends State<HealthCalculatorScreen> {
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _ageController = TextEditingController();

  String _selectedGender = 'male';
  String _activityLevel = 'sedentary';
  double? _bmi;
  double? _bmr;
  String? _bmiCategory;
  String? _bmiDescription;

  final Map<String, String> _activityLevels = {
    'sedentary': 'Sedentary (little or no exercise)',
    'light': 'Lightly active (1-3 days/week)',
    'moderate': 'Moderately active (3-5 days/week)',
    'active': 'Very active (6-7 days/week)',
    'extra': 'Extra active (physical job or training)',
  };

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;

    if (user != null) {
      if (user.gender != null) {
        _selectedGender = user.gender!;
      }

      // Calculate age from date of birth
      if (user.dateOfBirth != null) {
        try {
          final birthDate = DateTime.parse(user.dateOfBirth!);
          final age = DateTime.now().year - birthDate.year;
          _ageController.text = age.toString();
        } catch (e) {
          debugPrint('Error parsing date: $e');
        }
      }
    }
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _calculate() async {
    if (_heightController.text.isEmpty ||
        _weightController.text.isEmpty ||
        _ageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    final height = double.tryParse(_heightController.text);
    final weight = double.tryParse(_weightController.text);
    final age = int.tryParse(_ageController.text);

    if (height == null || weight == null || age == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid numbers')),
      );
      return;
    }

    setState(() {
      // Calculate BMI
      final heightInMeters = height / 100;
      _bmi = weight / (heightInMeters * heightInMeters);

      // Determine BMI category
      if (_bmi! < 18.5) {
        _bmiCategory = 'Underweight';
        _bmiDescription = 'You may need to gain weight. Consult a healthcare provider.';
      } else if (_bmi! < 25) {
        _bmiCategory = 'Normal weight';
        _bmiDescription = 'You have a healthy weight. Keep it up!';
      } else if (_bmi! < 30) {
        _bmiCategory = 'Overweight';
        _bmiDescription = 'You may want to consider losing weight for better health.';
      } else {
        _bmiCategory = 'Obese';
        _bmiDescription = 'Consider consulting a healthcare provider for weight management.';
      }

      // Calculate BMR (Mifflin-St Jeor Equation)
      if (_selectedGender == 'male') {
        _bmr = (10 * weight) + (6.25 * height) - (5 * age) + 5;
      } else {
        _bmr = (10 * weight) + (6.25 * height) - (5 * age) - 161;
      }
    });

    // Save height and weight to user profile
    await _saveToProfile(height, weight);
  }

  Future<void> _saveToProfile(double height, double weight) async {
    try {
      final authProvider = context.read<AuthProvider>();
      final currentUser = authProvider.user;

      if (currentUser == null) return;

      final updatedUser = UserModel(
        id: currentUser.id,
        email: currentUser.email,
        fullName: currentUser.fullName,
        phoneNumber: currentUser.phoneNumber,
        dateOfBirth: currentUser.dateOfBirth,
        gender: _selectedGender,
        bloodGroup: currentUser.bloodGroup,
        height: height,
        weight: weight,
        profileImageUrl: currentUser.profileImageUrl,
        createdAt: currentUser.createdAt,
        updatedAt: DateTime.now(),
      );

      final success = await authProvider.updateProfile(updatedUser);

      if (success && mounted) {
        Get.snackbar(
          'Success',
          'Health metrics saved successfully',
          backgroundColor: AppColors.success,
          colorText: AppColors.textWhite,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      debugPrint('Error saving to profile: $e');
    }
  }

  double? _calculateCalories() {
    if (_bmr == null) return null;

    final multipliers = {
      'sedentary': 1.2,
      'light': 1.375,
      'moderate': 1.55,
      'active': 1.725,
      'extra': 1.9,
    };

    return _bmr! * (multipliers[_activityLevel] ?? 1.2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Calculator'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info Card
            Card(
              color: AppColors.primary.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          'BMI & BMR Calculator',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Calculate your Body Mass Index (BMI) and Basal Metabolic Rate (BMR) to understand your health metrics.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Input Fields
            TextField(
              controller: _heightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Height (cm)',
                prefixIcon: Icon(Icons.height),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _weightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Weight (kg)',
                prefixIcon: Icon(Icons.monitor_weight_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Age',
                prefixIcon: Icon(Icons.cake_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Gender Selection
            DropdownButtonFormField<String>(
              value: _selectedGender,
              decoration: const InputDecoration(
                labelText: 'Gender',
                prefixIcon: Icon(Icons.wc_outlined),
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'male', child: Text('Male')),
                DropdownMenuItem(value: 'female', child: Text('Female')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedGender = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Activity Level
            DropdownButtonFormField<String>(
              value: _activityLevel,
              decoration: const InputDecoration(
                labelText: 'Activity Level',
                prefixIcon: Icon(Icons.directions_run),
                border: OutlineInputBorder(),
              ),
              items: _activityLevels.entries.map((entry) {
                return DropdownMenuItem(
                  value: entry.key,
                  child: Text(
                    entry.value,
                    style: const TextStyle(fontSize: 14),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _activityLevel = value;
                  });
                }
              },
            ),
            const SizedBox(height: 24),

            // Calculate Button
            ElevatedButton(
              onPressed: _calculate,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Calculate',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 32),

            // Results
            if (_bmi != null) ...[
              // BMI Result
              _buildResultCard(
                title: 'BMI (Body Mass Index)',
                value: _bmi!.toStringAsFixed(1),
                category: _bmiCategory!,
                description: _bmiDescription!,
                color: _getBMIColor(_bmi!),
                icon: Icons.analytics_outlined,
              ),
              const SizedBox(height: 16),

              // BMR Result
              _buildResultCard(
                title: 'BMR (Basal Metabolic Rate)',
                value: '${_bmr!.toStringAsFixed(0)} kcal/day',
                category: 'Daily calories at rest',
                description:
                    'This is the number of calories your body needs to maintain basic functions at rest.',
                color: AppColors.healthBlue,
                icon: Icons.local_fire_department_outlined,
              ),
              const SizedBox(height: 16),

              // Daily Calories
              _buildResultCard(
                title: 'Daily Calorie Needs',
                value: '${_calculateCalories()!.toStringAsFixed(0)} kcal/day',
                category: 'Based on your activity level',
                description:
                    'This is the total number of calories you need per day to maintain your current weight.',
                color: AppColors.healthGreen,
                icon: Icons.restaurant_outlined,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard({
    required String title,
    required String value,
    required String category,
    required String description,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              category,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: color.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getBMIColor(double bmi) {
    if (bmi < 18.5) {
      return AppColors.warning;
    } else if (bmi < 25) {
      return AppColors.success;
    } else if (bmi < 30) {
      return AppColors.healthOrange;
    } else {
      return AppColors.error;
    }
  }
}
