import 'dart:convert';

import 'package:http/http.dart' as http;

const _cbuUrl = 'https://cbu.uz/uz/arkhiv-kursov-valyut/json/';

Future<List<dynamic>?> fetchCbuRatesJson() async {
  final response = await http
      .get(Uri.parse(_cbuUrl))
      .timeout(const Duration(seconds: 12));
  if (response.statusCode != 200) {
    throw Exception('HTTP ${response.statusCode}');
  }
  return jsonDecode(response.body) as List<dynamic>;
}
