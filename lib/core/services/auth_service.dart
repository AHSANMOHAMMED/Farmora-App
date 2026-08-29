import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../models/user_role.dart';

class AuthService {
  final String _baseUrl = 'https://kku-backend.example.com/api';
  final http.Client _client;

  AuthService({http.Client? client}) : _client = client ?? http.Client();

  Future<Map<String, dynamic>> _request(String endpoint, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    final response = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: body != null ? json.encode(body) : null,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load: ${response.statusCode}');
    }
  }

  Future<bool> register({
    required String name,
    required String phone,
    required String password,
    required Role role,
    String? district,
  }) async {
    final body = {
      'name': name,
      'phone': phone,
      'password': password,
      'role': role.toString().split('.').last,
      if (district != null) 'district': district,
    };

    final response = await _request('/register', body: body);
    return response['success'] as bool;
  }

  Future<bool> login({required String phone, required String password}) async {
    final body = {
      'phone': phone,
      'password': password,
    };

    final response = await _request('/login', body: body);
    return response['success'] as bool;
  }

  Future<String?> getUserToken() async {
    // In a real implementation, this would fetch the stored token
    // For now, return null - the app will use local state
    return null;
  }
}