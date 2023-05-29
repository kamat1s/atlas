import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

/*
BACKUP OTP
Config
Service ID: service_hywc4fb
Templay ID: template_o84hclo
User ID: odhjvTGZksfb5BxbL

 */

String generate() {
  var random = Random();
  String otp = "";

  for (int i = 0; i < 6; i++) {
    otp += random.nextInt(10).toString();
  }

  return otp;
}

Future send({
  required String email,
  required String otp,
}) async {
  const serviceId = 'service_x809jgp';
  const templateId = 'template_erhua9p';
  const userId = 'X2ktzY76FiMTtWMU1';

  final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
  final response = await http.post(
    url,
    headers: {
      'origin': 'http://localhost',
      'Content-Type': 'application/json',
    },
    body: json.encode(
      {
        'service_id': serviceId,
        'template_id': templateId,
        'user_id': userId,
        'template_params': {
          'email': email,
          'OTP': otp,
        }
      },
    ),
  );

  return response.statusCode;
}
