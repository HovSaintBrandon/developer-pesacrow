import 'dart:convert';
import 'package:http/http.dart' as http;

class FeeService {
  static const String baseUrl = 'https://api.escrow.pesacrow.top/api';

  Future<Map<String, dynamic>> calculateFees(double amount) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/fees/calculate?amount=$amount'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'];
        } else {
          throw Exception(data['message'] ?? 'Failed to calculate fees');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }
}
