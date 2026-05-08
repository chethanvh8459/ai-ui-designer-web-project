import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiConfig {
  static const String baseUrl = 'https://internship-backend-api.vercel.app';

  // API endpoints (add as needed)
  static const String designEndpoint = '$baseUrl/api/design';
  static const String generateEndpoint = '$baseUrl/api/generate';
  // ... other endpoints
}

class ApiClient {
  static const String _baseUrl = 'https://internship-backend-api.vercel.app';

  Future<http.Response> get(String endpoint) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    return await http.get(url);
  }

  Future<http.Response> post(
    String endpoint, {
    required Map<String, dynamic> body,
  }) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    return await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );
  }
}
