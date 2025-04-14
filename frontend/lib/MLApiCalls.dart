import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

class MLApiService {
  // Base URL for the Flask API - update to match your deployment
  static const String baseUrl = "http://192.168.109.121:7122";

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
      // For sending multipart request when an image is included
      if (imageFile != null) {
        print('Preparing to send image file: ${imageFile.path}');
        print('Image exists: ${imageFile.existsSync()}');
        print('Image size: ${imageFile.lengthSync()} bytes');

        var request = http.MultipartRequest(
            'POST', Uri.parse('$baseUrl/process_complaint'));

        // Add text fields - ensure they're named exactly as expected by the backend
        request.fields['complaint'] = complaint;
        request.fields['location'] = location;

        // Add the file - make sure 'image' matches what the server expects
        try {
          var stream = http.ByteStream(imageFile.openRead());
          var length = await imageFile.length();

          print('Created file stream, length: $length bytes');

          var multipartFile = http.MultipartFile(
              'image', // This name must match what the server expects in request.files['image']
              stream,
              length,
              filename: path.basename(imageFile.path));

          request.files.add(multipartFile);
          print('Added file to request: ${multipartFile.filename}');

          // Print request details for debugging
          print('Request fields: ${request.fields}');
          print('Request files: ${request.files.length} files');
          print('Sending request to: ${request.url}');

          // Send the request
          var streamedResponse = await request.send();
    

          var response = await http.Response.fromStream(streamedResponse);
          print('Response body length: ${response.body.length} bytes');

          if (response.statusCode == 200) {
            return jsonDecode(response.body);
          } else {
            print('Error response from server: ${response.body}');
            throw Exception(
                'Failed to process complaint: ${response.statusCode}');
          }
        } catch (e) {
          print('Error in multipart request: $e');
          throw Exception('Error sending image: $e');
        }
      } else {
        print('No image file provided, sending JSON request');
        // Regular JSON request when no image is included
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
          print('Error from server: ${response.body}');
          throw Exception(
              'Failed to process complaint: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('Error in processComplaint: $e');
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

  // This method is no longer needed as we're sending the actual file
  // in the multipart request above
  /// Upload an image file for processing
  Future<String> uploadImage(File imageFile) async {
    try {
      // Just return the file path, as we'll handle the actual file upload
      // in the processComplaint method
      return imageFile.path;
    } catch (e) {
      throw Exception('Image upload failed: $e');
    }
  }

  /// Predict skin disease from an image
  Future<Map<String, dynamic>> predictSkinDisease(File imageFile) async {
    try {
      print('Predicting skin disease from image: ${imageFile.path}');
      print('Image exists: ${imageFile.existsSync()}');
      print('Image size: ${imageFile.lengthSync()} bytes');

      var request = http.MultipartRequest(
          'POST', Uri.parse('$baseUrl/predict_skin_disease'));

      // Add the image file
      var stream = http.ByteStream(imageFile.openRead());
      var length = await imageFile.length();

      var multipartFile = http.MultipartFile(
          'image',
          stream,
          length,
          filename: path.basename(imageFile.path));

      request.files.add(multipartFile);
      print('Added file to request: ${multipartFile.filename}');

      // Send the request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        print('Response body: ${response.body}');
        return jsonDecode(response.body);
      } else {
        print('Error response from server: ${response.body}');
        throw Exception('Failed to predict skin disease: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in predictSkinDisease: $e');
      throw Exception('Skin disease prediction failed: $e');
    }
  }
}
