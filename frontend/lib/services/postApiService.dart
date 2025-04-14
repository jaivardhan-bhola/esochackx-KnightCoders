import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart' as DotEnv;
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:http_parser/http_parser.dart';

class PostApiService {
  static var client = http.Client();
  static var server_url =
      '${DotEnv.dotenv.env['HOST']}:${DotEnv.dotenv.env['PORT']}';
  static var token = DotEnv.dotenv.env['VAR_API_TOKEN'];

  // Fetch all posts
  static Future<List<dynamic>> getPosts() async {
    Map<String, String> requestHeaders = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token'
    };

    var url = Uri.http(server_url, '/api/posts', {
      'populate': '*',
    });

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

  // Fetch a specific post by ID
  static Future<Map<String, dynamic>?> getPostById(String id) async {
    Map<String, String> requestHeaders = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token'
    };

    var url = Uri.parse('$server_url/api/posts/$id');

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

  // Create a new post
  static Future<bool> createPost({
    required String title,
    String? description,
    File? mediaFile,
    int? userId,
  }) async {
    Map<String, String> requestHeaders = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token'
    };

    var url = Uri.http(server_url, '/api/posts');

    int? mediaId;
    if (mediaFile != null) {
      mediaId = await uploadMedia(mediaFile);
      print('Media ID: $mediaId');
    }

    var payload = jsonEncode({
      'data': {
        'title': title,
        'description': description,
        if (mediaId != null) 'media': mediaId,
        if (userId != null)
          'users_permissions_user': userId,
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

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error creating post: $e');
      return false;
    }
  }

  // Upload media to Strapi
  static Future<int?> uploadMedia(File mediaFile) async {
    try {
      var uri = Uri.http(server_url, '/api/upload');

      // Create multipart request
      var request = http.MultipartRequest('POST', uri);

      // Add authorization header
      request.headers['Authorization'] = 'Bearer $token';

      // Add the file
      var stream = http.ByteStream(mediaFile.openRead());
      var length = await mediaFile.length();
      var filename = mediaFile.path.split('/').last;

      var multipartFile = http.MultipartFile(
        'files',
        stream,
        length,
        filename: filename,
        contentType: MediaType(
          filename.toLowerCase().endsWith('.mp4') ? 'video' : 'image',
          filename.split('.').last,
        ),
      );

      request.files.add(multipartFile);

      // Send the request
      var response = await request.send();

      // Get response as string
      var responseData = await response.stream.bytesToString();
      var responseJson = jsonDecode(responseData);

      // Check if upload was successful
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Return the ID of the uploaded media for Strapi relationship
        if (responseJson is List && responseJson.isNotEmpty) {
          print('Media uploaded successfully: ${responseJson}');
          return responseJson[0]['id'];
        }
      }

      print('Media upload failed: ${response.statusCode}, $responseJson');
      return null;
    } catch (e) {
      print('Error uploading media: $e');
      return null;
    }
  }

  // Update an existing post
  static Future<bool> updatePost({
    required String id,
    String? title,
    String? description,
    int? mediaId,
    int? userId,
  }) async {
    Map<String, String> requestHeaders = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token'
    };

    var url = Uri.http(server_url, '/api/posts/$id');

    var payload = jsonEncode({
      'data': {
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (mediaId != null) 'media': mediaId,
        if (userId != null) 'users_permissions_user': userId,
      }
    });

    try {
      print('Updating post at URL: ${url.toString()}');
      print('Payload: $payload');

      var response = await client.put(
        url,
        headers: requestHeaders,
        body: payload,
      );
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      print('Error updating post: $e');
      return false;
    }
  }

  // Delete a post
  static Future<bool> deletePost(String id) async {
    Map<String, String> requestHeaders = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token'
    };

    var url = Uri.parse('$server_url/api/posts/$id');

    var response = await client.delete(
      url,
      headers: requestHeaders,
    );

    return response.statusCode == 200;
  }

  // Get posts for a specific user
  static Future<List<dynamic>> getPostsByUserId(int userId) async {
    Map<String, String> requestHeaders = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token'
    };

    var url = Uri.parse(
        '$server_url/api/posts?filters[users_permissions_user][id][eq]=$userId&populate=*');

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