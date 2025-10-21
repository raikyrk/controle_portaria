import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  static String? get baseUrl => dotenv.env['BASE_URL'];

  Future<List<Map<String, dynamic>>> fetchMotoboys() async {
    if (baseUrl == null) {
      throw Exception('BASE_URL não configurada no arquivo .env');
    }
    final response = await http.get(Uri.parse('$baseUrl/get_motoboys.php'));
    print('Request URL: $baseUrl/get_motoboys.php');
    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => {
        'id': int.parse(item['id'].toString()),
        'nome': item['nome'] as String,
        'placa': item['placa'] as String,
      }).toList();
    } else {
      throw Exception('Erro ao carregar motoboys: ${response.statusCode} - ${response.body}');
    }
  }

  Future<List<String>> fetchConferentes() async {
    if (baseUrl == null) {
      throw Exception('BASE_URL não configurada no arquivo .env');
    }
    final response = await http.get(Uri.parse('$baseUrl/get_conferentes.php'));
    print('Request URL: $baseUrl/get_conferentes.php');
    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => item['nome'] as String).toList();
    } else {
      throw Exception('Erro ao carregar conferentes: ${response.statusCode} - ${response.body}');
    }
  }

  Future<List<String>> fetchPlacas() async {
    if (baseUrl == null) {
      throw Exception('BASE_URL não configurada no arquivo .env');
    }
    final response = await http.get(Uri.parse('$baseUrl/get_placas.php'));
    print('Request URL: $baseUrl/get_placas.php');
    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => item['placa'] as String).toList();
    } else {
      throw Exception('Erro ao carregar placas: ${response.statusCode} - ${response.body}');
    }
  }

  Future<Map<String, dynamic>> saveRegistro(Map<String, dynamic> data) async {
    if (baseUrl == null) {
      throw Exception('BASE_URL não configurada no arquivo .env');
    }
    final response = await http.post(
      Uri.parse('$baseUrl/save_registro.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );
    print('Request URL: $baseUrl/save_registro.php');
    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');
    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Erro ao salvar registro: ${response.statusCode} - ${response.body}');
    }
  }
}