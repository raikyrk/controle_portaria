import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'new_record_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  const String fallbackUrl = 'https://aogosto.store/mototrack/api/';
  String baseUrl = fallbackUrl;
  bool envLoaded = false;

  try {

    await dotenv.load(fileName: ".env");
    envLoaded = true;
    

    final url = dotenv.env['BASE_URL'];
    if (url != null && url.isNotEmpty) {
      baseUrl = url;
      print('BASE_URL carregada do .env: $baseUrl');
    } else {
      print('BASE_URL não encontrada no .env. Usando fallback: $fallbackUrl');
    }
  } catch (e) {
    print('Erro ao carregar o arquivo .env: $e');
    print('Usando URL fallback: $fallbackUrl');
  }


  if (!envLoaded) {
    dotenv.testLoad(fileInput: 'BASE_URL=$baseUrl');
  }

  runApp(const MotoTrackApp());
}

class MotoTrackApp extends StatelessWidget {
  const MotoTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MotoTrack',
      theme: ThemeData(
        primaryColor: const Color(0xFFFF6A00),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: const Color(0xFFFF6A00),
          secondary: const Color(0xFFFF8B3D),
        ),
        scaffoldBackgroundColor: const Color(0xFFF9FAFB),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0B0B0B),
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: Color(0xFF6B7280),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFFF6A00), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF6A00),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 6,
          ),
        ),
      ),
      home: const NewRecordScreen(),
    );
  }
}