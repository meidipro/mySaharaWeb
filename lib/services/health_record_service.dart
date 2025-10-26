import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/medical_document.dart';

/// Service for managing health records (CRUD operations)
class HealthRecordService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get current user ID
  String? get _currentUserId => _supabase.auth.currentUser?.id;

  /// Fetch all health records for current user
  Future<List<MedicalDocument>> getHealthRecords() async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase
          .from('medical_documents')
          .select()
          .eq('user_id', _currentUserId!)
          .order('document_date', ascending: false);

      return (response as List)
          .map((json) => MedicalDocument.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch health records: $e');
    }
  }

  /// Get a single health record by ID
  Future<MedicalDocument?> getHealthRecordById(String id) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase
          .from('medical_documents')
          .select()
          .eq('id', id)
          .eq('user_id', _currentUserId!)
          .single();

      return MedicalDocument.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Add new health record with file upload
  Future<MedicalDocument> addHealthRecord(
    MedicalDocument document,
    dynamic fileData, // Can be File (mobile) or Uint8List (web)
    String fileName,
  ) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      print('DEBUG: Starting file upload for user: $_currentUserId');
      print('DEBUG: Document type: ${document.documentType}');
      print('DEBUG: File name: $fileName');

      // Get file path in storage
      final storagePath = '$_currentUserId/${_currentUserId}_${DateTime.now().millisecondsSinceEpoch}_$fileName';

      print('DEBUG: Storage path: $storagePath');

      // Upload file to Supabase Storage
      try {
        if (fileData is Uint8List) {
          // For web, upload bytes directly
          print('DEBUG: Uploading ${fileData.length} bytes to storage (web)');
          await _supabase.storage.from('medical-documents').uploadBinary(
                storagePath,
                fileData,
                fileOptions: FileOptions(
                  cacheControl: '3600',
                  upsert: false,
                  contentType: _getContentType(fileName),
                ),
              );
        } else if (fileData is File) {
          // For mobile, upload file directly
          print('DEBUG: Uploading file to storage (mobile)');
          await _supabase.storage.from('medical-documents').upload(
                storagePath,
                fileData,
                fileOptions: FileOptions(
                  cacheControl: '3600',
                  upsert: false,
                  contentType: _getContentType(fileName),
                ),
              );
        } else {
          throw Exception('Invalid file data type');
        }
        print('DEBUG: File uploaded successfully');
      } catch (storageError) {
        print('ERROR: Storage upload failed: $storageError');
        throw Exception('Failed to upload file to storage: $storageError');
      }

      // Get the public URL for the uploaded file
      final publicUrl = _supabase.storage.from('medical-documents').getPublicUrl(storagePath);
      print('DEBUG: File stored at: $storagePath');
      print('DEBUG: Public URL: $publicUrl');

      // Create document record with public URL
      final documentData = document.toJson();
      documentData['user_id'] = _currentUserId;
      documentData['file_url'] = publicUrl; // Store full public URL

      print('DEBUG: Inserting document record: $documentData');

      try {
        final response = await _supabase
            .from('medical_documents')
            .insert(documentData)
            .select()
            .single();

        print('DEBUG: Document record created successfully: ${response['id']}');
        return MedicalDocument.fromJson(response);
      } catch (dbError) {
        print('ERROR: Database insert failed: $dbError');
        throw Exception('Failed to save document record: $dbError');
      }
    } catch (e) {
      print('ERROR: addHealthRecord failed: $e');
      throw Exception('Failed to add health record: $e');
    }
  }

  /// Get content type based on file extension
  String _getContentType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return 'application/octet-stream';
    }
  }

  /// Update existing health record
  Future<MedicalDocument> updateHealthRecord(
    String id,
    MedicalDocument document,
  ) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final documentData = document.toJson();
      documentData['updated_at'] = DateTime.now().toIso8601String();

      final response = await _supabase
          .from('medical_documents')
          .update(documentData)
          .eq('id', id)
          .eq('user_id', _currentUserId!)
          .select()
          .single();

      return MedicalDocument.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update health record: $e');
    }
  }

  /// Update health record with new file
  Future<MedicalDocument> updateHealthRecordWithFile(
    String id,
    MedicalDocument document,
    File file,
  ) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Upload new file
      final fileName =
          '${_currentUserId}_${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final filePath = '$_currentUserId/$fileName';

      // Upload file to Supabase Storage
      if (kIsWeb) {
        // For web, read file as bytes
        final bytes = await file.readAsBytes();
        await _supabase.storage.from('medical-documents').uploadBinary(
              filePath,
              bytes,
              fileOptions: FileOptions(
                cacheControl: '3600',
                upsert: false,
                contentType: _getContentType(fileName),
              ),
            );
      } else {
        // For mobile, upload file directly
        await _supabase.storage.from('medical-documents').upload(
              filePath,
              file,
              fileOptions: FileOptions(
                cacheControl: '3600',
                upsert: false,
                contentType: _getContentType(fileName),
              ),
            );
      }

      // Get public URL of uploaded file
      final fileUrl = _supabase.storage
          .from('medical-documents')
          .getPublicUrl(filePath);

      // Update document record with new file URL
      final documentData = document.toJson();
      documentData['file_url'] = fileUrl;
      documentData['updated_at'] = DateTime.now().toIso8601String();

      final response = await _supabase
          .from('medical_documents')
          .update(documentData)
          .eq('id', id)
          .eq('user_id', _currentUserId!)
          .select()
          .single();

      // Delete old file if exists
      if (document.fileUrl.isNotEmpty) {
        try {
          final oldFilePath = document.fileUrl
              .split('/medical-documents/')
              .last;
          await _supabase.storage
              .from('medical-documents')
              .remove([oldFilePath]);
        } catch (e) {
          // Ignore error if old file doesn't exist
        }
      }

      return MedicalDocument.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update health record: $e');
    }
  }

  /// Delete health record
  Future<void> deleteHealthRecord(String id) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      print('DEBUG: Deleting document with ID: $id');

      // Get document to retrieve file URL
      final document = await getHealthRecordById(id);

      if (document != null) {
        print('DEBUG: Document found, file_url: ${document.fileUrl}');

        // Delete file from storage
        if (document.fileUrl.isNotEmpty) {
          try {
            // For new documents, fileUrl is already just the storage path
            // For old documents, fileUrl might be a full URL
            String filePath;
            if (document.fileUrl.contains('/medical-documents/')) {
              // Old format: extract path from URL
              filePath = document.fileUrl.split('/medical-documents/').last;
            } else {
              // New format: already a storage path
              filePath = document.fileUrl;
            }

            print('DEBUG: Deleting file from storage: $filePath');
            await _supabase.storage
                .from('medical-documents')
                .remove([filePath]);
            print('DEBUG: File deleted from storage successfully');
          } catch (e) {
            print('ERROR: Failed to delete file from storage: $e');
            // Continue even if file deletion fails
          }
        }

        // Delete document record
        print('DEBUG: Deleting document record from database');
        await _supabase
            .from('medical_documents')
            .delete()
            .eq('id', id)
            .eq('user_id', _currentUserId!);
        print('DEBUG: Document deleted successfully from database');
      } else {
        print('ERROR: Document not found with ID: $id');
      }
    } catch (e) {
      print('ERROR: deleteHealthRecord failed: $e');
      throw Exception('Failed to delete health record: $e');
    }
  }

  /// Search health records by keyword
  Future<List<MedicalDocument>> searchHealthRecords(String keyword) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase
          .from('medical_documents')
          .select()
          .eq('user_id', _currentUserId!)
          .or('title.ilike.%$keyword%,description.ilike.%$keyword%,doctor_name.ilike.%$keyword%,hospital.ilike.%$keyword%')
          .order('document_date', ascending: false);

      return (response as List)
          .map((json) => MedicalDocument.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to search health records: $e');
    }
  }

  /// Get health records by document type
  Future<List<MedicalDocument>> getHealthRecordsByType(String type) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase
          .from('medical_documents')
          .select()
          .eq('user_id', _currentUserId!)
          .eq('document_type', type)
          .order('document_date', ascending: false);

      return (response as List)
          .map((json) => MedicalDocument.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch health records by type: $e');
    }
  }

  /// Get health records by date range
  Future<List<MedicalDocument>> getHealthRecordsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase
          .from('medical_documents')
          .select()
          .eq('user_id', _currentUserId!)
          .gte('document_date', startDate.toIso8601String())
          .lte('document_date', endDate.toIso8601String())
          .order('document_date', ascending: false);

      return (response as List)
          .map((json) => MedicalDocument.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch health records by date range: $e');
    }
  }

  /// Get health records statistics
  Future<Map<String, int>> getHealthRecordsStats() async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final documents = await getHealthRecords();

      // Count by document type
      final stats = <String, int>{};
      for (final doc in documents) {
        stats[doc.documentType] = (stats[doc.documentType] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      throw Exception('Failed to fetch health records stats: $e');
    }
  }

  /// Get recent health records (last 10)
  Future<List<MedicalDocument>> getRecentHealthRecords({int limit = 10}) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase
          .from('medical_documents')
          .select()
          .eq('user_id', _currentUserId!)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => MedicalDocument.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch recent health records: $e');
    }
  }

  /// Get signed URL for viewing a private document
  /// Returns a temporary URL that expires in 1 hour
  /// Handles both full URLs and storage paths
  Future<String> getSignedUrl(String fileUrl) async {
    try {
      // If the bucket is public, just return the URL directly
      if (fileUrl.contains('/object/public/medical-documents/')) {
        print('DEBUG: Using public URL directly: $fileUrl');
        return fileUrl;
      }

      // Extract storage path from URL if needed
      String filePath;
      if (fileUrl.contains('/medical-documents/')) {
        // Extract path from full URL
        filePath = fileUrl.split('/medical-documents/').last;
        print('DEBUG: Extracted path from URL: $filePath');
      } else {
        // Already a storage path
        filePath = fileUrl;
        print('DEBUG: Using storage path directly: $filePath');
      }

      // Create signed URL for private bucket
      final signedUrl = await _supabase.storage
          .from('medical-documents')
          .createSignedUrl(filePath, 3600); // 1 hour expiry

      print('DEBUG: Created signed URL successfully');
      return signedUrl;
    } catch (e) {
      print('ERROR: Failed to create signed URL: $e');

      // Fallback: Try to use the URL directly if it's already a full URL
      if (fileUrl.startsWith('http')) {
        print('DEBUG: Falling back to direct URL: $fileUrl');
        return fileUrl;
      }

      throw Exception('Failed to get document URL: $e');
    }
  }
}
