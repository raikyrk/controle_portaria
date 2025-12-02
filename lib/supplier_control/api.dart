import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';

class Api {
  static String get apiUrl => dotenv.env['API_URL'] ?? 'https://aogosto.store/mototrack/api';

  static Future<List<Map<String, dynamic>>> fetchConferentes() async {
    final url = '$apiUrl/get_conferentes.php';
    print('GET: $url');

    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      print('Status: ${response.statusCode} | Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      throw Exception('Failed to load gatekeepers: ${response.statusCode}');
    } catch (e) {
      print('Error fetchConferentes: $e');
      rethrow;
    }
  }

  static Future<bool> registerSupplierEntry({
    required String conferenteId,
    required String placa,
    required String motorista,
    required String idMotorista,
    required String empresa,
  }) async {
    final url = '$apiUrl/fornecedores/register_entrada.php';
    final registro = {
      'conferente_id': conferenteId,
      'placa': placa.trim().toUpperCase(),
      'motorista': motorista.trim(),
      'id_motorista': idMotorista.trim(),
      'empresa': empresa.trim(),
      'data_registro': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      'horario_chegada': DateFormat('HH:mm').format(DateTime.now()),
    };

    print('POST: $url');
    print('Payload: ${json.encode(registro)}');

    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(registro),
          )
          .timeout(const Duration(seconds: 15));

      print('Status: ${response.statusCode}');
      print('Response: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final result = json.decode(response.body);
          return result['success'] == true;
        } catch (e) {
          print('Invalid JSON: $e');
          return false;
        }
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } on http.ClientException catch (e) {
      throw Exception('Network error: $e');
    } catch (e) {
      print('Error registerSupplierEntry: $e');
      rethrow;
    }
  }


  static Future<List<Map<String, dynamic>>> fetchSuppliersInsideToday() async {
    final url = '$apiUrl/fornecedores/fornecedores_status.php';
    print('GET: $url');

    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      print('Status: ${response.statusCode} | Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['fornecedores'] ?? []);
        }
      }
      return [];
    } catch (e) {
      print('Error fetchSuppliersInsideToday: $e');
      return [];
    }
  }


  static Future<bool> registerSupplierExit(String placa) async {
    final url = '$apiUrl/fornecedores/register_saida.php';
    final payload = {
      'placa': placa.trim().toUpperCase(),
      'horario_saida': DateFormat('HH:mm').format(DateTime.now()),
    };

    print('POST: $url | Payload: ${json.encode(payload)}');

    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(payload),
          )
          .timeout(const Duration(seconds: 15));

      print('Status: ${response.statusCode} | Response: ${response.body}');

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        return result['success'] == true;
      }
      throw Exception('Error ${response.statusCode}');
    } catch (e) {
      print('Error registerSupplierExit: $e');
      rethrow;
    }
  }
}