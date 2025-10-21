class ProgressSummary {
  final double? startWeight;
  final double? currentWeight;
  final double? targetWeight;
  final double? progressPercentage;
  final String motivationalMessage;
  final List<WeightDataPoint> weightHistory;

  ProgressSummary({
    this.startWeight,
    this.currentWeight,
    this.targetWeight,
    this.progressPercentage,
    required this.motivationalMessage,
    required this.weightHistory,
  });

  factory ProgressSummary.fromJson(Map<String, dynamic> json) {
    return ProgressSummary(
      startWeight: json['start_weight']?.toDouble(),
      currentWeight: json['current_weight']?.toDouble(),
      targetWeight: json['target_weight']?.toDouble(),
      progressPercentage: json['progress_percentage']?.toDouble(),
      motivationalMessage: json['motivational_message'],
      weightHistory: (json['weight_history'] as List)
          .map((i) => WeightDataPoint.fromJson(i))
          .toList(),
    );
  }
}

class WeightDataPoint {
  final DateTime date;
  final double value;

  WeightDataPoint({required this.date, required this.value});

  factory WeightDataPoint.fromJson(Map<String, dynamic> json) {
    return WeightDataPoint(
      date: DateTime.parse(json['date']),
      value: json['value'].toDouble(),
    );
  }
}
