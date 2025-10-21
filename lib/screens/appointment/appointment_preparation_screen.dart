import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../services/appointment_service.dart';
import '../../services/ai_service.dart';

/// Appointment Preparation Screen - Pre-appointment checklist and AI assistant
class AppointmentPreparationScreen extends StatefulWidget {
  final Map<String, dynamic> appointment;

  const AppointmentPreparationScreen({super.key, required this.appointment});

  @override
  State<AppointmentPreparationScreen> createState() =>
      _AppointmentPreparationScreenState();
}

class _AppointmentPreparationScreenState
    extends State<AppointmentPreparationScreen> with SingleTickerProviderStateMixin {
  final AppointmentService _appointmentService = AppointmentService();
  late TabController _tabController;

  Map<String, dynamic>? _preparation;
  bool _isLoading = true;
  bool _isGeneratingAI = false;

  // Controllers for text inputs
  final _questionController = TextEditingController();
  final _symptomController = TextEditingController();
  final _medicationController = TextEditingController();
  final _documentController = TextEditingController();
  final _updatesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadPreparation();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _questionController.dispose();
    _symptomController.dispose();
    _medicationController.dispose();
    _documentController.dispose();
    _updatesController.dispose();
    super.dispose();
  }

  Future<void> _loadPreparation() async {
    setState(() => _isLoading = true);

    final prep =
        await _appointmentService.getPreparation(widget.appointment['id']);

    setState(() {
      _preparation = prep;
      if (prep != null && prep['updates_since_last_visit'] != null) {
        _updatesController.text = prep['updates_since_last_visit'];
      }
      _isLoading = false;
    });
  }

  Future<void> _generateAISuggestions() async {
    setState(() => _isGeneratingAI = true);

    try {
      final doctorName = widget.appointment['doctor_name'];
      final specialty = widget.appointment['specialty'];
      final reason = widget.appointment['reason_for_visit'];
      final appointmentDate =
          DateTime.parse(widget.appointment['appointment_date']);

      // Build context for AI
      final context = StringBuffer();
      context.writeln('Upcoming appointment with Dr. $doctorName');
      if (specialty != null) context.writeln('Specialty: $specialty');
      if (reason != null) context.writeln('Reason: $reason');
      context.writeln(
          'Date: ${DateFormat('MMMM d, yyyy').format(appointmentDate)}');

      if (_preparation != null) {
        if (_preparation!['symptoms'] != null &&
            (_preparation!['symptoms'] as List).isNotEmpty) {
          context.writeln(
              '\nCurrent symptoms: ${(_preparation!['symptoms'] as List).join(', ')}');
        }
        if (_preparation!['current_medications'] != null &&
            (_preparation!['current_medications'] as List).isNotEmpty) {
          context.writeln(
              'Current medications: ${(_preparation!['current_medications'] as List).join(', ')}');
        }
        if (_preparation!['updates_since_last_visit'] != null) {
          context.writeln(
              'Updates: ${_preparation!['updates_since_last_visit']}');
        }
      }

      final prompt = '''
Based on this appointment information:
$context

Please provide 5-7 helpful suggestions for what the patient should:
1. Ask the doctor
2. Discuss or mention
3. Bring (documents/reports)
4. Prepare or note

Format as a simple numbered list, each item on a new line.
''';

      final response = await AIService.chat(prompt);

      // Parse AI response into list
      final suggestions = response
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .where((line) =>
              RegExp(r'^\d+\.').hasMatch(line.trim()) || line.startsWith('-'))
          .map((line) => line.replaceAll(RegExp(r'^\d+\.\s*|-\s*'), '').trim())
          .toList();

      if (suggestions.isNotEmpty) {
        await _appointmentService.updateAISuggestions(
          widget.appointment['id'],
          suggestions,
        );

        await _loadPreparation();

        Get.snackbar(
          'AI Suggestions Generated',
          'Check the AI Assistant tab for personalized recommendations',
          backgroundColor: AppColors.success,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print('Error generating AI suggestions: $e');
      Get.snackbar(
        'Error',
        'Failed to generate AI suggestions',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }

    setState(() => _isGeneratingAI = false);
  }

  @override
  Widget build(BuildContext context) {
    final doctorName = widget.appointment['doctor_name'];
    final appointmentDate =
        DateTime.parse(widget.appointment['appointment_date']);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Preparation'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
        actions: [
          IconButton(
            icon: _isGeneratingAI
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.auto_awesome),
            onPressed: _isGeneratingAI ? null : _generateAISuggestions,
            tooltip: 'Generate AI Suggestions',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.textWhite,
          labelColor: AppColors.textWhite,
          unselectedLabelColor: AppColors.textWhite.withOpacity(0.7),
          tabs: const [
            Tab(text: 'Questions', icon: Icon(Icons.help_outline, size: 20)),
            Tab(text: 'Symptoms', icon: Icon(Icons.healing, size: 20)),
            Tab(text: 'Medications', icon: Icon(Icons.medication, size: 20)),
            Tab(text: 'Documents', icon: Icon(Icons.description, size: 20)),
            Tab(text: 'AI Assistant', icon: Icon(Icons.auto_awesome, size: 20)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Appointment info card
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.healthBlue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.event, color: Colors.white, size: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Preparing for appointment with',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              doctorName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('EEEE, MMMM d • h:mm a')
                                  .format(appointmentDate),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Tab views
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildQuestionsTab(),
                      _buildSymptomsTab(),
                      _buildMedicationsTab(),
                      _buildDocumentsTab(),
                      _buildAIAssistantTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildQuestionsTab() {
    final questions = _preparation != null &&
            _preparation!['questions'] != null
        ? List<String>.from(_preparation!['questions'])
        : <String>[];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Write down questions you want to ask your doctor',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _questionController,
                  decoration: InputDecoration(
                    hintText: 'e.g., What are the side effects?',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onSubmitted: (_) => _addQuestion(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.add_circle, color: AppColors.primary, size: 32),
                onPressed: _addQuestion,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: questions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.help_outline,
                          size: 64, color: AppColors.textSecondary.withOpacity(0.3)),
                      const SizedBox(height: 16),
                      Text(
                        'No questions yet',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: questions.length,
                  itemBuilder: (context, index) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(questions[index]),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: AppColors.error),
                          onPressed: () => _removeQuestion(index),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSymptomsTab() {
    final symptoms = _preparation != null &&
            _preparation!['symptoms'] != null
        ? List<String>.from(_preparation!['symptoms'])
        : <String>[];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'List symptoms or changes since your last visit',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _updatesController,
                decoration: InputDecoration(
                  labelText: 'General Updates',
                  hintText: 'Any changes or updates to mention...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                maxLines: 3,
                onChanged: (value) {
                  _appointmentService.savePreparation(
                    appointmentId: widget.appointment['id'],
                    updatesSinceLastVisit: value.isEmpty ? null : value,
                  );
                },
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _symptomController,
                  decoration: InputDecoration(
                    hintText: 'e.g., Headache, Fatigue',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onSubmitted: (_) => _addSymptom(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.add_circle, color: AppColors.primary, size: 32),
                onPressed: _addSymptom,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: symptoms.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.healing,
                          size: 64, color: AppColors.textSecondary.withOpacity(0.3)),
                      const SizedBox(height: 16),
                      Text(
                        'No symptoms listed',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: symptoms.length,
                  itemBuilder: (context, index) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(Icons.healing, color: AppColors.error),
                        title: Text(symptoms[index]),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: AppColors.error),
                          onPressed: () => _removeSymptom(index),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildMedicationsTab() {
    final medications = _preparation != null &&
            _preparation!['current_medications'] != null
        ? List<String>.from(_preparation!['current_medications'])
        : <String>[];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'List all medications you are currently taking',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _medicationController,
                  decoration: InputDecoration(
                    hintText: 'e.g., Aspirin 100mg daily',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onSubmitted: (_) => _addMedication(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.add_circle, color: AppColors.primary, size: 32),
                onPressed: _addMedication,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: medications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.medication,
                          size: 64, color: AppColors.textSecondary.withOpacity(0.3)),
                      const SizedBox(height: 16),
                      Text(
                        'No medications listed',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: medications.length,
                  itemBuilder: (context, index) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(Icons.medication, color: AppColors.healthBlue),
                        title: Text(medications[index]),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: AppColors.error),
                          onPressed: () => _removeMedication(index),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildDocumentsTab() {
    final documents = _preparation != null &&
            _preparation!['documents_to_bring'] != null
        ? List<String>.from(_preparation!['documents_to_bring'])
        : <String>[];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'List documents or reports to bring to your appointment',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _documentController,
                  decoration: InputDecoration(
                    hintText: 'e.g., Blood test results, X-ray',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onSubmitted: (_) => _addDocument(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.add_circle, color: AppColors.primary, size: 32),
                onPressed: _addDocument,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: documents.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.description,
                          size: 64, color: AppColors.textSecondary.withOpacity(0.3)),
                      const SizedBox(height: 16),
                      Text(
                        'No documents listed',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: documents.length,
                  itemBuilder: (context, index) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(Icons.description, color: AppColors.warning),
                        title: Text(documents[index]),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: AppColors.error),
                          onPressed: () => _removeDocument(index),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildAIAssistantTab() {
    final suggestions = _preparation != null &&
            _preparation!['ai_suggestions'] != null
        ? List<String>.from(_preparation!['ai_suggestions'])
        : <String>[];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: AppColors.healthBlue.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(Icons.auto_awesome, color: AppColors.healthBlue, size: 48),
                const SizedBox(height: 12),
                Text(
                  'AI Preparation Assistant',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.healthBlue,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  suggestions.isEmpty
                      ? 'Get personalized suggestions based on your appointment and medical history'
                      : 'AI-generated suggestions to help you prepare',
                  style: TextStyle(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _isGeneratingAI ? null : _generateAISuggestions,
                  icon: _isGeneratingAI
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.auto_awesome),
                  label: Text(_isGeneratingAI
                      ? 'Generating...'
                      : suggestions.isEmpty
                          ? 'Generate Suggestions'
                          : 'Regenerate Suggestions'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.healthBlue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            'AI Suggestions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...suggestions.asMap().entries.map((entry) {
            final index = entry.key;
            final suggestion = entry.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.healthBlue.withOpacity(0.1),
                  child: Icon(Icons.lightbulb, color: AppColors.healthBlue),
                ),
                title: Text(suggestion),
              ),
            );
          }).toList(),
        ],
      ],
    );
  }

  // Action methods
  Future<void> _addQuestion() async {
    if (_questionController.text.trim().isEmpty) return;

    await _appointmentService.addQuestion(
      widget.appointment['id'],
      _questionController.text.trim(),
    );

    _questionController.clear();
    await _loadPreparation();
  }

  Future<void> _removeQuestion(int index) async {
    await _appointmentService.removeQuestion(widget.appointment['id'], index);
    await _loadPreparation();
  }

  Future<void> _addSymptom() async {
    if (_symptomController.text.trim().isEmpty) return;

    await _appointmentService.addSymptom(
      widget.appointment['id'],
      _symptomController.text.trim(),
    );

    _symptomController.clear();
    await _loadPreparation();
  }

  Future<void> _removeSymptom(int index) async {
    await _appointmentService.removeSymptom(widget.appointment['id'], index);
    await _loadPreparation();
  }

  Future<void> _addMedication() async {
    if (_medicationController.text.trim().isEmpty) return;

    await _appointmentService.addCurrentMedication(
      widget.appointment['id'],
      _medicationController.text.trim(),
    );

    _medicationController.clear();
    await _loadPreparation();
  }

  Future<void> _removeMedication(int index) async {
    await _appointmentService.removeCurrentMedication(
      widget.appointment['id'],
      index,
    );
    await _loadPreparation();
  }

  Future<void> _addDocument() async {
    if (_documentController.text.trim().isEmpty) return;

    await _appointmentService.addDocumentToBring(
      widget.appointment['id'],
      _documentController.text.trim(),
    );

    _documentController.clear();
    await _loadPreparation();
  }

  Future<void> _removeDocument(int index) async {
    await _appointmentService.removeDocumentToBring(
      widget.appointment['id'],
      index,
    );
    await _loadPreparation();
  }
}
