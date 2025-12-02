import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:controle_portaria/portaria_app/models.dart' as models;
import 'package:controle_portaria/portaria_app/api_service.dart';
import 'package:controle_portaria/portaria_app/widgets.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:controle_portaria/main.dart';
import 'package:animate_do/animate_do.dart';

// ================================
// PALETA DE CORES
// ================================
class AppColors {
  static const Color primary = Color(0xFFF97316);
  static const Color primaryDark = Color(0xFFEA580C);
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
}

// ================================
// PORTARIA HOME SCREEN
// ================================
class PortariaHomeScreen extends StatefulWidget {
  const PortariaHomeScreen({super.key});

  @override
  State<PortariaHomeScreen> createState() => _PortariaHomeScreenState();
}

class _PortariaHomeScreenState extends State<PortariaHomeScreen>
    with TickerProviderStateMixin {
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

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
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
    _shakeAnimation = Tween<double>(begin: -6, end: 6)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeController);

    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _kmDepartureController.dispose();
    _lateralSealController.dispose();
    _rearSealController.dispose();
    _customRouteController.dispose();
    _shakeController.dispose();
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

      final vehicles = options['vehicles'] != null
          ? (options['vehicles'] as List<dynamic>).whereType<models.Vehicle>().toList()
          : <models.Vehicle>[];
      final drivers = options['drivers'] != null
          ? (options['drivers'] as List<dynamic>).whereType<models.Driver>().toList()
          : <models.Driver>[];

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
          _vehicles = vehicles;
          _drivers = drivers;
          _routes = sortedRoutes;
          _vehiclesInRoute = vehiclesInRoute;
          _driversInRoute = driversInRoute;

          if (appState.selectedVehicle != null && !_vehicles.any((v) => v.id == appState.selectedVehicle!.id)) {
            appState.setVehicle(null);
          }
          if (appState.selectedDriver != null && !_drivers.any((d) => d.id == appState.selectedDriver!.id)) {
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
            backgroundColor: AppColors.error,
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
        setState(() => _history = history);
      }
    } catch (e, stackTrace) {
      print('Erro ao carregar histórico: $e\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().contains('Falha de conexão')
                ? 'Não foi possível conectar ao servidor.'
                : 'Erro ao carregar histórico: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _submitForm(BuildContext context) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    if (!_validateForm(appState)) {
      _shakeController.forward().then((_) => _shakeController.reset());
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos obrigatórios!'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ApiService.saveTrip(
      vehicleId: appState.selectedVehicle!.id,
      driverId: appState.selectedDriver!.id,
      kmDeparture: _kmDepartureController.text,
      lateralSeal: (appState.selectedVehicle?.name == 'Iveco' || appState.selectedVehicle?.name == 'Kia Bongo')
          ? _lateralSealController.text.trim().isEmpty ? null : _lateralSealController.text.trim()
          : null,
      rearSeal: (appState.selectedVehicle?.name == 'Iveco' || 
               appState.selectedVehicle?.name == 'Fiorino' || 
               appState.selectedVehicle?.name == 'Kia Bongo')
          ? _rearSealController.text.trim().isEmpty ? null : _rearSealController.text.trim()
          : null,
      routes: appState.selectedRoutes,
      routeMap: {for (var r in _routes) r.name: r.id},
    );
      await _loadHistory();
      await _loadPendingTrips();
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Registro salvo com sucesso!'), backgroundColor: AppColors.success),
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
          backgroundColor: AppColors.error,
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
        const SnackBar(content: Text('Rota excluída com sucesso!'), backgroundColor: AppColors.success),
      );
    } catch (e, stackTrace) {
      print('Erro ao excluir: $e\n$stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir: $e'), backgroundColor: AppColors.error),
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

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isTablet = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFFF7ED), Color(0xFFF8FAFC)],
                ),
              ),
            ),
            CustomScrollView(
              slivers: [
                SliverAppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  floating: true,
                  expandedHeight: 160,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.primary, AppColors.primaryDark],
                        ),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(32),
                          bottomRight: Radius.circular(32),
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => Navigator.pushReplacementNamed(context, '/menu'),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(50),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(FeatherIcons.arrowLeft, color: Colors.white, size: 28),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Controle de Portaria', style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                                    Text('Registro de saída de veículos', style: GoogleFonts.poppins(fontSize: 15, color: Colors.white70)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: Colors.white.withAlpha(50), borderRadius: BorderRadius.circular(16)),
                                child: Row(
                                  children: [
                                    IconButton(icon: const Icon(FontAwesomeIcons.circleMinus, color: Colors.white), onPressed: appState.decreaseFontSize),
                                    IconButton(icon: const Icon(FontAwesomeIcons.circlePlus, color: Colors.white), onPressed: appState.increaseFontSize),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: isTablet ? 100 : 16, vertical: 24),
                  sliver: SliverToBoxAdapter(
                    child: FadeInUp(
                      duration: const Duration(milliseconds: 700),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 40, offset: const Offset(0, 16)),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FadeInLeft(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withAlpha(30),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(FontAwesomeIcons.calendarDay, color: AppColors.primary, size: 22),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Hoje: ${DateFormat('EEEE, d MMMM yyyy', 'pt_BR').format(DateTime.now())}',
                                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16, color: AppColors.textPrimary),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 40),

                              // === FORMULÁRIO ===
                              ..._buildFormSections(appState),

                              const SizedBox(height: 40),

                              // Botão principal
                              FadeInUp(
                                delay: const Duration(milliseconds: 400),
                                child: AnimatedBuilder(
                                  animation: _shakeController,
                                  builder: (context, child) {
                                    return Transform.translate(
                                      offset: Offset(_shakeAnimation.value, 0),
                                      child: SizedBox(
                                        height: 64,
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          onPressed: _isLoading ? null : () => _submitForm(context),
                                          icon: _isLoading
                                              ? const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                                              : const Icon(FontAwesomeIcons.paperPlane, size: 26),
                                          label: Text(
                                            _isLoading ? "Registrando..." : "Registrar Saída",
                                            style: GoogleFonts.poppins(fontSize: 19, fontWeight: FontWeight.bold),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primary,
                                            foregroundColor: Colors.white,
                                            elevation: 12,
                                            shadowColor: AppColors.primary.withAlpha(100),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),

                              const SizedBox(height: 48),

                              // Histórico
                              _buildHistoryCard(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

    List<Widget> _buildFormSections(AppState appState) {
    return [
      _modernSection("Veículo", FontAwesomeIcons.truck, CustomDropdown<models.Vehicle>(
        items: _vehicles,
        selectedItem: appState.selectedVehicle,
        hint: 'Selecione o veículo',
        displayText: (v) => _vehiclesInRoute[v.id] == true ? '${v.name} (Em rota)' : v.name,
        onChanged: (v) { appState.setVehicle(v); setState(() {}); },
        isDisabled: (v) => _vehiclesInRoute[v.id] ?? false,
      )),

      _modernSection("Destino da Rota", FontAwesomeIcons.route, Column(
        children: [
          CustomDropdown<models.Route>(
            items: _routes,
            selectedItem: appState.selectedRoute,
            hint: 'Selecione ou digite uma rota',
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
            _modernTextField(
              controller: _customRouteController,
              hintText: "Ex: Cliente XYZ - Rua Tal",
              onSubmitted: (v) {
                if (v.trim().isNotEmpty) {
                  appState.addRoute(v.trim());
                  _customRouteController.clear();
                  setState(() {});
                }
              },
              suffixIcon: IconButton(
                icon: const Icon(FontAwesomeIcons.circlePlus, color: AppColors.primary),
                onPressed: () {
                  if (_customRouteController.text.trim().isNotEmpty) {
                    appState.addRoute(_customRouteController.text.trim());
                    _customRouteController.clear();
                    setState(() {});
                  }
                },
              ),
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: appState.selectedRoutes.asMap().entries.map((e) {
              return Chip(
                backgroundColor: AppColors.primary.withAlpha(30),
                label: Text(e.value, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                deleteIconColor: AppColors.primary,
                onDeleted: () { appState.removeRoute(e.value); setState(() {}); },
              );
            }).toList(),
          ),
        ],
      )),

      _modernSection("KM de Saída", FontAwesomeIcons.gaugeHigh, _modernTextField(
        controller: _kmDepartureController,
        hintText: "00000",
        keyboardType: TextInputType.number,
      )),

      // ==================== LACRES CORRIGIDOS ====================
      if (appState.selectedVehicle?.name == 'Iveco' || 
          appState.selectedVehicle?.name == 'Kia Bongo' || 
          appState.selectedVehicle?.name == 'Fiorino')
        Row(
          children: [
            // LACRE LATERAL → só Iveco e Kia Bongo
            if (appState.selectedVehicle?.name == 'Iveco' || appState.selectedVehicle?.name == 'Kia Bongo')
              Expanded(
                child: _modernSection(
                  "Lacre Lateral",
                  FontAwesomeIcons.lock,
                  _modernTextField(
                    controller: _lateralSealController,
                    hintText: "0000000",
                    keyboardType: TextInputType.number,
                    maxLength: 7,
                  ),
                ),
              ),

            // Espaço entre os dois campos
            if ((appState.selectedVehicle?.name == 'Iveco' || appState.selectedVehicle?.name == 'Kia Bongo') &&
                appState.selectedVehicle?.name != 'Fiorino')
              const SizedBox(width: 16),

            // LACRE TRASEIRO → Iveco, Kia Bongo e Fiorino
            if (appState.selectedVehicle?.name == 'Iveco' || 
                appState.selectedVehicle?.name == 'Kia Bongo' || 
                appState.selectedVehicle?.name == 'Fiorino')
              Expanded(
                child: _modernSection(
                  "Lacre Traseiro",
                  FontAwesomeIcons.lock,
                  _modernTextField(
                    controller: _rearSealController,
                    hintText: "0000000",
                    keyboardType: TextInputType.number,
                    maxLength: 7,
                  ),
                ),
              ),
          ],
        ),

      _modernSection("Motorista", FontAwesomeIcons.user, CustomDropdown<models.Driver>(
        items: _drivers,
        selectedItem: appState.selectedDriver,
        hint: 'Selecione o motorista',
        displayText: (d) => _driversInRoute[d.id] == true ? '${d.name} (Em rota)' : d.name,
        onChanged: (d) { appState.setDriver(d); setState(() {}); },
        isDisabled: (d) => _driversInRoute[d.id] ?? false,
      )),

      const SizedBox(height: 32),
      FadeInUp(
        child: SummaryCard(
          vehicle: appState.selectedVehicle?.name ?? 'Nenhum',
          routes: appState.selectedRoutes,
          driver: appState.selectedDriver?.name ?? 'Nenhum',
          kmDeparture: _kmDepartureController.text,
          lateralSeal: _lateralSealController.text,
          rearSeal: _rearSealController.text,
        ),
      ),
    ];
  }

  Widget _modernSection(String title, IconData icon, Widget child) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
                  borderRadius: BorderRadius.all(Radius.circular(18)),
                ),
                child: Icon(icon, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Text(title, style: GoogleFonts.poppins(fontSize: 19, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const Text(' *', style: TextStyle(color: Colors.red, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _modernTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    Function(String)? onSubmitted,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.poppins(color: AppColors.textSecondary.withAlpha(180)),
        filled: true,
        fillColor: Colors.grey[50],
        counterText: "",
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.primary, width: 2.5),
        ),
      ),
      style: GoogleFonts.poppins(fontSize: 17),
    );
  }

  Widget _buildHistoryCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 30, offset: const Offset(0, 12))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 28, 28, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Histórico do Dia", style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                Row(
                  children: [
                    InkWell(
                      onTap: () async {
                        final selected = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                          locale: const Locale('pt', 'BR'),
                        );
                        if (selected != null && mounted) {
                          setState(() => _selectedDate = selected);
                          _loadHistory();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(25),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(DateFormat('dd/MM/yyyy').format(_selectedDate), style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(FontAwesomeIcons.arrowsRotate, color: AppColors.primary, size: 26),
                      onPressed: () async {
                        setState(() => _isLoading = true);
                        await _loadHistory();
                        await _loadPendingTrips();
                        setState(() => _isLoading = false);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            tabs: const [
              Tab(text: "Pendentes"),
              Tab(text: "Concluídos"),
            ],
          ),
          SizedBox(
            height: 500,
            child: TabBarView(
              controller: _tabController,
              children: [
                _pendingTrips.isEmpty
                    ? const Center(child: Text("Nenhuma rota pendente", style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        itemCount: _pendingTrips.length,
                        itemBuilder: (context, i) => HistoryItem(
                          trip: _pendingTrips[i],
                          onEdit: () => showDialog(context: context, builder: (_) => EditTripDialog(trip: _pendingTrips[i], onSave: () async {
                            await _loadHistory();
                            await _loadPendingTrips();
                            setState(() {});
                          })),
                          onDelete: () => _deleteTrip(_pendingTrips[i].id),
                        ),
                      ),
                _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : _history.isEmpty
                        ? const Center(child: Text("Nenhum registro hoje", style: TextStyle(color: Colors.grey)))
                        : ListView.builder(
                            itemCount: _history.length,
                            itemBuilder: (context, i) => HistoryItem(
                              trip: _history[i],
                              onEdit: () => showDialog(context: context, builder: (_) => EditTripDialog(trip: _history[i], onSave: () async {
                                await _loadHistory();
                                await _loadPendingTrips();
                                setState(() {});
                              })),
                              onDelete: () => _deleteTrip(_history[i].id),
                            ),
                          ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ================================
// DIALOG DE EDIÇÃO (CORRIGIDO)
// ================================
class EditTripDialog extends StatefulWidget {
  final models.Trip trip;
  final VoidCallback onSave;
  const EditTripDialog({super.key, required this.trip, required this.onSave});

  @override
  State<EditTripDialog> createState() => _EditTripDialogState();
}

class _EditTripDialogState extends State<EditTripDialog> with SingleTickerProviderStateMixin {
  final _kmReturnController = TextEditingController();
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _kmReturnController.text = widget.trip.kmReturn ?? '';
    _shakeController = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    _shakeAnimation = Tween<double>(begin: -6, end: 6).chain(CurveTween(curve: Curves.elasticIn)).animate(_shakeController);
  }

  @override
  void dispose() {
    _kmReturnController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_kmReturnController.text.isEmpty) {
      setState(() => _errorMessage = 'Preencha o KM de Retorno!');
      _shakeController.forward().then((_) => _shakeController.reset());
      return;
    }

    try {
      await ApiService.updateTrip(widget.trip.id, _kmReturnController.text);
      widget.onSave();
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rota concluída com sucesso!'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      setState(() => _errorMessage = 'Erro ao concluir: $e');
      _shakeController.forward().then((_) => _shakeController.reset());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: AppColors.surface,
      contentPadding: const EdgeInsets.all(28),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(FontAwesomeIcons.circleCheck, color: AppColors.primary, size: 28),
                    const SizedBox(width: 12),
                    Text('Concluir Rota', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold)),
                  ],
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 24),
            ...[
              ['Veículo', widget.trip.vehicle],
              ['Motorista', widget.trip.driver],
              if (widget.trip.route.isNotEmpty) ['Rotas', widget.trip.route.join(', ')],
              if (widget.trip.lateralSeal != null && widget.trip.lateralSeal!.isNotEmpty) ['Lacre Lateral', widget.trip.lateralSeal!],
              if (widget.trip.rearSeal != null && widget.trip.rearSeal!.isNotEmpty) ['Lacre Traseiro', widget.trip.rearSeal!],
            ].map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(FontAwesomeIcons.circleInfo, color: AppColors.textSecondary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e[0], style: GoogleFonts.poppins(color: AppColors.textSecondary)),
                      const SizedBox(height: 4),
                      Text(e[1], style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
                    ],
                  )),
                ],
              ),
            )),

            const SizedBox(height: 24),
            Text('KM de Retorno *', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _kmReturnController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: "00000",
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2.5),
                ),
              ),
              style: GoogleFonts.poppins(fontSize: 18),
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_errorMessage!, style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
              ),
            const SizedBox(height: 28),
            AnimatedBuilder(
              animation: _shakeController,
              builder: (context, child) => Transform.translate(
                offset: Offset(_shakeAnimation.value, 0),
                child: SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton.icon(
                    onPressed: _submit,
                    icon: const Icon(FontAwesomeIcons.circleCheck),
                    label: Text("Concluir Rota", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 8,
                    ),
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