import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart' as DotEnv;
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:http_parser/http_parser.dart';

class ComplaintsApiService {
  static var client = http.Client();
  static var server_url =
      '${DotEnv.dotenv.env['HOST']}:${DotEnv.dotenv.env['PORT']}';
  static var token = DotEnv.dotenv.env['VAR_API_TOKEN'];

  // Fetch all complaints
  static Future<List<dynamic>> getComplaints() async {
    Map<String, String> requestHeaders = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token'
    };

    var url = Uri.http(server_url, '/api/complaints');

    var response = await client.get(
      url,
      headers: requestHeaders,
    );

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      return data['data'];
    } else {
      return [];
    }
  }

  // Fetch a specific complaint by ID
  static Future<Map<String, dynamic>?> getComplaintById(String id) async {
    Map<String, String> requestHeaders = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token'
    };

    var url = Uri.parse('$server_url/api/complaints/$id');

    var response = await client.get(
      url,
      headers: requestHeaders,
    );

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      return data['data'];
    } else {
      return null;
    }
  }

  // Create a new complaint
  static Future<bool> createComplaint({
    String? longText,
    String? summarisedText,
    String? complaintStatus,
    int? complaintSeverity,
    String? location,
    String? department,
    File? imageFile,
    int? userId, // Added userId parameter
  }) async {
    Map<String, String> requestHeaders = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token'
    };

    var url = Uri.http(server_url, '/api/complaints');

    int? imageId;
    if (imageFile != null) {
      imageId = await uploadImage(imageFile);
      print('Image ID: $imageId');
    }

    var payload = jsonEncode({
      'data': {
        'longText': longText,
        'summarisedText': summarisedText,
        'complaintStatus': complaintStatus,
        'complaintSeverity': complaintSeverity,
        'Location': location,
        'Department': department,
        if (imageId != null) 'image': [imageId],
        if (userId != null)
          'users_permissions_user': userId, // Associate complaint with user
      }
    });
    try {
      var response = await client.post(
        url,
        headers: requestHeaders,
        body: payload,
      );
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      print('Error creating complaint: $e');
      return false;
    }
  }

  // Upload an image to Strapi
  static Future<int?> uploadImage(File imageFile) async {
    try {
      var uri = Uri.http(server_url, '/api/upload');

      // Create multipart request
      var request = http.MultipartRequest('POST', uri);

      // Add authorization header
      request.headers['Authorization'] = 'Bearer $token';

      // Add the file
      var stream = http.ByteStream(imageFile.openRead());
      var length = await imageFile.length();
      var filename = imageFile.path.split('/').last;

      var multipartFile = http.MultipartFile(
        'files',
        stream,
        length,
        filename: filename,
        contentType: MediaType('image', filename.split('.').last),
      );

      request.files.add(multipartFile);

      // Send the request
      var response = await request.send();

      // Get response as string
      var responseData = await response.stream.bytesToString();
      var responseJson = jsonDecode(responseData);

      // Check if upload was successful
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Return the ID of the uploaded image for Strapi relationship
        if (responseJson is List && responseJson.isNotEmpty) {
          print('Image uploaded successfully: ${responseJson}');
          return responseJson[0]['id'];
        }
      }

      print('Image upload failed: ${response.statusCode}, $responseJson');
      return null;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  // Update an existing complaint
  static Future<bool> updateComplaint({
    required String id,
    String? longText,
    String? summarisedText,
    String? officialResponse,
    String? imageUrl,
    String? complaintStatus,
    int? complaintSeverity,
    int? userId, // Added userId parameter
  }) async {
    Map<String, String> requestHeaders = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token'
    };

    // Use the id as documentId in the URL
    var url = Uri.http(server_url, '/api/complaints/$id');

    var payload = jsonEncode({
      'data': {
        if (longText != null) 'longText': longText,
        if (summarisedText != null) 'summarisedText': summarisedText,
        if (officialResponse != null) 'officialResponse': officialResponse,
        if (imageUrl != null) 'image': [imageUrl],
        if (complaintStatus != null) 'complaintStatus': complaintStatus,
        if (complaintSeverity != null) 'complaintSeverity': complaintSeverity,
        if (userId != null)
          'users_permissions_user': userId, // Associate complaint with user
      }
    });

    try {
      print('Updating complaint at URL: ${url.toString()}');
      print('Payload: $payload');
      print('Using documentId: $id');

      var response = await client.put(
        url,
        headers: requestHeaders,
        body: payload,
      );
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      print('Error updating complaint: $e');
      return false;
    }
  }

  // Delete a complaint
  static Future<bool> deleteComplaint(String id) async {
    Map<String, String> requestHeaders = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token'
    };

    var url = Uri.parse('$server_url/api/complaints/$id');

    var response = await client.delete(
      url,
      headers: requestHeaders,
    );

    return response.statusCode == 200;
  }

  // Get complaints for a specific user
  static Future<List<dynamic>> getComplaintsByUserId(int userId) async {
    Map<String, String> requestHeaders = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token'
    };

    var url = Uri.parse(
        '$server_url/api/complaints?filters[users_permissions_user][id][eq]=$userId');

    var response = await client.get(
      url,
      headers: requestHeaders,
    );

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      return data['data'];
    } else {
      return [];
    }
  }
}
