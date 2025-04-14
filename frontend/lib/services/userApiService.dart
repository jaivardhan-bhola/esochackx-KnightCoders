import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart' as DotEnv;
import 'package:http/http.dart' as http;

class UserApiService {
  static var client = http.Client();
  static var server_url =
      '${DotEnv.dotenv.env['HOST']}:${DotEnv.dotenv.env['PORT']}';
  static var token = DotEnv.dotenv.env['USER_API_TOKEN'];

  static Future<Map<String, dynamic>> loginUser(
      String email, String password) async {
    try {
      var uri = Uri.http(server_url, '/api/auth/local');
      var response = await client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'identifier': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        token = data['jwt'];
        return data;
      } else {
        throw Exception('Login failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Login error: $e');
    }
  }

  static Future<Map<String, dynamic>> registerUser(
      String email, String password, String name, String phone) async {
    try {
      var uri = Uri.http(server_url, '/api/auth/local/register');
      var response = await client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'email': email,
          'password': password,
          'username': name,
          'phone': phone,
          'type': 'Citizen',
        }),
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        token = data['jwt'];
        return data;
      } else {
        throw Exception('Registration failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Registration error: $e');
    }
  }

  // Update user profile information
  static Future<Map<String, dynamic>> updateUserProfile(
      String userId, String name, String email, String phone) async {
    try {
      var uri = Uri.http(server_url, '/api/users/$userId');
      var response = await client.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'username': name,
          'email': email,
          'phone': phone,
        }),
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        return data;
      } else {
        throw Exception('Profile update failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Profile update error: $e');
    }
  }

  // Change user password
  static Future<Map<String, dynamic>> changePassword(
      String userId, String currentPassword, String newPassword) async {
    try {
      var uri = Uri.http(server_url, '/api/auth/change-password');
      var response = await client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'currentPassword': currentPassword,
          'password': newPassword,
          'passwordConfirmation': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        // Update token if the API returns a new one
        if (data.containsKey('jwt')) {
          token = data['jwt'];
        }
        return data;
      } else {
        throw Exception('Password change failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Password change error: $e');
    }
  }
}
