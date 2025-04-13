import 'dart:convert';
import 'package:http/http.dart' as http;

class MLApiService {
  // Base URL for the Flask API - update to match your deployment
  static const String baseUrl = "http://192.168.77.84:7122";

  // Singleton instance
  static final MLApiService _instance = MLApiService._internal();

  // Factory constructor
  factory MLApiService() {
    return _instance;
  }

  // Internal constructor
  MLApiService._internal();

  /// Check if the API server is healthy
  Future<Map<String, dynamic>> checkHealth() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/health'));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to check health: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Health check failed: $e');
    }
  }

  Future<Map<String, dynamic>> processComplaint({
    required String complaint,
    required String location,
  }) async {
    try {
      final payload = {
        'complaint': complaint,
        'location': location,
        
      };

      final response = await http.post(
        Uri.parse('$baseUrl/process_complaint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to process complaint: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Complaint processing failed: $e');
    }
  }

  Future<Map<String, dynamic>> analyzePost({
    required String postText,
    List<String> imagePaths = const [],
  }) async {
    try {
      final payload = {
        'post_text': postText,
        'image_paths': imagePaths,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/analyze_post'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to analyze post: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Post analysis failed: $e');
    }
  }

  /// Upload an image file for processing
  Future<Map<String, dynamic>> uploadImage(String filePath) async {
    try {
      // Implement file upload functionality
      // This is a placeholder - you'll need to implement multipart file upload
      throw UnimplementedError('Image upload not yet implemented');
    } catch (e) {
      throw Exception('Image upload failed: $e');
    }
  }
}
