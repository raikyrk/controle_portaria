import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'menu.dart';
import 'portaria_app/portaria_homescreen.dart';
import 'mototrack_app/new_record_screen.dart';
import 'controle_veiculos/veiculos_home_screen.dart';
import 'supplier_control/screenfor_home.dart';
import 'portaria_app/models.dart' as models;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);
  await dotenv.load(fileName: ".env");
  runApp(const ControlePortariaApp());
}

class ControlePortariaApp extends StatelessWidget {
  const ControlePortariaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppState(),
      child: MaterialApp(
        title: 'Gate Management',
        theme: ThemeData(
          primaryColor: const Color(0xFFF97316),
          colorScheme: ColorScheme.fromSwatch().copyWith(
            primary: const Color(0xFFF97316),
            secondary: const Color(0xFFFF8B3D),
          ),
          scaffoldBackgroundColor: const Color(0xFFF9FAFB),
          fontFamily: 'Poppins',
          textTheme: const TextTheme(
            headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0B0B0B)),
            bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFF97316), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF97316),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 6,
            ),
          ),
        ),
        home: const MenuScreen(),
        locale: const Locale('pt', 'BR'),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('pt', 'BR')],
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(Provider.of<AppState>(context).textScaleFactor),
            ),
            child: child!,
          );
        },
        routes: {
          '/menu': (context) => const MenuScreen(),
          '/portaria': (context) => const PortariaHomeScreen(),
          '/mototrack': (context) => const NewRecordScreen(),
          '/controle_veiculos': (context) => const VeiculosHomeScreen(),
          '/controle_fornecedores': (context) => const ScreenforHome(),
        },
      ),
    );
  }
}

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