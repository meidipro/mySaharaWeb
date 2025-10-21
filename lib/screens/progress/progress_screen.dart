import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_sahara_app/constants/app_colors.dart';
import 'package:my_sahara_app/providers/progress_provider.dart';
import 'package:provider/provider.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final _formKey = GlobalKey<FormState>();

  final _weightController = TextEditingController();
  final _bodyFatController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _waterController = TextEditingController();

  void _saveLog() async {
    if (_formKey.currentState!.validate()) {
      final provider = context.read<ProgressProvider>();

      final data = {
        'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        'weight_kg': double.tryParse(_weightController.text),
        'body_fat_percentage': double.tryParse(_bodyFatController.text),
        'calorie_intake': int.tryParse(_caloriesController.text),
        'water_intake_ml': int.tryParse(_waterController.text),
      };

      // Remove null values
      data.removeWhere((key, value) => value == null);

      if (data.keys.length <= 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter at least one metric to log.')),
        );
        return;
      }

      final success = await provider.saveDailyLog(data);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Log saved successfully!'))
        );
        _formKey.currentState?.reset();
        _weightController.clear();
        _bodyFatController.clear();
        _caloriesController.clear();
        _waterController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error ?? 'Failed to save log.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Your Progress'),
      ),
      body: Consumer<ProgressProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildLogEntryForm(provider.isLoading),
                const SizedBox(height: 24),
                // Progress charts and motivation will go here
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLogEntryForm(bool isLoading) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Log Your Daily Metrics', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          TextFormField(
            controller: _weightController,
            decoration: const InputDecoration(labelText: 'Weight (kg)'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _bodyFatController,
            decoration: const InputDecoration(labelText: 'Body Fat (%)'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _caloriesController,
            decoration: const InputDecoration(labelText: 'Calorie Intake (kcal)'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _waterController,
            decoration: const InputDecoration(labelText: 'Water Intake (ml)'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: isLoading ? null : _saveLog,
            child: isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Save Today\'s Log'),
          ),
        ],
      ),
    );
  }
}
