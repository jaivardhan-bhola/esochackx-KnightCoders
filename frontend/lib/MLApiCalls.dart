import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

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
    File? imageFile,
  }) async {
    try {
      // Prepare the payload
      final payload = {
        'complaint': complaint,
        'location': location,
      };

      // If an image is provided, add its path to the payload
      if (imageFile != null) {
        String imagePath = await uploadImage(imageFile);
        payload['image_path'] = imagePath;
      }

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
  Future<String> uploadImage(File imageFile) async {
    try {
      // Create a temporary file path on the server
      String fileName = path.basename(imageFile.path);
      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      String serverFileName = "${timestamp}_$fileName";

      // Convert the image to base64 for sending to the API
      List<int> imageBytes = await imageFile.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      // For now, we'll just return the local path since our Python API
      // expects a file path that's accessible on the server
      return imageFile.path;
    } catch (e) {
      throw Exception('Image upload failed: $e');
    }
  }
}
