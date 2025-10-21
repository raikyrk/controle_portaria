import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:controle_portaria/portaria_app/models.dart' as models;
import 'package:controle_portaria/portaria_app/api_service.dart';
import 'package:controle_portaria/portaria_app/widgets.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';

class AppState extends ChangeNotifier {
  models.Vehicle? _selectedVehicle;
  models.Driver? _selectedDriver;
  models.Route? _selectedRoute;
  List<String> _selectedRoutes = [];
  bool _showCustomRoute = false;
  double _textScaleFactor = 1.0;

  models.Vehicle? get selectedVehicle => _selectedVehicle;
  models.Driver? get selectedDriver => _selectedDriver;
  models.Route? get selectedRoute => _selectedRoute;
  List<String> get selectedRoutes => _selectedRoutes;
  bool get showCustomRoute => _showCustomRoute;
  double get textScaleFactor => _textScaleFactor;

  void setVehicle(models.Vehicle? vehicle) {
    _selectedVehicle = vehicle;
    notifyListeners();
  }

  void setDriver(models.Driver? driver) {
    _selectedDriver = driver;
    notifyListeners();
  }

  void setRoute(models.Route? route) {
    _selectedRoute = route;
    notifyListeners();
  }

  void addRoute(String route) {
    if (!_selectedRoutes.contains(route)) {
      _selectedRoutes.add(route);
      notifyListeners();
    }
  }

  void removeRoute(String route) {
    _selectedRoutes.remove(route);
    notifyListeners();
  }

  void toggleCustomRoute() {
    _showCustomRoute = !_showCustomRoute;
    notifyListeners();
  }

  void resetForm() {
    _selectedVehicle = null;
    _selectedDriver = null;
    _selectedRoute = null;
    _selectedRoutes = [];
    _showCustomRoute = false;
    notifyListeners();
  }

  void increaseFontSize() {
    _textScaleFactor = (_textScaleFactor + 0.2).clamp(0.8, 2.0);
    notifyListeners();
  }

  void decreaseFontSize() {
    _textScaleFactor = (_textScaleFactor - 0.2).clamp(0.8, 2.0);
    notifyListeners();
  }
}

