import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';

class ApiService {
  // URL base centralizada
  static String get apiUrl => dotenv.env['API_URL'] ?? 'https://aogosto.store/mototrack/api';

  // === BUSCAR CONFERENTES ===
  static Future<List<Map<String, dynamic>>> fetchConferentes() async {
    final url = Uri.parse('$apiUrl/get_conferentes.php');
    print('GET: $url');

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
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
    final url = Uri.parse('$apiUrl/veiculosreg/register_entrada.php');

    final registro = {
      'conferente_id': conferenteId,
      'placa': placa.trim().toUpperCase(),
      'modelo': modelo.trim(),
      'motorista': motorista.trim(),
      'id_motorista': idMotorista.trim(),
      'data_registro': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      'horario_chegada': DateFormat('HH:mm').format(DateTime.now()),
    };

    print('POST: $url | Payload: ${json.encode(registro)}');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(registro),
      ).timeout(const Duration(seconds: 15));

      print('Status: ${response.statusCode} | Response: ${response.body}');

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        return result['success'] == true;
      }
      throw Exception('Erro ${response.statusCode}: ${response.body}');
    } catch (e) {
      print('Erro registerEntrada: $e');
      rethrow;
    }
  }

  // === BUSCAR VEÍCULO POR PLACA (verifica se está dentro) ===
  static Future<Map<String, dynamic>?> searchVehicle(String placa) async {
    final url = Uri.parse('$apiUrl/veiculosreg/veiculos_status.php?placa=${placa.trim().toUpperCase()}');
    print('GET: $url');

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      print('Status: ${response.statusCode} | Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['status'] == 'dentro') {
          return data['veiculo'] as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      print('Erro searchVehicle: $e');
      return null;
    }
  }

  // === LISTAR VEÍCULOS DENTRO HOJE (para o dropdown de saída) ===
  static Future<List<Map<String, dynamic>>> fetchVeiculosDentroHoje() async {
    final url = Uri.parse('$apiUrl/veiculosreg/veiculos_status.php');
    print('GET: $url');

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      print('Status: ${response.statusCode} | Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final veiculos = data['veiculos'] as List<dynamic>? ?? [];
          return veiculos.cast<Map<String, dynamic>>();
        }
      }
      return [];
    } catch (e) {
      print('Erro fetchVeiculosDentroHoje: $e');
      return [];
    }
  }

  // === REGISTRAR SAÍDA (CORRIGIDO E 100% FUNCIONAL) ===
  static Future<bool> registerSaida(String placa, String horarioSaida) async {
    final url = Uri.parse('$apiUrl/veiculosreg/register_saida.php');

    final payload = {
      'placa': placa.trim().toUpperCase(),
      'horario_saida': horarioSaida, // Agora vem do formulário
    };

    print('POST: $url | Payload: ${json.encode(payload)}');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      ).timeout(const Duration(seconds: 15));

      print('Status: ${response.statusCode} | Response: ${response.body}');

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        return result['success'] == true;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Erro ${response.statusCode}');
      }
    } catch (e) {
      print('Erro registerSaida: $e');
      rethrow;
    }
  }
}