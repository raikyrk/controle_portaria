import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:controle_portaria/portaria_app/models.dart' as models;
import 'package:controle_portaria/portaria_app/api_service.dart';
import 'package:controle_portaria/portaria_app/widgets.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:controle_portaria/main.dart'; // Importa AppState global

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

// CLASSE CORRIGIDA: PortariaHomeScreen
class PortariaHomeScreen extends StatefulWidget {
  const PortariaHomeScreen({super.key});

  @override
  State<PortariaHomeScreen> createState() => _PortariaHomeScreenState();
}

class _PortariaHomeScreenState extends State<PortariaHomeScreen> with TickerProviderStateMixin {
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
    'Silviano', 'Prudente', 'Belvedere', 'Pampulha', 'Mangabeiras', 'Castelo',
    'Barreiro', 'Contagem', 'Silva Lobo', 'Buritis', 'Cidade Nova', 'Afonsos',
    'Ouro Preto', 'Sion', 'Lagoa Santa', 'Serviços Diversos',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
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
      final options = await ApiService.getOptions();
      final routes = options['routes'] != null
          ? (options['routes'] as List<dynamic>)
              .whereType<models.Route>()
              .toList()
          : <models.Route>[];

      List<models.Route> sortedRoutes = [];
      for (String routeName in _routeCreationOrder) {
        final matchingRoute = routes.firstWhere(
          (route) => route.name == routeName || (routeName == 'Serviços Diversos' && route.name == 'Diversos'),
          orElse: () => models.Route(id: 0, name: ''),
        );
        if (matchingRoute.id != 0) sortedRoutes.add(matchingRoute);
      }
      for (var route in routes) {
        if (!sortedRoutes.contains(route) && route.name != 'Desconhecido' && route.name.isNotEmpty) {
          sortedRoutes.add(route);
        }
      }

      final vehiclesMap = <int, models.Vehicle>{};
      final driversMap = <int, models.Driver>{};

      final vehicles = options['vehicles'] != null
          ? (options['vehicles'] as List<dynamic>).whereType<models.Vehicle>().toList()
          : <models.Vehicle>[];
      for (var v in vehicles) vehiclesMap[v.id] = v;

      final drivers = options['drivers'] != null
          ? (options['drivers'] as List<dynamic>).whereType<models.Driver>().toList()
          : <models.Driver>[];
      for (var d in drivers) driversMap[d.id] = d;

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

