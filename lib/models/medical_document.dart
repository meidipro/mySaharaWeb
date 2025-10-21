enum DocumentType {
  prescription,
  testReport,
  mriReport,
  xrayReport,
  ctScan,
  bloodReport,
  ultrasound,
  other,
}

class MedicalDocument {
  final String? id;
  final String userId;
  final String documentType;
  final String title;
  final String? description;
  final String? disease;
  final String? doctorName;
  final String? hospital;
  final DateTime documentDate;
  final String fileUrl;
  final String? thumbnailUrl;
  final Map<String, dynamic>? ocrData;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime? updatedAt;

  MedicalDocument({
    this.id,
    required this.userId,
    required this.documentType,
    required this.title,
    this.description,
    this.disease,
    this.doctorName,
    this.hospital,
    required this.documentDate,
    required this.fileUrl,
    this.thumbnailUrl,
    this.ocrData,
    this.metadata,
    required this.createdAt,
    this.updatedAt,
  });

  factory MedicalDocument.fromJson(Map<String, dynamic> json) {
    return MedicalDocument(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      documentType: json['document_type'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      disease: json['disease'] as String?,
      doctorName: json['doctor_name'] as String?,
      hospital: json['hospital'] as String?,
      documentDate: DateTime.parse(json['document_date'] as String),
      fileUrl: json['file_url'] as String,
      thumbnailUrl: json['thumbnail_url'] as String?,
      ocrData: json['ocr_data'] as Map<String, dynamic>?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'document_type': documentType,
      'title': title,
      'description': description,
      'disease': disease,
      'doctor_name': doctorName,
      'hospital': hospital,
      'document_date': documentDate.toIso8601String(),
      'file_url': fileUrl,
      'thumbnail_url': thumbnailUrl,
      'ocr_data': ocrData,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }
}
