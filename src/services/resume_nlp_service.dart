import 'dart:convert';
import 'package:http/http.dart' as http;

class ResumeNLPService {

  static Future<List<String>> extractSkills(String resumeUrl) async {

    final response = await http.post(
      Uri.parse("http://10.1.40.238:3000/extract-resume"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "resumeUrl": resumeUrl,
      }),
    );

    final data = jsonDecode(response.body);

    if (data['extractedSkills'] == null) {
      return [];
    }

    return List<String>.from(data['extractedSkills']);
  }
}