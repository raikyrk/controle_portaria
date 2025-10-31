import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';

class ApiService {
  static String get apiUrl => dotenv.env['API_URL'] ?? 'https://aogosto.store/mototrack/api';

  // === FETCH CONFERENTES ===
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
      throw Exception('Falha ao carregar conferentes: ${response.statusCode}');
    } catch (e) {
      print('Erro fetchConferentes: $e');
      rethrow;
    }
  }

  // === REGISTRAR ENTRADA ===
  static Future<bool> registerEntrada({
    required String conferenteId,
    required String placa,
    required String modelo,
    required String motorista,
    required String idMotorista,
  }) async {
    final url = '$apiUrl/veiculosreg/register_entrada.php';
    final registro = {
      'conferente_id': conferenteId,
      'placa': placa.trim().toUpperCase(),
      'modelo': modelo.trim(),
      'motorista': motorista.trim(),
      'id_motorista': idMotorista.trim(),
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
          print('JSON inválido: $e');
          return false;
        }
      } else {
        throw Exception('Erro ${response.statusCode}: ${response.body}');
      }
    } on http.ClientException catch (e) {
      throw Exception('Erro de rede: $e');
    } catch (e) {
      print('Erro registerEntrada: $e');
      rethrow;
    }
  }

  // === BUSCAR 1 VEÍCULO POR PLACA (ANTIGO search_vehicle) ===
  static Future<Map<String, dynamic>?> searchVehicle(String placa) async {
    final url = '$apiUrl/veiculosreg/veiculos_status.php?placa=${placa.trim().toUpperCase()}';
    print('GET: $url');

    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      print('Status: ${response.statusCode} | Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['status'] == 'dentro') {
          return data['veiculo'];
        }
      }
      return null;
    } catch (e) {
      print('Erro searchVehicle: $e');
      return null;
    }
  }

  // === LISTAR TODOS OS VEÍCULOS DENTRO HOJE (DROPDOWN) ===
  static Future<List<Map<String, dynamic>>> fetchVeiculosDentroHoje() async {
    final url = '$apiUrl/veiculosreg/veiculos_status.php';
    print('GET: $url');

    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      print('Status: ${response.statusCode} | Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['veiculos'] ?? []);
        }
      }
      return [];
    } catch (e) {
      print('Erro fetchVeiculosDentroHoje: $e');
      return [];
    }
  }

  // === REGISTRAR SAÍDA ===
  static Future<bool> registerSaida(String placa) async {
    final url = '$apiUrl/veiculosreg/register_saida.php';
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
      throw Exception('Erro ${response.statusCode}');
    } catch (e) {
      print('Erro registerSaida: $e');
      rethrow;
    }
  }
}