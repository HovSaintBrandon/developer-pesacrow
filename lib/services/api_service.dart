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

  void _log(String method, String endpoint, Map<String, dynamic>? body, http.Response response) {
    print('🚀 [API REQUEST] $method $endpoint');
    if (body != null) {
      final maskedBody = Map<String, dynamic>.from(body);
      if (maskedBody.containsKey('otp')) maskedBody['otp'] = '******';
      if (maskedBody.containsKey('kraPin')) maskedBody['kraPin'] = '******';
      print('📦 Payload: $maskedBody');
    }
    print('📥 Response (${response.statusCode}): ${response.body}');
    print('-----------------------------------');
  }

  Future<Map<String, dynamic>> sendOtp(String phone) async {
    final endpoint = '$baseUrl/auth/send-otp';
    final body = {'phone': phone, 'role': 'seller'};
    final response = await http.post(
      Uri.parse(endpoint),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    _log('POST', endpoint, body, response);
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> verifyOtp(String phone, String otp) async {
    final endpoint = '$baseUrl/auth/verify-otp';
    final body = {'phone': phone, 'otp': otp, 'role': 'seller'};
    final response = await http.post(
      Uri.parse(endpoint),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    _log('POST', endpoint, body, response);
    
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
    required String webhookUrl,
  }) async {
    if (_token == null) throw Exception('Not authenticated');

    final endpoint = '$baseUrl/platforms/request-go-live';
    final Map<String, dynamic> body = {
      'name': name,
      'email': email,
      'platformPhone': platformPhone,
      'webhookUrl': webhookUrl,
    };

    final response = await http.post(
      Uri.parse(endpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
      body: jsonEncode(body),
    );
    
    _log('POST', endpoint, body, response);
    return _handleResponse(response);
  }

  // KYC Endpoints
  Future<Map<String, dynamic>> checkId(String idNumber, String taxpayerType) async {
    final endpoint = '$baseUrl/kyc/check-id';
    final body = {'idNumber': idNumber, 'taxpayerType': taxpayerType};
    final response = await http.post(
      Uri.parse(endpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
      body: jsonEncode(body),
    );
    _log('POST', endpoint, body, response);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> validateNames(String names) async {
    final endpoint = '$baseUrl/kyc/validate-names';
    final body = {'names': names};
    final response = await http.post(
      Uri.parse(endpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
      body: jsonEncode(body),
    );
    _log('POST', endpoint, body, response);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> validatePin(String kraPin) async {
    final endpoint = '$baseUrl/kyc/validate-pin';
    final body = {'kraPin': kraPin};
    final response = await http.post(
      Uri.parse(endpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
      body: jsonEncode(body),
    );
    _log('POST', endpoint, body, response);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> ocrUpload({
    required List<int> idFrontBytes,
    required String idFrontName,
    required List<int> kraPinBytes,
    required String kraPinName,
    List<int>? idBackBytes,
    String? idBackName,
  }) async {
    final endpoint = '$baseUrl/kyc/ocr-upload';
    final request = http.MultipartRequest('POST', Uri.parse(endpoint));
    request.headers['Authorization'] = 'Bearer $_token';
    
    request.files.add(http.MultipartFile.fromBytes('idFront', idFrontBytes, filename: idFrontName));
    request.files.add(http.MultipartFile.fromBytes('kraPinImage', kraPinBytes, filename: kraPinName));
    
    if (idBackBytes != null && idBackName != null) {
      request.files.add(http.MultipartFile.fromBytes('idBack', idBackBytes, filename: idBackName));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    _log('POST (MULTIPART)', endpoint, {'files': [idFrontName, kraPinName, idBackName]}, response);
    return _handleResponse(response);
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (response.statusCode >= 400) {
        return {
          'success': false,
          'statusCode': response.statusCode,
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
