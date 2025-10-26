import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../models/medical_document.dart';
import '../services/health_record_service.dart';

/// Provider for managing health records state
class HealthRecordProvider extends ChangeNotifier {
  final HealthRecordService _healthRecordService = HealthRecordService();

  List<MedicalDocument> _healthRecords = [];
  MedicalDocument? _selectedHealthRecord;
  bool _isLoading = false;
  String? _errorMessage;

  /// All health records
  List<MedicalDocument> get healthRecords => _healthRecords;

  /// All documents (alias for healthRecords for compatibility)
  List<MedicalDocument> get documents => _healthRecords;

  /// Selected health record
  MedicalDocument? get selectedHealthRecord => _selectedHealthRecord;

  /// Loading state
  bool get isLoading => _isLoading;

  /// Error message
  String? get errorMessage => _errorMessage;

  /// Clear all data (for logout)
  void clear() {
    _healthRecords = [];
    _selectedHealthRecord = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  /// Load all health records
  Future<void> loadHealthRecords() async {
    _setLoading(true);
    _clearError();

    try {
      _healthRecords = await _healthRecordService.getHealthRecords();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load health records: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Load health record by ID
  Future<void> loadHealthRecordById(String id) async {
    _setLoading(true);
    _clearError();

    try {
      _selectedHealthRecord = await _healthRecordService.getHealthRecordById(id);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load health record: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Load documents for a specific user or family member
  /// If familyMemberId is null, loads for the user
  /// If familyMemberId is provided, loads for that family member
  Future<void> loadDocuments({
    required String userId,
    String? familyMemberId,
  }) async {
    // For now, just load all health records
    // The filtering will happen in the UI using familyMemberId
    await loadHealthRecords();
  }

  /// Add new health record
  Future<bool> addHealthRecord(MedicalDocument document, dynamic fileData, String fileName) async {
    _setLoading(true);
    _clearError();

    try {
      final newDocument = await _healthRecordService.addHealthRecord(
        document,
        fileData,
        fileName,
      );

      _healthRecords.insert(0, newDocument);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to add health record: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update existing health record
  Future<bool> updateHealthRecord(
    String id,
    MedicalDocument document,
  ) async {
    _setLoading(true);
    _clearError();

    try {
      final updatedDocument = await _healthRecordService.updateHealthRecord(
        id,
        document,
      );

      final index = _healthRecords.indexWhere((doc) => doc.id == id);
      if (index != -1) {
        _healthRecords[index] = updatedDocument;
      }

      if (_selectedHealthRecord?.id == id) {
        _selectedHealthRecord = updatedDocument;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update health record: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update health record with new file
  Future<bool> updateHealthRecordWithFile(
    String id,
    MedicalDocument document,
    File file,
  ) async {
    _setLoading(true);
    _clearError();

    try {
      final updatedDocument =
          await _healthRecordService.updateHealthRecordWithFile(
        id,
        document,
        file,
      );

      final index = _healthRecords.indexWhere((doc) => doc.id == id);
      if (index != -1) {
        _healthRecords[index] = updatedDocument;
      }

      if (_selectedHealthRecord?.id == id) {
        _selectedHealthRecord = updatedDocument;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update health record: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Delete health record
  Future<bool> deleteHealthRecord(String id) async {
    _setLoading(true);
    _clearError();

    try {
      await _healthRecordService.deleteHealthRecord(id);

      _healthRecords.removeWhere((doc) => doc.id == id);

      if (_selectedHealthRecord?.id == id) {
        _selectedHealthRecord = null;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete health record: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Search health records
  Future<void> searchHealthRecords(String keyword) async {
    if (keyword.isEmpty) {
      await loadHealthRecords();
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      _healthRecords = await _healthRecordService.searchHealthRecords(keyword);
      notifyListeners();
    } catch (e) {
      _setError('Failed to search health records: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Filter health records by type
  Future<void> filterByType(String type) async {
    _setLoading(true);
    _clearError();

    try {
      _healthRecords = await _healthRecordService.getHealthRecordsByType(type);
      notifyListeners();
    } catch (e) {
      _setError('Failed to filter health records: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Filter health records by date range
  Future<void> filterByDateRange(DateTime startDate, DateTime endDate) async {
    _setLoading(true);
    _clearError();

    try {
      _healthRecords = await _healthRecordService.getHealthRecordsByDateRange(
        startDate,
        endDate,
      );
      notifyListeners();
    } catch (e) {
      _setError('Failed to filter health records: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Get health records statistics
  Future<Map<String, int>> getStatistics() async {
    try {
      return await _healthRecordService.getHealthRecordsStats();
    } catch (e) {
      _setError('Failed to get statistics: $e');
      return {};
    }
  }

  /// Get recent health records
  Future<void> loadRecentHealthRecords({int limit = 10}) async {
    _setLoading(true);
    _clearError();

    try {
      _healthRecords = await _healthRecordService.getRecentHealthRecords(
        limit: limit,
      );
      notifyListeners();
    } catch (e) {
      _setError('Failed to load recent health records: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Get health records by document type (local filtering)
  List<MedicalDocument> getRecordsByType(String type) {
    return _healthRecords
        .where((doc) => doc.documentType.toLowerCase() == type.toLowerCase())
        .toList();
  }

  /// Get health records count by type
  Map<String, int> getCountByType() {
    final counts = <String, int>{};
    for (final doc in _healthRecords) {
      counts[doc.documentType] = (counts[doc.documentType] ?? 0) + 1;
    }
    return counts;
  }

  /// Get total health records count
  int get totalCount => _healthRecords.length;

  /// Get recent documents count (last 30 days)
  int get recentCount {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    return _healthRecords
        .where((doc) => doc.createdAt.isAfter(thirtyDaysAgo))
        .length;
  }

  /// Sort health records by date (ascending)
  void sortByDateAscending() {
    _healthRecords.sort((a, b) => a.documentDate.compareTo(b.documentDate));
    notifyListeners();
  }

  /// Sort health records by date (descending)
  void sortByDateDescending() {
    _healthRecords.sort((a, b) => b.documentDate.compareTo(a.documentDate));
    notifyListeners();
  }

  /// Sort health records by title
  void sortByTitle() {
    _healthRecords.sort((a, b) => a.title.compareTo(b.title));
    notifyListeners();
  }

  /// Sort health records by type
  void sortByType() {
    _healthRecords.sort((a, b) => a.documentType.compareTo(b.documentType));
    notifyListeners();
  }

  /// Set selected health record
  void setSelectedHealthRecord(MedicalDocument? document) {
    _selectedHealthRecord = document;
    notifyListeners();
  }

  /// Clear selected health record
  void clearSelectedHealthRecord() {
    _selectedHealthRecord = null;
    notifyListeners();
  }

  /// Refresh health records (reload from server)
  Future<void> refresh() async {
    await loadHealthRecords();
  }

  /// Set loading state
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Set error message
  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  /// Clear error message
  void _clearError() {
    _errorMessage = null;
  }

  /// Check if there are any health records
  bool get hasRecords => _healthRecords.isNotEmpty;

  /// Get health records for a specific year
  List<MedicalDocument> getRecordsByYear(int year) {
    return _healthRecords
        .where((doc) => doc.documentDate.year == year)
        .toList();
  }

  /// Get health records for a specific month
  List<MedicalDocument> getRecordsByMonth(int year, int month) {
    return _healthRecords
        .where((doc) =>
            doc.documentDate.year == year && doc.documentDate.month == month)
        .toList();
  }

  /// Get unique years from health records
  List<int> getAvailableYears() {
    final years = _healthRecords.map((doc) => doc.documentDate.year).toSet();
    return years.toList()..sort((a, b) => b.compareTo(a));
  }

  /// Get health records by doctor
  List<MedicalDocument> getRecordsByDoctor(String doctorName) {
    return _healthRecords
        .where((doc) =>
            doc.doctorName?.toLowerCase() == doctorName.toLowerCase())
        .toList();
  }

  /// Get health records by hospital
  List<MedicalDocument> getRecordsByHospital(String hospital) {
    return _healthRecords
        .where((doc) => doc.hospital?.toLowerCase() == hospital.toLowerCase())
        .toList();
  }

  /// Get unique doctors from health records
  List<String> getUniqueDoctors() {
    final doctors = _healthRecords
        .where((doc) => doc.doctorName != null && doc.doctorName!.isNotEmpty)
        .map((doc) => doc.doctorName!)
        .toSet();
    return doctors.toList()..sort();
  }

  /// Get unique hospitals from health records
  List<String> getUniqueHospitals() {
    final hospitals = _healthRecords
        .where((doc) => doc.hospital != null && doc.hospital!.isNotEmpty)
        .map((doc) => doc.hospital!)
        .toSet();
    return hospitals.toList()..sort();
  }

  @override
  void dispose() {
    _healthRecords.clear();
    _selectedHealthRecord = null;
    super.dispose();
  }
}
