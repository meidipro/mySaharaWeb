import 'package:flutter/material.dart';
import '../models/medical_history.dart';
import '../services/medical_timeline_service.dart';

/// Provider for managing medical timeline state
class MedicalTimelineProvider extends ChangeNotifier {
  final MedicalTimelineService _timelineService = MedicalTimelineService();

  List<MedicalHistory> _timelineEvents = [];
  MedicalHistory? _selectedEvent;
  bool _isLoading = false;
  String? _errorMessage;

  /// All timeline events
  List<MedicalHistory> get timelineEvents => _timelineEvents;

  /// All medical history (alias for timelineEvents for compatibility)
  List<MedicalHistory> get medicalHistory => _timelineEvents;

  /// Selected timeline event
  MedicalHistory? get selectedEvent => _selectedEvent;

  /// Loading state
  bool get isLoading => _isLoading;

  /// Error message
  String? get errorMessage => _errorMessage;

  /// Clear all data (for logout)
  void clear() {
    _timelineEvents = [];
    _selectedEvent = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  /// Load all timeline events
  Future<void> loadTimelineEvents() async {
    _setLoading(true);
    _clearError();

    try {
      _timelineEvents = await _timelineService.getTimelineEvents();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load timeline events: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Load timeline event by ID
  Future<void> loadTimelineEventById(String id) async {
    _setLoading(true);
    _clearError();

    try {
      _selectedEvent = await _timelineService.getTimelineEventById(id);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load timeline event: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Add new timeline event
  Future<bool> addTimelineEvent(MedicalHistory event) async {
    _setLoading(true);
    _clearError();

    try {
      final newEvent = await _timelineService.addTimelineEvent(event);
      _timelineEvents.insert(0, newEvent);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to add timeline event: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update existing timeline event
  Future<bool> updateTimelineEvent(
    String id,
    MedicalHistory event,
  ) async {
    _setLoading(true);
    _clearError();

    try {
      final updatedEvent = await _timelineService.updateTimelineEvent(
        id,
        event,
      );

      final index = _timelineEvents.indexWhere((e) => e.id == id);
      if (index != -1) {
        _timelineEvents[index] = updatedEvent;
      }

      if (_selectedEvent?.id == id) {
        _selectedEvent = updatedEvent;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update timeline event: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Delete timeline event
  Future<bool> deleteTimelineEvent(String id) async {
    _setLoading(true);
    _clearError();

    try {
      await _timelineService.deleteTimelineEvent(id);

      _timelineEvents.removeWhere((e) => e.id == id);

      if (_selectedEvent?.id == id) {
        _selectedEvent = null;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete timeline event: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Search timeline events
  Future<void> searchTimelineEvents(String keyword) async {
    if (keyword.isEmpty) {
      await loadTimelineEvents();
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      _timelineEvents = await _timelineService.searchTimelineEvents(keyword);
      notifyListeners();
    } catch (e) {
      _setError('Failed to search timeline events: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Filter timeline events by type
  Future<void> filterByType(String type) async {
    _setLoading(true);
    _clearError();

    try {
      _timelineEvents = await _timelineService.getEventsByType(type);
      notifyListeners();
    } catch (e) {
      _setError('Failed to filter timeline events: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Filter timeline events by date range
  Future<void> filterByDateRange(DateTime startDate, DateTime endDate) async {
    _setLoading(true);
    _clearError();

    try {
      _timelineEvents = await _timelineService.getEventsByDateRange(
        startDate,
        endDate,
      );
      notifyListeners();
    } catch (e) {
      _setError('Failed to filter timeline events: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Get timeline statistics
  Future<Map<String, int>> getStatistics() async {
    try {
      return await _timelineService.getTimelineStats();
    } catch (e) {
      _setError('Failed to get statistics: $e');
      return {};
    }
  }

  /// Get recent timeline events
  Future<void> loadRecentEvents({int limit = 10}) async {
    _setLoading(true);
    _clearError();

    try {
      _timelineEvents = await _timelineService.getRecentEvents(
        limit: limit,
      );
      notifyListeners();
    } catch (e) {
      _setError('Failed to load recent events: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Load medical history for a specific user or family member
  /// If familyMemberId is null, loads for the user
  /// If familyMemberId is provided, loads for that family member
  Future<void> loadMedicalHistory({
    required String userId,
    String? familyMemberId,
  }) async {
    // For now, just load all timeline events
    // The filtering will happen in the UI using familyMemberId
    await loadTimelineEvents();
  }

  /// Get events by type (local filtering)
  List<MedicalHistory> getEventsByTypeLocal(String type) {
    return _timelineEvents
        .where((event) => event.eventType.toLowerCase() == type.toLowerCase())
        .toList();
  }

  /// Get events count by type
  Map<String, int> getCountByType() {
    final counts = <String, int>{};
    for (final event in _timelineEvents) {
      counts[event.eventType] = (counts[event.eventType] ?? 0) + 1;
    }
    return counts;
  }

  /// Get total events count
  int get totalCount => _timelineEvents.length;

  /// Get recent events count (last 30 days)
  int get recentCount {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    return _timelineEvents
        .where((event) => event.eventDate.isAfter(thirtyDaysAgo))
        .length;
  }

  /// Sort events by date (ascending)
  void sortByDateAscending() {
    _timelineEvents.sort((a, b) => a.eventDate.compareTo(b.eventDate));
    notifyListeners();
  }

  /// Sort events by date (descending)
  void sortByDateDescending() {
    _timelineEvents.sort((a, b) => b.eventDate.compareTo(a.eventDate));
    notifyListeners();
  }

  /// Sort events by type
  void sortByType() {
    _timelineEvents.sort((a, b) => a.eventType.compareTo(b.eventType));
    notifyListeners();
  }

  /// Set selected event
  void setSelectedEvent(MedicalHistory? event) {
    _selectedEvent = event;
    notifyListeners();
  }

  /// Clear selected event
  void clearSelectedEvent() {
    _selectedEvent = null;
    notifyListeners();
  }

  /// Refresh timeline events (reload from server)
  Future<void> refresh() async {
    await loadTimelineEvents();
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

  /// Check if there are any events
  bool get hasEvents => _timelineEvents.isNotEmpty;

  /// Get events for a specific year
  List<MedicalHistory> getEventsByYear(int year) {
    return _timelineEvents
        .where((event) => event.eventDate.year == year)
        .toList();
  }

  /// Get events for a specific month
  List<MedicalHistory> getEventsByMonth(int year, int month) {
    return _timelineEvents
        .where((event) =>
            event.eventDate.year == year && event.eventDate.month == month)
        .toList();
  }

  /// Get unique years from events
  List<int> getAvailableYears() {
    final years = _timelineEvents.map((event) => event.eventDate.year).toSet();
    return years.toList()..sort((a, b) => b.compareTo(a));
  }

  /// Get events by doctor
  List<MedicalHistory> getEventsByDoctor(String doctorName) {
    return _timelineEvents
        .where((event) =>
            event.doctorName?.toLowerCase() == doctorName.toLowerCase())
        .toList();
  }

  /// Get events by hospital
  List<MedicalHistory> getEventsByHospital(String hospital) {
    return _timelineEvents
        .where(
            (event) => event.hospital?.toLowerCase() == hospital.toLowerCase())
        .toList();
  }

  /// Get unique doctors from events
  List<String> getUniqueDoctors() {
    final doctors = _timelineEvents
        .where((event) => event.doctorName != null && event.doctorName!.isNotEmpty)
        .map((event) => event.doctorName!)
        .toSet();
    return doctors.toList()..sort();
  }

  /// Get unique hospitals from events
  List<String> getUniqueHospitals() {
    final hospitals = _timelineEvents
        .where((event) => event.hospital != null && event.hospital!.isNotEmpty)
        .map((event) => event.hospital!)
        .toSet();
    return hospitals.toList()..sort();
  }

  @override
  void dispose() {
    _timelineEvents.clear();
    _selectedEvent = null;
    super.dispose();
  }
}
