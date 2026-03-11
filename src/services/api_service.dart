import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:3000';

  static Future<int> getCompatibilityScore(
    List<String> candidateSkills,
    List<String> jobSkills,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/compatibility'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'candidateSkills': candidateSkills,
        'jobSkills': jobSkills,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['score'];
    } else {
      throw Exception('Failed to calculate compatibility');
    }
  }
}
