// entrada_form.dart
import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services_api.dart';

class AppPreferences {
  static const String _keyConferenteId = 'conferente_id';

  static Future<void> saveConferenteId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyConferenteId, id);
  }

  static Future<String?> getConferenteId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyConferenteId);
  }
}

class EntradaForm extends StatefulWidget {
  const EntradaForm({super.key});

  @override
  _EntradaFormState createState() => _EntradaFormState();
}

class _EntradaFormState extends State<EntradaForm>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> conferentes = [];
  String? selectedConferente;
  final TextEditingController placaController = TextEditingController();
  final TextEditingController modeloController = TextEditingController();
  final TextEditingController motoristaController = TextEditingController();
  final TextEditingController idController = TextEditingController();
  bool showSuccess = false;
  bool isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _fetchConferentesAndLoadSaved();
    _animationController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchConferentesAndLoadSaved();
  }

  Future<void> _fetchConferentesAndLoadSaved() async {
    try {
      final data = await ApiService.fetchConferentes();
      final List<Map<String, String>> loadedConferentes = data.map((c) {
        return {
          'id': c['id'].toString(),
          'nome': c['nome'].toString().trim(),
        };
      }).toList();

      setState(() {
        conferentes = loadedConferentes.cast<Map<String, dynamic>>();
      });

      final savedId = await AppPreferences.getConferenteId();

      if (savedId != null && loadedConferentes.isNotEmpty) {
        final savedConferente = loadedConferentes.firstWhere(
          (c) => c['id'] == savedId,
          orElse: () => loadedConferentes[0],
        );

        setState(() {
          selectedConferente = savedConferente['nome'];
        });
        return;
      }

      if (loadedConferentes.isNotEmpty) {
        setState(() {
          selectedConferente = loadedConferentes[0]['nome'];
        });
      }
    } catch (e) {
      _showErrorSnackBar('Erro ao carregar conferentes: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(FeatherIcons.alertCircle, color: Colors.white, size: 28),  
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 16, color: Colors.white), 
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
      ),
    );
  }

  Future<void> _registerEntrada() async {
    if (selectedConferente == null ||
        placaController.text.isEmpty ||
        modeloController.text.isEmpty ||
        motoristaController.text.isEmpty ||
        idController.text.isEmpty) {
      _showErrorSnackBar('Preencha todos os campos obrigatórios');
      return;
    }

    setState(() => isLoading = true);

    try {
      final conferente = conferentes.cast<Map<String, String>>().firstWhere(
        (c) => c['nome'] == selectedConferente,
        orElse: () => {'id': '', 'nome': ''},
      );

      if (conferente['id'] == null || conferente['id']!.isEmpty) {
        _showErrorSnackBar('Conferente inválido. Recarregue a lista.');
        setState(() => isLoading = false);
        return;
      }

      final success = await ApiService.registerEntrada(
        conferenteId: conferente['id']!,
        placa: placaController.text.trim().toUpperCase(),
        modelo: modeloController.text.trim(),
        motorista: motoristaController.text.trim(),
        idMotorista: idController.text.trim(),
      );

      if (!success) throw Exception('Falha no servidor');

      setState(() {
        showSuccess = true;
        isLoading = false;
        placaController.clear();
        modeloController.clear();
        motoristaController.clear();
        idController.clear();
      });

      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => showSuccess = false);
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showErrorSnackBar('Erro ao registrar: $e');
    }
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(FeatherIcons.info, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Preencha todos os campos para registrar a entrada do veículo',
              style: TextStyle(
                fontSize: 16, 
                color: Color(0xFF1E40AF),
                fontWeight: FontWeight.bold,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: selectedConferente,
        decoration: InputDecoration(
          labelText: 'Conferente (Porteiro)',
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF374151),
            fontSize: 16, 
          ),
          prefixIcon: const Icon(FeatherIcons.user, color: Color(0xFFFF6A00), size: 28),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFFF6A00), width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        ),
        items: conferentes.map((conferente) {
          return DropdownMenuItem<String>(
            value: conferente['nome'] as String,
            child: Text(
              conferente['nome'] as String,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), 
            ),
          );
        }).toList(),
        onChanged: (value) async {
          if (value == null) return;

          setState(() {
            selectedConferente = value;
          });

          final conferente = conferentes.cast<Map<String, String>>().firstWhere(
            (c) => c['nome'] == value,
            orElse: () => conferentes[0] as Map<String, String>,
          );

          await AppPreferences.saveConferenteId(conferente['id']!);
        },
        dropdownColor: Colors.white,
        style: const TextStyle(fontSize: 16, color: Colors.black), 
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int? maxLength,
    bool centerText = false,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        textCapitalization: textCapitalization,
        textAlign: centerText ? TextAlign.center : TextAlign.start,
        maxLength: maxLength,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0B0B0B),
          letterSpacing: 1.0,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF374151),
            fontSize: 16,
          ),
          prefixIcon: Icon(icon, color: const Color(0xFFFF6A00), size: 28),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFFF6A00), width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          counterText: '',
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      height: 58, 
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF6A00), Color(0xFFFF8B3D)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6A00).withOpacity(0.5),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : _registerEntrada,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(FeatherIcons.checkCircle, color: Colors.white, size: 28),
                  SizedBox(width: 12),
                  Text(
                    'REGISTRAR ENTRADA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18, 
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSuccessCard() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            margin: const EdgeInsets.only(top: 24),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF0FDF4), Color(0xFFDCFCE7)],
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF16A34A).withOpacity(0.3),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    FeatherIcons.checkCircle,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SUCESSO!',
                        style: TextStyle(
                          fontSize: 20, 
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF16A34A),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Entrada registrada com sucesso',
                        style: TextStyle(
                          fontSize: 16, 
                          color: Color(0xFF15803D),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0), 
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInfoCard(),
            _buildCustomDropdown(),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: placaController,
                    label: 'PLACA',
                    icon: FeatherIcons.truck,
                    maxLength: 8,
                    centerText: true,
                    textCapitalization: TextCapitalization.characters,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: modeloController,
                    label: 'MODELO',
                    icon: FeatherIcons.tag,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: motoristaController,
              label: 'MOTORISTA',
              icon: FeatherIcons.user,
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: idController,
              label: 'IDENTIDADE (ID)',
              icon: FeatherIcons.creditCard,
            ),
            const SizedBox(height: 28),
            _buildSubmitButton(),
            if (showSuccess) _buildSuccessCard(),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    placaController.dispose();
    modeloController.dispose();
    motoristaController.dispose();
    idController.dispose();
    super.dispose();
  }
}