class Vehicle {
  final int id;
  final String name;

  Vehicle({required this.id, required this.name});

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? 'Desconhecido',
    );
  }

  @override
  String toString() => 'Vehicle(id: $id, name: $name)';
}

class Driver {
  final int id;
  final String name;

  Driver({required this.id, required this.name});

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? 'Desconhecido',
    );
  }

  @override
  String toString() => 'Driver(id: $id, name: $name)';
}

class Route {
  final int id;
  final String name;

  Route({required this.id, required this.name});

  factory Route.fromJson(Map<String, dynamic> json) {
    return Route(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? 'Desconhecido',
    );
  }

  @override
  String toString() => 'Route(id: $id, name: $name)';
}

class Trip {
  final int id;
  final String vehicle;
  final List<String> route;
  final String driver;
  final String status;
  final String time;
  final String date;
  final String km;
  final String kmDeparture;
  final String? kmReturn;
  final String seals;
  final String? lateralSeal;
  final String? rearSeal;
  final int vehicleId;
  final int driverId;
  final bool hasFuelRecord;
  final int? kmFuel;
  final double? liters;
  final double? amountPaid;
  final String? receiptPath;
  final String departureTime;
  final String? returnTime;

  Trip({
    required this.id,
    required this.vehicle,
    required this.route,
    required this.driver,
    required this.status,
    required this.time,
    required this.date,
    required this.km,
    required this.kmDeparture,
    this.kmReturn,
    required this.seals,
    this.lateralSeal,
    this.rearSeal,
    required this.vehicleId,
    required this.driverId,
    required this.hasFuelRecord,
    this.kmFuel,
    this.liters,
    this.amountPaid,
    this.receiptPath,
    required this.departureTime,
    this.returnTime,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      vehicle: json['vehicle']?.toString() ?? 'Desconhecido',
      route: (json['routes'] as List<dynamic>?)?.map((r) => r.toString()).toList() ?? [],
      driver: json['driver']?.toString() ?? 'Desconhecido',
      status: json['status']?.toString() ?? 'Desconhecido',
      time: json['time']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      km: json['km']?.toString() ?? '',
      kmDeparture: json['km_departure']?.toString() ?? '',
      kmReturn: json['km_return']?.toString(),
      seals: json['seals']?.toString() ?? '',
      lateralSeal: json['lateral_seal']?.toString(),
      rearSeal: json['rear_seal']?.toString(),
      vehicleId: json['vehicle_id'] is int ? json['vehicle_id'] as int : int.tryParse(json['vehicle_id']?.toString() ?? '0') ?? 0,
      driverId: json['driver_id'] is int ? json['driver_id'] as int : int.tryParse(json['driver_id']?.toString() ?? '0') ?? 0,
      hasFuelRecord: json['has_fuel_record'] != null && (json['has_fuel_record'] == 1 || json['has_fuel_record'] == true || json['has_fuel_record'].toString() == '1'),
      kmFuel: json['km_fuel'] != null ? (json['km_fuel'] is int ? json['km_fuel'] as int : int.tryParse(json['km_fuel']?.toString() ?? '0')) : null,
      liters: json['liters'] != null ? (json['liters'] is double ? json['liters'] as double : double.tryParse(json['liters']?.toString() ?? '0.0')) : null,
      amountPaid: json['amount_paid'] != null ? (json['amount_paid'] is double ? json['amount_paid'] as double : double.tryParse(json['amount_paid']?.toString() ?? '0.0')) : null,
      receiptPath: json['receipt_path']?.toString(),
      departureTime: json['departure_time']?.toString() ?? '',
      returnTime: json['return_time']?.toString(),
    );
  }

  @override
  String toString() => 'Trip(id: $id, vehicle: $vehicle, driver: $driver)';
}