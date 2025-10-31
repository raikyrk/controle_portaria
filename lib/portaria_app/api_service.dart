import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:controle_portaria/portaria_app/models.dart' as models;

const String apiBaseUrl = String.fromEnvironment('PORTARIA_BASE_URL', defaultValue: 'https://aogosto.store/portaria/');

class ApiService {
  static Future<Map<String, dynamic>> getOptions() async {
    try {
      print('Tentando conectar a: ${apiBaseUrl}get_options.php');
      final response = await http.get(Uri.parse('${apiBaseUrl}get_options.php')).timeout(const Duration(seconds: 30));
      print('Resposta: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is! Map<String, dynamic>) {
          throw Exception('Resposta JSON inválida: não é um objeto');
        }
        if (data['success']) {
          final vehicles = (data['vehicles'] as List?)?.map((v) => models.Vehicle.fromJson(v)).toList() ?? [];
          final drivers = (data['drivers'] as List?)?.map((d) => models.Driver.fromJson(d)).toList() ?? [];
          final routes = (data['routes'] as List?)?.map((r) => models.Route.fromJson(r)).toList() ?? [];
          print('Veículos: ${vehicles.length}, Motoristas: ${drivers.length}, Rotas: ${routes.length}');
          return {
            'vehicles': vehicles,
            'drivers': drivers,
            'routes': routes,
          };
        } else {
          throw Exception('${data['error']} (Debug: ${data['debug']?['steps']?.join(', ') ?? 'Sem debug'})');
        }
      } else {
        throw Exception('Erro ao conectar com o servidor: ${response.statusCode} - ${response.body}');
      }
    } on SocketException {
      throw Exception('Falha de conexão: Não foi possível conectar ao servidor.');
    } catch (e) {
      throw Exception('Erro inesperado ao carregar opções: $e');
    }
  }

  static Future<List<models.Trip>> getTrips({
    String? dateStart,
    String? dateEnd,
    String? status,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (dateStart != null) queryParams['date_start'] = dateStart;
      if (dateEnd != null) queryParams['date_end'] = dateEnd;
      if (status != null) queryParams['status'] = status;

      final uri = Uri.parse(apiBaseUrl + 'get_trips.php').replace(queryParameters: queryParams);
      print('Tentando conectar a: $uri');
      final response = await http.get(uri).timeout(const Duration(seconds: 30));
      print('Resposta: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Dados recebidos: $data');
        if (data['success']) {
          final trips = (data['data'] as List?)?.map((t) => models.Trip.fromJson(t)).toList() ?? [];
          print('Viagens carregadas: ${trips.length}');
          print('Status das viagens: ${trips.map((t) => t.status).toSet().toList()}');
          return trips;
        } else {
          throw Exception('${data['error']} (Debug: ${data['debug']?['steps']?.join(', ') ?? 'Sem debug'})');
        }
      } else {
        throw Exception('Erro ao conectar com o servidor: ${response.statusCode} - ${response.body}');
      }
    } on SocketException {
      throw Exception('Falha de conexão: Não foi possível conectar ao servidor.');
    } catch (e) {
      throw Exception('Erro inesperado ao carregar histórico: $e');
    }
  }

  static Future<List<models.Trip>> getPendingTrips() async {
    return await getTrips(status: 'Saiu pra Rota');
  }

  static Future<int> saveTrip({
    required int vehicleId,
    required int driverId,
    required String kmDeparture,
    required String? lateralSeal,
    required String? rearSeal,
    required List<String> routes,
    required Map<String, int> routeMap,
  }) async {
    try {
      print('Enviando viagem: vehicleId=$vehicleId, driverId=$driverId, kmDeparture=$kmDeparture, lateralSeal=$lateralSeal, rearSeal=$rearSeal, routes=$routes');
      final response = await http.post(
        Uri.parse('${apiBaseUrl}save_trip.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'vehicle_id': vehicleId,
          'driver_id': driverId,
          'km_departure': kmDeparture,
          'lateral_seal': lateralSeal,
          'rear_seal': rearSeal,
          'status': 'Saiu pra Rota',
          'routes': routes.asMap().entries.map((e) => {
                'id': routeMap[e.value] ?? 0,
                'name': e.value,
                'custom': routeMap[e.value] == null ? e.value : null,
              }).toList(),
        }),
      ).timeout(const Duration(seconds: 30));
      print('Resposta: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          print('Viagem salva com ID: ${data['trip_id']}');
          return int.parse(data['trip_id'].toString());
        } else {
          throw Exception('${data['error']} (Debug: ${data['debug']?['steps']?.join(', ') ?? 'Sem debug'})');
        }
      } else {
        throw Exception('Erro ao conectar com o servidor: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Falha de conexão: Não foi possível conectar ao servidor.');
    } catch (e) {
      throw Exception('Erro inesperado ao salvar viagem: $e');
    }
  }

  static Future<void> updateTrip(int tripId, String kmReturn) async {
    try {
      print('Atualizando viagem: tripId=$tripId, kmReturn=$kmReturn');
      final response = await http.post(
        Uri.parse('${apiBaseUrl}update_trip.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': tripId,
          'km_return': kmReturn,
          'status': 'Concluído',
        }),
      ).timeout(const Duration(seconds: 30));
      print('Resposta: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          print('Viagem atualizada com sucesso');
        } else {
          String debugInfo = 'Sem debug';
          if (data['debug'] != null && data['debug'] is Map) {
            debugInfo = (data['debug']['steps'] as List?)?.join(', ') ?? 'Debug incompleto';
          }
          throw Exception('${data['error']} (Debug: $debugInfo)');
        }
      } else {
        throw Exception('Erro ao conectar com o servidor: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Falha de conexão: Não foi possível conectar ao servidor.');
    } catch (e) {
      throw Exception('Erro inesperado ao atualizar viagem: $e');
    }
  }

  static Future<void> deleteTrip(int tripId) async {
    try {
      print('Deletando viagem: tripId=$tripId');
      final response = await http.post(
        Uri.parse('${apiBaseUrl}delete_trip.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': tripId}),
      ).timeout(const Duration(seconds: 30));
      print('Resposta: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (!data['success']) {
          throw Exception('${data['error']} (Debug: ${data['debug']?['steps']?.join(', ') ?? 'Sem debug'})');
        }
        print('Viagem deletada com sucesso');
      } else {
        throw Exception('Erro ao conectar com o servidor: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Falha de conexão: Não foi possível conectar ao servidor.');
    } catch (e) {
      throw Exception('Erro inesperado ao deletar viagem: $e');
    }
  }
}