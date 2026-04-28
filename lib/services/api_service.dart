import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://api.escrow.pesacrow.top/api';
  
  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _token;

  void setToken(String token) {
    _token = token;
  }

  Future<Map<String, dynamic>> sendOtp(String phone) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/send-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone, 'role': 'seller'}),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> verifyOtp(String phone, String otp) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/verify-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone, 'otp': otp, 'role': 'seller'}),
    );
    
    final data = jsonDecode(response.body);
    if (data['success'] == true) {
      _token = data['data']['token'];
    }
    return data;
  }

  Future<Map<String, dynamic>> requestGoLive({
    required String name,
    required String email,
    required String platformPhone,
    String? webhookUrl,
  }) async {
    if (_token == null) throw Exception('Not authenticated');

    final Map<String, dynamic> body = {
      'name': name,
      'email': email,
      'platformPhone': platformPhone,
    };
    if (webhookUrl != null && webhookUrl.isNotEmpty) {
      body['webhookUrl'] = webhookUrl;
    }

    final response = await http.post(
      Uri.parse('$baseUrl/platforms/request-go-live'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
      body: jsonEncode(body),
    );
    
    try {
      final decoded = jsonDecode(response.body);
      if (response.statusCode != 200 && response.statusCode != 201) {
        return {
          'success': false,
          'message': decoded['message'] ?? 'Server error (${response.statusCode})',
        };
      }
      return decoded;
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to parse server response',
      };
    }
  }
}