          if (appState.selectedVehicle != null && !_vehicles.contains(appState.selectedVehicle)) {
            appState.setVehicle(null);
          }
          if (appState.selectedDriver != null && !_drivers.contains(appState.selectedDriver)) {
            appState.setDriver(null);
          }
        });
      }
    } catch (e, stackTrace) {
      print('Erro em _loadOptions: $e\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().contains('Falha de conexão')
                ? 'Não foi possível conectar ao servidor.'
                : 'Erro ao carregar opções: $e'),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 5),
          ),
        );
        setState(() {
          _vehicles = [];
          _drivers = [];
          _routes = [];
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadHistory() async {
    try {
      setState(() => _isLoading = true);
      final history = await ApiService.getTrips(
        dateStart: DateFormat('yyyy-MM-dd').format(_selectedDate),
        dateEnd: DateFormat('yyyy-MM-dd').format(_selectedDate),
        status: 'Concluído',
      );
      if (mounted) {
        setState(() {
          _history = history;
          _isLoading = false;
        });
        if (history.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nenhuma rota registrada.'), backgroundColor: Colors.blue, duration: Duration(seconds: 3)),
          );
        }
      }
    } catch (e, stackTrace) {
      print('Erro ao carregar histórico: $e\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().contains('Falha de conexão')
                ? 'Não foi possível conectar ao servidor.'
                : 'Erro ao carregar histórico: $e'),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 5),
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadPendingTrips() async {
    try {
      final pendingTrips = await ApiService.getPendingTrips();
      if (mounted) {
        setState(() {
          _pendingTrips = pendingTrips;
          final v = <int, bool>{};
          final d = <int, bool>{};
          for (var t in _pendingTrips) {
            if (t.status == 'Saiu pra Rota') {
              v[t.vehicleId] = true;
              d[t.driverId] = true;
            }
          }
          _vehiclesInRoute = v;
          _driversInRoute = d;
        });
      }
    } catch (e, stackTrace) {
      print('Erro ao carregar pendentes: $e\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().contains('Falha de conexão')
                ? 'Não foi possível conectar ao servidor.'
                : 'Erro ao carregar pendentes: $e'),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _submitForm(BuildContext context) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    if (!_validateForm(appState)) {
      _shakeController?.forward().then((_) => _shakeController?.reset());
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos obrigatórios!'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final tripId = await ApiService.saveTrip(
        vehicleId: appState.selectedVehicle!.id,
        driverId: appState.selectedDriver!.id,
        kmDeparture: _kmDepartureController.text,
        lateralSeal: appState.selectedVehicle!.name == 'Iveco' ? _lateralSealController.text : null,
        rearSeal: (appState.selectedVehicle!.name == 'Iveco' || appState.selectedVehicle!.name == 'Fiorino') ? _rearSealController.text : null,
        routes: appState.selectedRoutes,
        routeMap: {for (var r in _routes) r.name: r.id},
      );
      await _loadHistory();
      await _loadPendingTrips();
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Registro salvo com sucesso!'), backgroundColor: Colors.green),
      );
      appState.resetForm();
      _kmDepartureController.clear();
      _lateralSealController.clear();
      _rearSealController.clear();
      _customRouteController.clear();
    } catch (e, stackTrace) {
      print('Erro ao salvar: $e\n$stackTrace');
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(e.toString().contains('idêntica') ? 'Viagem já registrada.' : 'Erro ao salvar: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteTrip(int tripId) async {
    try {
      setState(() => _isLoading = true);
      await ApiService.deleteTrip(tripId);
      await _loadHistory();
      await _loadPendingTrips();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rota excluída com sucesso!'), backgroundColor: Colors.green),
      );
    } catch (e, stackTrace) {
      print('Erro ao excluir: $e\n$stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir: $e'), backgroundColor: Colors.red.shade700),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _validateForm(AppState appState) {
    if (appState.selectedVehicle == null ||
        appState.selectedDriver == null ||
        _kmDepartureController.text.isEmpty ||
        appState.selectedRoutes.isEmpty) return false;
    if (appState.selectedVehicle!.name == 'Iveco' &&
        (_lateralSealController.text.isEmpty || _rearSealController.text.isEmpty)) return false;
    if (appState.selectedVehicle!.name == 'Fiorino' && _rearSealController.text.isEmpty) return false;
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
            child: Icon(icon, color: useGrayBackground ? const Color(0xFF374151) : const Color(0xFFF97316), size: 24),
          ),
          const SizedBox(width: 8),
          Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF1F2937))),
          const Text('*', style: TextStyle(color: Colors.red)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Theme(
      data: ThemeData(primarySwatch: Colors.blue, colorScheme: Theme.of(context).colorScheme.copyWith(primary: Colors.blue, secondary: Colors.blueAccent)),
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
                      // Botão voltar
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFFFF6A00), Color(0xFFFF8B3D)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [BoxShadow(color: const Color(0xFFFF6A00).withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 6))],
                          ),
                          child: IconButton(
                            icon: const Icon(FeatherIcons.arrowLeft, color: Colors.white, size: 24),
                            onPressed: () => Navigator.pushReplacementNamed(context, '/menu'),
                            tooltip: 'Voltar ao Menu',
                          ),
                        ),
                      ),

                      // Header
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFFF24514), Color(0xFFD93D12)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 4))],
                        ),
                        padding: const EdgeInsets.all(24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(FontAwesomeIcons.carSide, color: Colors.white, size: 28),
                                const SizedBox(width: 8),
                                Text('Controle de Veículos - Portaria', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                              ],
                            ),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF374151))),
                                  child: Row(
                                    children: [
                                      IconButton(icon: const Icon(FontAwesomeIcons.circleMinus, color: Color(0xFFF97316), size: 20), onPressed: appState.decreaseFontSize, tooltip: 'Diminuir texto'),
                                      const SizedBox(width: 4),
                                      IconButton(icon: const Icon(FontAwesomeIcons.circlePlus, color: Color(0xFFF97316), size: 20), onPressed: appState.increaseFontSize, tooltip: 'Aumentar texto'),
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
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 4))]),
                        child: Row(
                          children: [
                            const Icon(FontAwesomeIcons.calendarDay, color: Color(0xFF374151), size: 24),
                            const SizedBox(width: 12),
                            Text('Hoje: ${DateFormat('EEEE, d MMMM yyyy', 'pt_BR').format(DateTime.now())}', style: GoogleFonts.poppins(fontWeight: FontWeight.w500, color: const Color(0xFF1F2937))),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 4))]),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle('Veículo', FontAwesomeIcons.truck, isTablet),
                            CustomDropdown<models.Vehicle>(
                              items: _vehicles,
                              selectedItem: appState.selectedVehicle,
                              hint: 'Selecione um veículo',
                              displayText: (v) => _vehiclesInRoute[v.id] == true ? '${v.name} (Em Rota)' : v.name,
                              onChanged: (v) { appState.setVehicle(v); setState(() {}); },
                              isDisabled: (v) => _vehiclesInRoute[v.id] ?? false,
                            ),

                            const SizedBox(height: 16),
                            _buildSectionTitle('Rota (destino)', FontAwesomeIcons.route, isTablet),
                            CustomDropdown<models.Route>(
                              items: _routes,
                              selectedItem: appState.selectedRoute,
                              hint: 'Selecione uma ou mais rotas',
                              displayText: (r) => r.name,
                              onChanged: (r) {
                                if (r != null) {
                                  if (r.name == 'Serviços Diversos') {
                                    appState.toggleCustomRoute();
                                  } else {
                                    appState.addRoute(r.name);
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
                                      onSubmitted: (v) {
                                        if (v.trim().isNotEmpty) {
                                          appState.addRoute(v.trim());
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
                              children: appState.selectedRoutes.asMap().entries.map((e) {
                                return RouteTag(
                                  route: e.value,
                                  index: e.key,
                                  onRemove: () { appState.removeRoute(e.value); setState(() {}); },
                                );
                              }).toList(),
                            ),

                            const SizedBox(height: 16),
                            _buildSectionTitle('KM Saída', FontAwesomeIcons.gaugeHigh, isTablet),
                            buildTextFieldContainer(
                              controller: _kmDepartureController,
                              hintText: '00000',
                              keyboardType: TextInputType.number,
                              onChanged: (_) => setState(() {}),
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
                                            onChanged: (_) => setState(() {}),
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
                                            onChanged: (_) => setState(() {}),
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
                              displayText: (d) => _driversInRoute[d.id] == true ? '${d.name} (Em Rota)' : d.name,
                              onChanged: (d) { appState.setDriver(d); setState(() {}); },
                              isDisabled: (d) => _driversInRoute[d.id] ?? false,
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
                                        ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                                        : Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(FontAwesomeIcons.floppyDisk, color: Colors.white),
                                              const SizedBox(width: 8),
                                              Text('Registrar Rota', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
                                            ],
                                          ),
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 4))]),
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
                                          Text('Registros', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF1F2937))),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          SizedBox(
                                            width: isTablet ? 200 : 150,
                                            child: InkWell(
                                              onTap: () async {
                                                final selected = await showDatePicker(
                                                  context: context,
                                                  initialDate: _selectedDate,
                                                  firstDate: DateTime(2000),
                                                  lastDate: DateTime.now(),
                                                  locale: const Locale('pt', 'BR'),
                                                );
                                                if (selected != null && selected != _selectedDate && mounted) {
                                                  setState(() => _selectedDate = selected);
                                                  await _loadHistory();
                                                }
                                              },
                                              child: InputDecorator(
                                                decoration: InputDecoration(
                                                  hintText: 'Filtrar por data',
                                                  suffixIcon: const Icon(FontAwesomeIcons.calendarDays, color: Color(0xFF374151)),
                                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                  border: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFF374151), width: 2), borderRadius: BorderRadius.circular(8)),
                                                  enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFF374151), width: 2), borderRadius: BorderRadius.circular(8)),
                                                  focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFFF97316), width: 2), borderRadius: BorderRadius.circular(8)),
                                                ),
                                                child: Text(DateFormat('dd/MM/yyyy', 'pt_BR').format(_selectedDate), style: GoogleFonts.poppins(color: const Color(0xFF1F2937))),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            icon: const Icon(FontAwesomeIcons.arrowsRotate, color: Color(0xFFF97316), size: 24),
                                            onPressed: () async {
                                              setState(() => _isLoading = true);
                                              await _loadHistory();
                                              await _loadPendingTrips();
                                              setState(() => _isLoading = false);
                                            },
                                            tooltip: 'Atualizar',
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
                                      Tab(child: Text('Pendentes', style: GoogleFonts.poppins(fontWeight: FontWeight.w600))),
                                      Tab(child: Text('Concluídos', style: GoogleFonts.poppins(fontWeight: FontWeight.w600))),
                                    ],
                                  ),

                                  const SizedBox(height: 16),
                                  SizedBox(
                                    height: MediaQuery.of(context).size.height * 0.5,
                                    child: TabBarView(
                                      controller: _tabController,
                                      children: [
                                        _pendingTrips.isEmpty
                                            ? const Center(child: Text('Nenhuma rota pendente.', style: TextStyle(color: Colors.grey)))
                                            : ListView.builder(
                                                shrinkWrap: true,
                                                physics: const ClampingScrollPhysics(),
                                                itemCount: _pendingTrips.length,
                                                itemBuilder: (context, i) {
                                                  final trip = _pendingTrips[i];
                                                  return HistoryItem(
                                                    trip: trip,
                                                    onEdit: () {
                                                      showDialog(
                                                        context: context,
                                                        builder: (_) => EditTripDialog(
                                                          trip: trip,
                                                          onSave: () async {
                                                            await _loadHistory();
                                                            await _loadPendingTrips();
                                                            if (mounted) setState(() {});
                                                          },
                                                        ),
                                                      );
                                                    },
                                                    onDelete: () => _deleteTrip(trip.id),
                                                  );
                                                },
                                              ),

                                        _isLoading
                                            ? const Center(child: CircularProgressIndicator())
                                            : _history.isEmpty
                                                ? const Center(child: Text('Nenhuma rota registrada.', style: TextStyle(color: Colors.grey)))
                                                : ListView.builder(
                                                    shrinkWrap: true,
                                                    physics: const ClampingScrollPhysics(),
                                                    itemCount: _history.length,
                                                    itemBuilder: (context, i) {
                                                      final trip = _history[i];
                                                      return HistoryItem(
                                                        trip: trip,
                                                        onEdit: () {
                                                          showDialog(
                                                            context: context,
                                                            builder: (_) => EditTripDialog(
                                                              trip: trip,
                                                              onSave: () async {
                                                                await _loadHistory();
                                                                await _loadPendingTrips();
                                                                if (mounted) setState(() {});
                                                              },
                                                            ),
                                                          );
                                                        },
                                                        onDelete: () => _deleteTrip(trip.id),
                                                      );
                                                    },
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
    _shakeController = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    _shakeAnimation = Tween<double>(begin: -4, end: 4).chain(CurveTween(curve: Curves.elasticIn)).animate(_shakeController!);
  }

  @override
  void dispose() {
    _kmReturnController.dispose();
    _shakeController?.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_kmReturnController.text.isEmpty) {
      setState(() => _errorMessage = 'Preencha o KM de Retorno!');
      _shakeController?.forward().then((_) => _shakeController?.reset());
      return;
    }

    try {
      await ApiService.updateTrip(widget.trip.id, _kmReturnController.text);
      widget.onSave();
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rota concluída com sucesso!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      setState(() => _errorMessage = 'Erro ao concluir: $e');
      _shakeController?.forward().then((_) => _shakeController?.reset());
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value, bool isTablet) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: Colors.grey[500])),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.poppins(color: Colors.grey[600])),
                if (label == 'Rota' && widget.trip.route.isNotEmpty)
                  ...widget.trip.route.asMap().entries.map((e) => Text('${e.key + 1}. ${e.value}', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: const Color(0xFF1F2937))))
                else
                  Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: const Color(0xFF1F2937))),
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
                    Text('Concluir Rota', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF1F2937))),
                  ],
                ),
                IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => Navigator.of(context).pop()),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(FontAwesomeIcons.truck, 'Veículo', widget.trip.vehicle, isTablet),
            _buildInfoRow(FontAwesomeIcons.route, 'Rota', '', isTablet),
            _buildInfoRow(FontAwesomeIcons.user, 'Motorista', widget.trip.driver, isTablet),
            if (widget.trip.vehicle == 'Iveco' && widget.trip.lateralSeal != null && widget.trip.lateralSeal!.isNotEmpty)
              _buildInfoRow(FontAwesomeIcons.lock, 'Lacre Lateral', widget.trip.lateralSeal!, isTablet),
            if ((widget.trip.vehicle == 'Iveco' || widget.trip.vehicle == 'Fiorino') && widget.trip.rearSeal != null && widget.trip.rearSeal!.isNotEmpty)
              _buildInfoRow(FontAwesomeIcons.lock, 'Lacre Traseiro', widget.trip.rearSeal!, isTablet),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFFFEDD5), borderRadius: BorderRadius.circular(8)), child: const Icon(FontAwesomeIcons.gaugeHigh, color: Color(0xFFF97316), size: 20)),
                const SizedBox(width: 8),
                Text('KM Retorno', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF1F2937))),
                const Text('*', style: TextStyle(color: Colors.red)),
              ],
            ),
            const SizedBox(height: 8),
            buildTextFieldContainer(
              controller: _kmReturnController,
              hintText: '00000',
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() => _errorMessage = null),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(_errorMessage!, style: GoogleFonts.poppins(color: Colors.red[600]), textAlign: TextAlign.center),
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
                        Text('Concluir Rota', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
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