import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services_api.dart';

// ==================== PREFERENCES ====================
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
// =====================================================================

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
    final List<Map<String, dynamic>> loadedConferentes = data.map((c) {
      return {
        'id': c['id'].toString(),
        'nome': c['nome'].toString().trim(),
      };
    }).toList();

    setState(() {
      conferentes = loadedConferentes;
    });

    final savedId = await AppPreferences.getConferenteId();
    if (savedId != null && conferentes.isNotEmpty) {
      final saved = conferentes.cast<Map<String, dynamic>>().firstWhere(
        (c) => c['id'] == savedId,
        orElse: () => conferentes[0], // Retorna o primeiro
      );
      setState(() {
        selectedConferente = saved['nome'];
      });
      return;
    }

    if (conferentes.isNotEmpty) {
      setState(() {
        selectedConferente = conferentes[0]['nome'];
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
            const Icon(FeatherIcons.alertCircle, color: Colors.white, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
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
    final conferente = conferentes.cast<Map<String, dynamic>>().firstWhere(
      (c) => c['nome'] == selectedConferente,
      orElse: () => {'id': '', 'nome': ''}, // Map válido
    );

    if (conferente['id'] == null || conferente['id'].toString().isEmpty) {
      _showErrorSnackBar('Conferente inválido. Recarregue a lista.');
      setState(() => isLoading = false);
      return;
    }

    final success = await ApiService.registerEntrada(
      conferenteId: conferente['id'].toString(),
      placa: placaController.text,
      modelo: modeloController.text,
      motorista: motoristaController.text,
      idMotorista: idController.text,
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
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(FeatherIcons.info, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 20),
          const Expanded(
            child: Text(
              'Preencha todos os campos para registrar a entrada do veículo',
              style: TextStyle(
                fontSize: 18,
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
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
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
            fontSize: 18,
          ),
          prefixIcon: const Icon(FeatherIcons.user, color: Color(0xFFFF6A00), size: 32),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 3),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Color(0xFFFF6A00), width: 3),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        ),
        items: conferentes.map((conferente) {
          return DropdownMenuItem<String>(
            value: conferente['nome'],
            child: Text(
              conferente['nome'],
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          );
        }).toList(),
        onChanged: (value) async {
          if (value == null) return;
          setState(() => selectedConferente = value);

          final conferente = conferentes.firstWhere((c) => c['nome'] == value);
          await AppPreferences.saveConferenteId(conferente['id']);
        },
        dropdownColor: Colors.white,
        style: const TextStyle(fontSize: 18, color: Colors.black),
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
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        textCapitalization: textCapitalization,
        textAlign: centerText ? TextAlign.center : TextAlign.start,
        maxLength: maxLength,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0B0B0B),
          letterSpacing: 1.2,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF374151),
            fontSize: 18,
          ),
          prefixIcon: Icon(icon, color: const Color(0xFFFF6A00), size: 32),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 3),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Color(0xFFFF6A00), width: 3),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          counterText: '',
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF6A00), Color(0xFFFF8B3D)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6A00).withOpacity(0.5),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : _registerEntrada,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(FeatherIcons.checkCircle, color: Colors.white, size: 32),
                  SizedBox(width: 16),
                  Text(
                    'REGISTRAR ENTRADA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
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
            margin: const EdgeInsets.only(top: 28),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF0FDF4), Color(0xFFDCFCE7)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF16A34A).withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    FeatherIcons.checkCircle,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'SUCESSO!',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF16A34A),
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Entrada registrada com sucesso',
                        style: TextStyle(
                          fontSize: 18,
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
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInfoCard(),
            _buildCustomDropdown(),
            const SizedBox(height: 24),
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
                const SizedBox(width: 20),
                Expanded(
                  child: _buildTextField(
                    controller: modeloController,
                    label: 'MODELO',
                    icon: FeatherIcons.tag,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildTextField(
              controller: motoristaController,
              label: 'MOTORISTA',
              icon: FeatherIcons.user,
            ),
            const SizedBox(height: 24),
            _buildTextField(
              controller: idController,
              label: 'IDENTIDADE (ID)',
              icon: FeatherIcons.creditCard,
            ),
            const SizedBox(height: 32),
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

// ====================== SAIDA FORM (VARIANTE IDOSO) ======================
class SaidaForm extends StatefulWidget {
  const SaidaForm({super.key});

  @override
  _SaidaFormState createState() => _SaidaFormState();
}

class _SaidaFormState extends State<SaidaForm>
    with SingleTickerProviderStateMixin {
  final TextEditingController placaController = TextEditingController();
  bool showSuccess = false;
  bool showVehicleInfo = false;
  bool isSearching = false;
  bool isRegistering = false;
  Map<String, dynamic>? vehicleInfo;
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
    _animationController.forward();
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(FeatherIcons.alertCircle, color: Colors.white, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      ),
    );
  }

  Future<void> _searchVehicle() async {
    final placa = placaController.text.trim().toUpperCase();
    if (placa.isEmpty) {
      _showErrorSnackBar('Digite a placa do veículo');
      return;
    }

    setState(() => isSearching = true);

    try {
      final data = await ApiService.searchVehicle(placa);
      setState(() {
        vehicleInfo = data;
        showVehicleInfo = data != null;
        isSearching = false;
      });
      if (data == null) {
        _showErrorSnackBar('Veículo não encontrado ou já saiu');
      }
    } catch (e) {
      setState(() {
        showVehicleInfo = false;
        isSearching = false;
      });
      _showErrorSnackBar('Erro ao buscar veículo: $e');
    }
  }

  Future<void> _registerSaida() async {
    final placa = placaController.text.trim().toUpperCase();
    if (placa.isEmpty) {
      _showErrorSnackBar('Digite a placa do veículo');
      return;
    }

    setState(() => isRegistering = true);

    try {
      final success = await ApiService.registerSaida(placa);
      if (!success) throw Exception('Falha ao registrar saída');

      setState(() {
        showSuccess = true;
        showVehicleInfo = false;
        isRegistering = false;
        placaController.clear();
      });
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => showSuccess = false);
      });
    } catch (e) {
      setState(() => isRegistering = false);
      _showErrorSnackBar('Erro ao registrar saída: $e');
    }
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6A00).withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6A00),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(FeatherIcons.logOut, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 20),
          const Expanded(
            child: Text(
              'Digite a placa do veículo que está saindo',
              style: TextStyle(
                fontSize: 18,
                color: Color(0xFF7C2D12),
                fontWeight: FontWeight.bold,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TextFormField(
        controller: placaController,
        textCapitalization: TextCapitalization.characters,
        textAlign: TextAlign.center,
        maxLength: 8,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0B0B0B),
          letterSpacing: 3,
        ),
        decoration: InputDecoration(
          labelText: 'PLACA DO VEÍCULO',
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF374151),
            fontSize: 18,
          ),
          prefixIcon: const Icon(FeatherIcons.search, color: Color(0xFFFF6A00), size: 32),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 3),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Color(0xFFFF6A00), width: 3),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          counterText: '',
        ),
      ),
    );
  }

  Widget _buildSearchButton() {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.5),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isSearching ? null : _searchVehicle,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: isSearching
            ? const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(FeatherIcons.search, color: Colors.white, size: 32),
                  SizedBox(width: 16),
                  Text(
                    'BUSCAR VEÍCULO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildVehicleInfoCard() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFBBF24), width: 3),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFBBF24).withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBBF24),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        FeatherIcons.info,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'INFORMAÇÕES DO VEÍCULO',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0B0B0B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildInfoRow(FeatherIcons.user, 'MOTORISTA', vehicleInfo!['motorista']),
                const SizedBox(height: 16),
                _buildInfoRow(FeatherIcons.tag, 'MODELO', vehicleInfo!['modelo']),
                const SizedBox(height: 16),
                _buildInfoRow(
                  FeatherIcons.clock,
                  'ENTRADA',
                  vehicleInfo!['horario_chegada'],
                  isHighlight: true,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {bool isHighlight = false}) {
    return Row(
      children: [
        Icon(icon, size: 28, color: isHighlight ? const Color(0xFF16A34A) : const Color(0xFF78716C)),
        const SizedBox(width: 14),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isHighlight ? const Color(0xFF16A34A) : const Color(0xFF78716C),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.bold,
              color: isHighlight ? const Color(0xFF16A34A) : const Color(0xFF0B0B0B),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterButton() {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF16A34A), Color(0xFF15803D)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF16A34A).withOpacity(0.5),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isRegistering ? null : _registerSaida,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: isRegistering
            ? const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(FeatherIcons.checkCircle, color: Colors.white, size: 32),
                  SizedBox(width: 16),
                  Text(
                    'REGISTRAR SAÍDA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
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
            margin: const EdgeInsets.only(top: 28),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF0FDF4), Color(0xFFDCFCE7)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF16A34A).withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    FeatherIcons.checkCircle,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'SUCESSO!',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF16A34A),
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Saída registrada com sucesso',
                        style: TextStyle(
                          fontSize: 18,
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
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInfoCard(),
            _buildSearchField(),
            const SizedBox(height: 24),
            _buildSearchButton(),
            if (showVehicleInfo && vehicleInfo != null) _buildVehicleInfoCard(),
            if (showVehicleInfo) const SizedBox(height: 24),
            if (showVehicleInfo && vehicleInfo != null) _buildRegisterButton(),
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
    super.dispose();
  }
}