Widget buildTextFieldContainer({
  required TextEditingController controller,
  required String hintText,
  required TextInputType keyboardType,
  int? maxLength,
  Function(String)? onChanged,
  Function(String)? onSubmitted,
}) {
  return Container(
    decoration: BoxDecoration(
      border: Border.all(
        color: const Color(0xFF374151),
        width: 2,
      ),
      borderRadius: BorderRadius.circular(8),
    ),
    child: TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      decoration: InputDecoration(
        hintText: hintText,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: InputBorder.none,
        focusedBorder: InputBorder.none,
        enabledBorder: InputBorder.none,
        hintStyle: GoogleFonts.poppins(color: Colors.grey[700]),
      ),
      style: GoogleFonts.poppins(),
      onChanged: onChanged,
      onSubmitted: onSubmitted,
    ),
  );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final _kmDepartureController = TextEditingController();
  final _lateralSealController = TextEditingController();
  final _rearSealController = TextEditingController();
  final _customRouteController = TextEditingController();
  List<models.Vehicle> _vehicles = [];
  List<models.Driver> _drivers = [];
  List<models.Route> _routes = [];
  List<models.Trip> _history = [];
  List<models.Trip> _pendingTrips = [];
  Map<int, bool> _vehiclesInRoute = {};
  Map<int, bool> _driversInRoute = {};
  late DateTime _selectedDate;
  bool _isLoading = true;
  AnimationController? _shakeController;
  Animation<double>? _shakeAnimation;
  late TabController _tabController;

  static const List<String> _routeCreationOrder = [
    'Silviano',
    'Prudente',
    'Belvedere',
    'Pampulha',
    'Mangabeiras',
    'Castelo',
    'Barreiro',
    'Contagem',
    'Silva Lobo',
    'Buritis',
    'Cidade Nova',
    'Afonsos',
    'Ouro Preto',
    'Sion',
    'Lagoa Santa',
    'Serviços Diversos',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    print('Inicializando HomeScreen com _selectedDate: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}');
    _loadOptions();
    _loadHistory();
    _loadPendingTrips();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: -4, end: 4).chain(
      CurveTween(curve: Curves.elasticIn),
    ).animate(_shakeController!);
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _kmDepartureController.dispose();
    _lateralSealController.dispose();
    _rearSealController.dispose();
    _customRouteController.dispose();
    _shakeController?.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOptions() async {
    try {
      print('Iniciando _loadOptions');
      final options = await ApiService.getOptions();
      print('Opções recebidas: Veículos=${options['vehicles']?.length ?? 0}, Motoristas=${options['drivers']?.length ?? 0}, Rotas=${options['routes']?.length ?? 0}');
      print('Veículos brutos: ${options['vehicles']}');
      print('Motoristas brutos: ${options['drivers']}');

      final routes = options['routes'] != null
          ? (options['routes'] as List<dynamic>)
              .where((item) => item is models.Route)
              .cast<models.Route>()
              .toList()
          : <models.Route>[];
      List<models.Route> sortedRoutes = [];
      for (String routeName in _routeCreationOrder) {
        final matchingRoute = routes.firstWhere(
          (route) => route.name == routeName || (routeName == 'Serviços Diversos' && route.name == 'Diversos'),
          orElse: () => models.Route(id: 0, name: ''),
        );
        if (matchingRoute.id != 0 && matchingRoute.name.isNotEmpty) {
          sortedRoutes.add(matchingRoute);
        }
      }
      for (var route in routes) {
        if (!sortedRoutes.contains(route) && route.name != 'Desconhecido' && route.name.isNotEmpty) {
          sortedRoutes.add(route);
        }
      }

      // Remover duplicatas de veículos e motoristas com base no id
      final vehiclesMap = <int, models.Vehicle>{};
      final driversMap = <int, models.Driver>{};

      final vehicles = options['vehicles'] != null
          ? (options['vehicles'] as List<dynamic>)
              .where((item) => item is models.Vehicle)
              .cast<models.Vehicle>()
              .toList()
          : <models.Vehicle>[];
      for (var vehicle in vehicles) {
        vehiclesMap[vehicle.id] = vehicle;
      }

      final drivers = options['drivers'] != null
          ? (options['drivers'] as List<dynamic>)
              .where((item) => item is models.Driver)
              .cast<models.Driver>()
              .toList()
          : <models.Driver>[];
      for (var driver in drivers) {
        driversMap[driver.id] = driver;
      }

      final vehiclesInRoute = <int, bool>{};
      final driversInRoute = <int, bool>{};
      for (var trip in _pendingTrips) {
        if (trip.status == 'Saiu pra Rota') {
          vehiclesInRoute[trip.vehicleId] = true;
          driversInRoute[trip.driverId] = true;
        }
      }

      if (mounted) {
        final appState = Provider.of<AppState>(context, listen: false);
        setState(() {
          _vehicles = vehiclesMap.values.toList();
          _drivers = driversMap.values.toList();
          _routes = sortedRoutes;
          _vehiclesInRoute = vehiclesInRoute;
          _driversInRoute = driversInRoute;

          // Verificar se selectedVehicle e selectedDriver estão nas novas listas
          if (appState.selectedVehicle != null && !_vehicles.contains(appState.selectedVehicle)) {
            appState.setVehicle(null);
          }
          if (appState.selectedDriver != null && !_drivers.contains(appState.selectedDriver)) {
            appState.setDriver(null);
          }
        });
      }
      print('Estado atualizado: _vehicles=${_vehicles.length}, _drivers=${_drivers.length}, _routes=${_routes.length}');
      print('Veículos em rota: $_vehiclesInRoute');
      print('Motoristas em rota: $_driversInRoute');
      print('Rotas ordenadas: ${_routes.map((r) => r.name).toList()}');
    } catch (e, stackTrace) {
      print('Erro em _loadOptions: $e\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('Falha de conexão')
                  ? 'Não foi possível conectar ao servidor. Verifique sua conexão com a internet.'
                  : 'Erro ao carregar opções: $e',
            ),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      if (mounted) {
        setState(() {
          _vehicles = [];
          _drivers = [];
          _routes = [];
          _vehiclesInRoute = {};
          _driversInRoute = {};
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadHistory() async {
    try {
      print('Carregando histórico para data: ${DateFormat('dd/MM/yyyy').format(_selectedDate)} com status: Concluído');
      setState(() {
        _isLoading = true;
      });
      final history = await ApiService.getTrips(
        dateStart: DateFormat('yyyy-MM-dd').format(_selectedDate),
        dateEnd: DateFormat('yyyy-MM-dd').format(_selectedDate),
        status: 'Concluído',
      );
      print('Histórico recebido: ${history.length} registros');
      print('Status das viagens: ${history.map((t) => t.status).toSet().toList()}');
      print('Dados brutos do histórico: ${history.map((t) => t.toString()).toList()}');
      if (mounted) {
        setState(() {
          _history = history;
          _isLoading = false;
        });
        if (history.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Nenhuma rota registrada.'),
              backgroundColor: Colors.blue.shade700,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      print('Erro ao carregar histórico: $e\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('Falha de conexão')
                  ? 'Não foi possível conectar ao servidor. Verifique sua conexão com a internet.'
                  : 'Erro ao carregar histórico: $e',
            ),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 5),
          ),
        );
        setState(() {
          _isLoading = false;
          _history = [];
        });
      }
    }
  }

  Future<void> _loadPendingTrips() async {
    try {
      print('Carregando pendentes com status: Saiu pra Rota');
      final pendingTrips = await ApiService.getPendingTrips();
      print('Pendentes recebido: ${pendingTrips.length} registros');
      print('Status das viagens pendentes: ${pendingTrips.map((t) => t.status).toSet().toList()}');
      print('Pendentes com lacres: ${pendingTrips.map((t) => "ID: ${t.id}, LateralSeal: ${t.lateralSeal}, RearSeal: ${t.rearSeal}").toList()}');
      if (mounted) {
        setState(() {
          _pendingTrips = pendingTrips;
          final vehiclesInRoute = <int, bool>{};
          final driversInRoute = <int, bool>{};
          for (var trip in _pendingTrips) {
            if (trip.status == 'Saiu pra Rota') {
              vehiclesInRoute[trip.vehicleId] = true;
              driversInRoute[trip.driverId] = true;
            }
          }
          _vehiclesInRoute = vehiclesInRoute;
          _driversInRoute = driversInRoute;
          print('Veículos em rota atualizados: $_vehiclesInRoute');
          print('Motoristas em rota atualizados: $_driversInRoute');
        });
      }
    } catch (e, stackTrace) {
      print('Erro ao carregar pendentes: $e\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('Falha de conexão')
                  ? 'Não foi possível conectar ao servidor. Verifique sua conexão com a internet.'
                  : 'Erro ao carregar pendentes: $e',
            ),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 5),
          ),
        );
        setState(() {
          _pendingTrips = [];
          _vehiclesInRoute = {};
          _driversInRoute = {};
        });
      }
    }
  }

  void _submitForm(BuildContext context) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    if (!_validateForm(appState)) {
      _shakeController?.forward().then((value) => _shakeController?.reset());
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: const Text('Preencha todos os campos obrigatórios!'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('Enviando viagem: vehicleId=${appState.selectedVehicle!.id}, driverId=${appState.selectedDriver!.id}, kmDeparture=${_kmDepartureController.text}, lateralSeal=${_lateralSealController.text}, rearSeal=${_rearSealController.text}, routes=${appState.selectedRoutes}');
      final tripId = await ApiService.saveTrip(
        vehicleId: appState.selectedVehicle!.id,
        driverId: appState.selectedDriver!.id,
        kmDeparture: _kmDepartureController.text,
        lateralSeal: appState.selectedVehicle!.name == 'Iveco' ? _lateralSealController.text : null,
        rearSeal: appState.selectedVehicle!.name == 'Iveco' || appState.selectedVehicle!.name == 'Fiorino' ? _rearSealController.text : null,
        routes: appState.selectedRoutes,
        routeMap: {for (var r in _routes) r.name: r.id},
      );
      print('Viagem salva com ID: $tripId');
      await _loadHistory();
      await _loadPendingTrips();
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: const Text('Registro salvo com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        appState.resetForm();
        _kmDepartureController.clear();
        _lateralSealController.clear();
        _rearSealController.clear();
        _customRouteController.clear();
      }
    } catch (e, stackTrace) {
      print('Erro ao salvar viagem: $e\n$stackTrace');
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('Falha de conexão')
                  ? 'Não foi possível conectar ao servidor. Verifique sua conexão com a internet.'
                  : e.toString().contains('Uma viagem idêntica')
                      ? 'Esta viagem já foi registrada recentemente.'
                      : 'Erro ao salvar registro: $e',
            ),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteTrip(int tripId) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      setState(() {
        _isLoading = true;
      });
      await ApiService.deleteTrip(tripId);
      await _loadHistory();
      await _loadPendingTrips();
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: const Text('Rota excluída com sucesso!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e, stackTrace) {
      print('Erro ao excluir viagem: $e\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('Falha de conexão')
                  ? 'Não foi possível conectar ao servidor. Verifique sua conexão com a internet.'
                  : 'Erro ao excluir rota: $e',
            ),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  bool _validateForm(AppState appState) {
    if (appState.selectedVehicle == null ||
        appState.selectedDriver == null ||
        _kmDepartureController.text.isEmpty ||
        appState.selectedRoutes.isEmpty) {
      return false;
    }
    if (appState.selectedVehicle!.name == 'Iveco' &&
        (_lateralSealController.text.isEmpty || _rearSealController.text.isEmpty)) {
      return false;
    }
    if (appState.selectedVehicle!.name == 'Fiorino' && _rearSealController.text.isEmpty) {
      return false;
    }
    return true;
  }

  Widget _buildSectionTitle(String title, IconData icon, bool isTablet, {bool useGrayBackground = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: useGrayBackground ? Colors.grey[200] : const Color(0xFFFFEDD5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: useGrayBackground ? const Color(0xFF374151) : const Color(0xFFF97316),
              size: 24,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1F2937),
            ),
          ),
          const Text(
            '*',
            style: TextStyle(color: Colors.red),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Theme(
      data: ThemeData(
        primarySwatch: Colors.blue,
        colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Colors.blue,
              secondary: Colors.blueAccent,
            ),
      ),
      child: Scaffold(
        body: Stack(
          children: [
            SafeArea(
              child: SingleChildScrollView(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Botão de voltar no canto superior esquerdo
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF6A00), Color(0xFFFF8B3D)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF6A00).withOpacity(0.35),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(FeatherIcons.arrowLeft, color: Colors.white, size: 24),
                            onPressed: () {
                              Navigator.pushReplacementNamed(context, '/menu');
                            },
                            tooltip: 'Voltar ao Menu',
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF24514), Color(0xFFD93D12)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 4)),
                          ],
                        ),
                        padding: const EdgeInsets.all(24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(FontAwesomeIcons.carSide, color: Colors.white, size: 28),
                                const SizedBox(width: 8),
                                Text(
                                  'Controle de Veículos - Portaria',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFF374151), width: 1),
                                  ),
                                  child: Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(FontAwesomeIcons.circleMinus, color: Color(0xFFF97316), size: 20),
                                        onPressed: () {
                                          appState.decreaseFontSize();
                                        },
                                        tooltip: 'Diminuir texto',
                                      ),
                                      const SizedBox(width: 4),
                                      IconButton(
                                        icon: const Icon(FontAwesomeIcons.circlePlus, color: Color(0xFFF97316), size: 20),
                                        onPressed: () {
                                          appState.increaseFontSize();
                                        },
                                        tooltip: 'Aumentar texto',
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 4)),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(FontAwesomeIcons.calendarDay, color: Color(0xFF374151), size: 24),
                            const SizedBox(width: 12),
                            Text(
                              'Hoje: ${DateFormat('EEEE, d MMMM yyyy', 'pt_BR').format(DateTime.now())}',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF1F2937),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 4)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle('Veículo', FontAwesomeIcons.truck, isTablet),
                            CustomDropdown<models.Vehicle>(
                              items: _vehicles,
                              selectedItem: appState.selectedVehicle,
                              hint: 'Selecione um veículo',
                              displayText: (vehicle) => _vehiclesInRoute[vehicle.id] == true ? '${vehicle.name} (Em Rota)' : vehicle.name,
                              onChanged: (vehicle) {
                                appState.setVehicle(vehicle);
                                setState(() {});
                              },
                              isDisabled: (vehicle) => _vehiclesInRoute[vehicle.id] ?? false,
                            ),
                            const SizedBox(height: 16),
                            _buildSectionTitle('Rota (destino)', FontAwesomeIcons.route, isTablet),
                            CustomDropdown<models.Route>(
                              items: _routes,
                              selectedItem: appState.selectedRoute,
                              hint: 'Selecione uma ou mais rotas',
                              displayText: (route) => route.name,
                              onChanged: (route) {
                                if (route != null) {
                                  if (route.name == 'Serviços Diversos') {
                                    appState.toggleCustomRoute();
                                  } else {
                                    appState.addRoute(route.name);
                                  }
                                  appState.setRoute(null);
                                }
                                setState(() {});
                              },
                              isDisabled: (_) => false,
                            ),
                            if (appState.showCustomRoute) ...[
                              const SizedBox(height: 16),
                              _buildSectionTitle('Descreva o destino', FontAwesomeIcons.pen, isTablet),
                              Row(
                                children: [
                                  Expanded(
                                    child: buildTextFieldContainer(
                                      controller: _customRouteController,
                                      hintText: 'Digite o destino e pressione Enter...',
                                      keyboardType: TextInputType.text,
                                      onSubmitted: (value) {
                                        if (value.trim().isNotEmpty) {
                                          appState.addRoute(value.trim());
                                          _customRouteController.clear();
                                          setState(() {});
                                        }
                                      },
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(FontAwesomeIcons.circlePlus, color: Color(0xFFF97316)),
                                    onPressed: () {
                                      if (_customRouteController.text.trim().isNotEmpty) {
                                        appState.addRoute(_customRouteController.text.trim());
                                        _customRouteController.clear();
                                        setState(() {});
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: appState.selectedRoutes.asMap().entries.map((entry) {
                                return RouteTag(
                                  route: entry.value,
                                  index: entry.key,
                                  onRemove: () {
                                    appState.removeRoute(entry.value);
                                    setState(() {});
                                  },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 16),
                            _buildSectionTitle('KM Saída', FontAwesomeIcons.gaugeHigh, isTablet),
                            buildTextFieldContainer(
                              controller: _kmDepartureController,
                              hintText: '00000',
                              keyboardType: TextInputType.number,
                              onChanged: (value) => setState(() {}),
                            ),
                            const SizedBox(height: 16),
                            if (appState.selectedVehicle?.name == 'Iveco' || appState.selectedVehicle?.name == 'Fiorino') ...[
                              Row(
                                children: [
                                  if (appState.selectedVehicle?.name == 'Iveco') ...[
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          _buildSectionTitle('Lacre Lateral', FontAwesomeIcons.lock, isTablet),
                                          buildTextFieldContainer(
                                            controller: _lateralSealController,
                                            hintText: '0000000',
                                            keyboardType: TextInputType.number,
                                            maxLength: 7,
                                            onChanged: (value) => setState(() {}),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                  ],
                                  if (appState.selectedVehicle?.name == 'Iveco' || appState.selectedVehicle?.name == 'Fiorino') ...[
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          _buildSectionTitle('Lacre Traseiro', FontAwesomeIcons.lock, isTablet, useGrayBackground: true),
                                          buildTextFieldContainer(
                                            controller: _rearSealController,
                                            hintText: '0000000',
                                            keyboardType: TextInputType.number,
                                            maxLength: 7,
                                            onChanged: (value) => setState(() {}),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 16),
                            ],
                            _buildSectionTitle('Motorista', FontAwesomeIcons.user, isTablet),
                            CustomDropdown<models.Driver>(
                              items: _drivers,
                              selectedItem: appState.selectedDriver,
                              hint: 'Selecione um motorista',
                              displayText: (driver) => _driversInRoute[driver.id] == true ? '${driver.name} (Em Rota)' : driver.name,
                              onChanged: (driver) {
                                appState.setDriver(driver);
                                setState(() {});
                              },
                              isDisabled: (driver) => _driversInRoute[driver.id] ?? false,
                            ),
                            const SizedBox(height: 24),
                            SummaryCard(
                              vehicle: appState.selectedVehicle?.name ?? 'Nenhum selecionado',
                              routes: appState.selectedRoutes,
                              driver: appState.selectedDriver?.name ?? 'Nenhum selecionado',
                              kmDeparture: _kmDepartureController.text,
                              lateralSeal: _lateralSealController.text,
                              rearSeal: _rearSealController.text,
                            ),
                            const SizedBox(height: 24),
                            AnimatedBuilder(
                              animation: _shakeController!,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(_shakeAnimation?.value ?? 0, 0),
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : () => _submitForm(context),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFF97316),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      minimumSize: const Size(double.infinity, 48),
                                    ),
                                    child: _isLoading
                                        ? const CircularProgressIndicator(
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          )
                                        : Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(FontAwesomeIcons.floppyDisk, color: Colors.white),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Registrar Rota',
                                                style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: const [
                                  BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 4)),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(FontAwesomeIcons.clockRotateLeft, color: Color(0xFFF97316)),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Registros',
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF1F2937),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          SizedBox(
                                            width: isTablet ? 200 : 150,
                                            child: InkWell(
                                              onTap: () async {
                                                print('Campo de data clicado, data atual: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}');
                                                final selected = await showDatePicker(
                                                  context: context,
                                                  initialDate: _selectedDate,
                                                  firstDate: DateTime(2000),
                                                  lastDate: DateTime.now(),
                                                  locale: const Locale('pt', 'BR'),
                                                );
                                                if (selected != null && selected != _selectedDate && mounted) {
                                                  setState(() {
                                                    _selectedDate = selected;
                                                  });
                                                  print('Nova data selecionada: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}');
                                                  await _loadHistory();
                                                }
                                              },
                                              child: InputDecorator(
                                                decoration: InputDecoration(
                                                  hintText: 'Filtrar por data',
                                                  suffixIcon: const Icon(FontAwesomeIcons.calendarDays, color: Color(0xFF374151)),
                                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                  border: OutlineInputBorder(
                                                    borderSide: const BorderSide(color: Color(0xFF374151), width: 2),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  enabledBorder: OutlineInputBorder(
                                                    borderSide: const BorderSide(color: Color(0xFF374151), width: 2),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  focusedBorder: OutlineInputBorder(
                                                    borderSide: const BorderSide(color: Color(0xFFF97316), width: 2),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                ),
                                                child: Text(
                                                  DateFormat('dd/MM/yyyy', 'pt_BR').format(_selectedDate),
                                                  style: GoogleFonts.poppins(
                                                    color: const Color(0xFF1F2937),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            icon: const Icon(FontAwesomeIcons.arrowsRotate, color: Color(0xFFF97316), size: 24),
                                            onPressed: () async {
                                              print('Botão de atualizar clicado, recarregando histórico e pendentes');
                                              setState(() {
                                                _isLoading = true;
                                              });
                                              await _loadHistory();
                                              await _loadPendingTrips();
                                              setState(() {
                                                _isLoading = false;
                                              });
                                            },
                                            tooltip: 'Atualizar histórico',
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  TabBar(
                                    controller: _tabController,
                                    indicatorColor: const Color(0xFFF97316),
                                    labelColor: const Color(0xFFF97316),
                                    unselectedLabelColor: const Color(0xFF1F2937),
                                    tabs: [
                                      Tab(
                                        child: Text(
                                          'Pendentes',
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Tab(
                                        child: Text(
                                          'Concluídos',
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    height: MediaQuery.of(context).size.height * 0.5,
                                    child: TabBarView(
                                      controller: _tabController,
                                      children: [
                                        // Aba Pendentes
                                        _pendingTrips.isEmpty
                                            ? Center(
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    const Icon(
                                                      FontAwesomeIcons.clipboardList,
                                                      size: 48,
                                                      color: Color(0xFF9CA3AF),
                                                    ),
                                                    const SizedBox(height: 16),
                                                    Text(
                                                      'Nenhuma rota pendente.',
                                                      style: GoogleFonts.poppins(
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            : SingleChildScrollView(
                                                physics: const ClampingScrollPhysics(),
                                                child: ListView.builder(
                                                  shrinkWrap: true,
                                                  physics: const NeverScrollableScrollPhysics(),
                                                  itemCount: _pendingTrips.length,
                                                  itemBuilder: (context, index) {
                                                    final trip = _pendingTrips[index];
                                                    return HistoryItem(
                                                      trip: trip,
                                                      onEdit: () {
                                                        showDialog(
                                                          context: context,
                                                          builder: (context) => EditTripDialog(
                                                            trip: trip,
                                                            onSave: () async {
                                                              await _loadHistory();
                                                              await _loadPendingTrips();
                                                              if (mounted) {
                                                                setState(() {});
                                                              }
                                                            },
                                                          ),
                                                        );
                                                      },
                                                      onDelete: () => _deleteTrip(trip.id),
                                                    );
                                                  },
                                                ),
                                              ),
                                        // Aba Histórico
                                        _isLoading
                                            ? const Center(
                                                child: CircularProgressIndicator(
                                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF97316)),
                                                ),
                                              )
                                            : _history.isEmpty
                                                ? Center(
                                                    child: Column(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        const Icon(
                                                          FontAwesomeIcons.clipboardList,
                                                          size: 48,
                                                          color: Color(0xFF9CA3AF),
                                                        ),
                                                        const SizedBox(height: 16),
                                                        Text(
                                                          'Nenhuma rota registrada.',
                                                          style: GoogleFonts.poppins(
                                                            color: Colors.grey[600],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  )
                                                : SingleChildScrollView(
                                                    physics: const ClampingScrollPhysics(),
                                                    child: ListView.builder(
                                                      shrinkWrap: true,
                                                      physics: const NeverScrollableScrollPhysics(),
                                                      itemCount: _history.length,
                                                      itemBuilder: (context, index) {
                                                        final trip = _history[index];
                                                        return HistoryItem(
                                                          trip: trip,
                                                          onEdit: () {
                                                            showDialog(
                                                              context: context,
                                                              builder: (context) => EditTripDialog(
                                                                trip: trip,
                                                                onSave: () async {
                                                                  await _loadHistory();
                                                                  await _loadPendingTrips();
                                                                  if (mounted) {
                                                                    setState(() {});
                                                                  }
                                                                },
                                                              ),
                                                            );
                                                          },
                                                          onDelete: () => _deleteTrip(trip.id),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EditTripDialog extends StatefulWidget {
  final models.Trip trip;
  final VoidCallback onSave;

  const EditTripDialog({super.key, required this.trip, required this.onSave});

  @override
  State<EditTripDialog> createState() => _EditTripDialogState();
}

class _EditTripDialogState extends State<EditTripDialog> with SingleTickerProviderStateMixin {
  final _kmReturnController = TextEditingController();
  AnimationController? _shakeController;
  Animation<double>? _shakeAnimation;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _kmReturnController.text = widget.trip.kmReturn ?? '';
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: -4, end: 4).chain(
      CurveTween(curve: Curves.elasticIn),
    ).animate(_shakeController!);
  }

  @override
  void dispose() {
    _kmReturnController.dispose();
    _shakeController?.dispose();
    super.dispose();
  }

  void _submit() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    if (_kmReturnController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Preencha o KM de Retorno!';
      });
      _shakeController?.forward().then((value) => _shakeController?.reset());
      return;
    }

    try {
      await ApiService.updateTrip(widget.trip.id, _kmReturnController.text);
      widget.onSave();
      if (mounted) {
        Navigator.of(context).pop();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: const Text('Rota concluída com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e, stackTrace) {
      print('Erro ao concluir rota: $e\n$stackTrace');
      String errorMessage = e.toString().contains('Falha de conexão')
          ? 'Não foi possível conectar ao servidor. Verifique sua conexão com a internet.'
          : 'Erro ao concluir rota: $e';
      if (mounted) {
        setState(() {
          _errorMessage = errorMessage;
        });
        _shakeController?.forward().then((value) => _shakeController?.reset());
      }
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value, bool isTablet) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.grey[500]),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    color: Colors.grey[600],
                  ),
                ),
                if (label == 'Rota' && widget.trip.route.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: widget.trip.route.asMap().entries.map((entry) {
                      int idx = entry.key + 1;
                      String route = entry.value;
                      return Text(
                        '$idx. $route',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1F2937),
                        ),
                      );
                    }).toList(),
                  )
                else
                  Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: Colors.white,
      contentPadding: const EdgeInsets.all(24),
      content: SizedBox(
        width: isTablet ? 400 : 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(FontAwesomeIcons.penToSquare, color: Color(0xFFF97316)),
                    const SizedBox(width: 8),
                    Text(
                      'Concluir Rota',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(FontAwesomeIcons.truck, 'Veículo', widget.trip.vehicle, isTablet),
            _buildInfoRow(FontAwesomeIcons.route, 'Rota', '', isTablet),
            _buildInfoRow(FontAwesomeIcons.user, 'Motorista', widget.trip.driver, isTablet),
            if (widget.trip.vehicle == 'Iveco' && widget.trip.lateralSeal != null && widget.trip.lateralSeal!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildInfoRow(FontAwesomeIcons.lock, 'Lacre Lateral', widget.trip.lateralSeal!, isTablet),
            ],
            if ((widget.trip.vehicle == 'Iveco' || widget.trip.vehicle == 'Fiorino') && widget.trip.rearSeal != null && widget.trip.rearSeal!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildInfoRow(FontAwesomeIcons.lock, 'Lacre Traseiro', widget.trip.rearSeal!, isTablet),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEDD5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(FontAwesomeIcons.gaugeHigh, color: Color(0xFFF97316), size: 20),
                ),
                const SizedBox(width: 8),
                Text(
                  'KM Retorno',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                const Text(
                  '*',
                  style: TextStyle(color: Colors.red),
                ),
              ],
            ),
            const SizedBox(height: 8),
            buildTextFieldContainer(
              controller: _kmReturnController,
              hintText: '00000',
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  _errorMessage = null;
                });
              },
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: GoogleFonts.poppins(
                  color: Colors.red[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 16),
            AnimatedBuilder(
              animation: _shakeController!,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(_shakeAnimation?.value ?? 0, 0),
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF97316),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(FontAwesomeIcons.circleCheck, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          'Concluir Rota',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}