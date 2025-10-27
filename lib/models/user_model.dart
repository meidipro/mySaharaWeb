class UserModel {
  final String id;
  final String email;
  final String? fullName;
  final String? phoneNumber;
  final String? dateOfBirth;
  final String? gender;
  final String? bloodGroup;
  final String? profileImageUrl;
  final double? height; // in cm
  final double? weight; // in kg
  final String? chronicDiseases; // comma-separated chronic diseases
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.id,
    required this.email,
    this.fullName,
    this.phoneNumber,
    this.dateOfBirth,
    this.gender,
    this.bloodGroup,
    this.profileImageUrl,
    this.height,
    this.weight,
    this.chronicDiseases,
    required this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
      phoneNumber: json['phone_number'] as String?,
      dateOfBirth: json['date_of_birth'] as String?,
      gender: json['gender'] as String?,
      bloodGroup: json['blood_group'] as String?,
      profileImageUrl: json['profile_image_url'] as String?,
      height: json['height'] != null ? (json['height'] as num).toDouble() : null,
      weight: json['weight'] != null ? (json['weight'] as num).toDouble() : null,
      chronicDiseases: json['chronic_diseases'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'date_of_birth': dateOfBirth,
      'gender': gender,
      'blood_group': bloodGroup,
      'profile_image_url': profileImageUrl,
      'height': height,
      'weight': weight,
      'chronic_diseases': chronicDiseases,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Helper method to calculate age from date of birth
  int? get age {
    if (dateOfBirth == null) return null;
    try {
      final birthDate = DateTime.parse(dateOfBirth!);
      final today = DateTime.now();
      int age = today.year - birthDate.year;
      if (today.month < birthDate.month ||
          (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }
      return age;
    } catch (e) {
      return null;
    }
  }

  // Helper method to calculate BMI
  double? get bmi {
    if (height == null || weight == null || height! <= 0) return null;
    final heightInMeters = height! / 100;
    return weight! / (heightInMeters * heightInMeters);
  }

  // Helper method to calculate BMR (Mifflin-St Jeor Equation)
  double? get bmr {
    if (height == null || weight == null || age == null || gender == null) {
      return null;
    }
    if (gender == 'male') {
      return (10 * weight!) + (6.25 * height!) - (5 * age!) + 5;
    } else {
      return (10 * weight!) + (6.25 * height!) - (5 * age!) - 161;
    }
  }

  // Helper method to get BMI category
  String? get bmiCategory {
    if (bmi == null) return null;
    if (bmi! < 18.5) return 'Underweight';
    if (bmi! < 25) return 'Normal';
    if (bmi! < 30) return 'Overweight';
    return 'Obese';
  }
}
