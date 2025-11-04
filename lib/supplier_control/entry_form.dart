// lib/supplier_control/entry_form.dart
import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api.dart';

class EntryForm extends StatefulWidget {
  const EntryForm({super.key});

  @override
  State<EntryForm> createState() => _EntryFormState();
}

class _EntryFormState extends State<EntryForm>
    with SingleTickerProviderStateMixin {
  /* ---------- Controllers ---------- */
  final _placaController = TextEditingController();
  final _motoristaController = TextEditingController();
  final _idMotoristaController = TextEditingController();
  final _empresaController = TextEditingController();

  /* ---------- Dados do conferente ---------- */
  List<Map<String, dynamic>> _conferentes = [];
  Map<String, dynamic>? _selectedConferente;
  String? _cachedConferenteId;

  bool _isLoadingConferentes = true;
  bool _hasInternetError = false;

  /* ---------- UI ---------- */
  bool isLoading = false;
  bool showSuccess = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);
    _animationController.forward();

    _loadConferenteAndList();
  }

  Future<void> _loadConferenteAndList() async {
    await _loadCachedConferenteId();
    await _loadConferentesFromApi();
  }

  Future<void> _loadCachedConferenteId() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedId = prefs.getString('conferente_id');
    if (cachedId != null) {
      _cachedConferenteId = cachedId;
    }
  }

  Future<void> _saveConferenteToCache(String id, String nome) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('conferente_id', id);
    await prefs.setString('conferente_nome', nome);
  }

  Future<void> _loadConferentesFromApi() async {
  try {
    final data = await Api.fetchConferentes();

    setState(() {
      // ✅ REMOVE DUPLICATAS baseado no ID
      final Map<String, Map<String, dynamic>> uniqueMap = {};
      for (var conferente in data) {
        final id = conferente['id'].toString();
        uniqueMap[id] = conferente;
      }
      _conferentes = uniqueMap.values.toList();
      
      _hasInternetError = false;

      // Seleciona com referência exata
      if (_cachedConferenteId != null && _conferentes.isNotEmpty) {
        try {
          _selectedConferente = _conferentes.firstWhere(
            (c) => c['id'].toString() == _cachedConferenteId,
          );
        } catch (_) {
          _selectedConferente = null;
        }
      }

      if (_selectedConferente == null && _conferentes.isNotEmpty) {
        _selectedConferente = _conferentes[0];
      }

      if (_selectedConferente != null) {
        _saveConferenteToCache(
          _selectedConferente!['id'].toString(),
          _selectedConferente!['nome'],
        );
      }

      _isLoadingConferentes = false;
    });
  } catch (e) {
    setState(() {
      _hasInternetError = true;
      _isLoadingConferentes = false;

      if (_cachedConferenteId != null) {
        _showErrorSnackBar('Sem internet. Usando último conferente salvo.');
      }
    });
  }
}

  Future<void> _registerEntry() async {
    final placa = _placaController.text.trim().toUpperCase();
    final motorista = _motoristaController.text.trim();
    final idMotorista = _idMotoristaController.text.trim();
    final empresa = _empresaController.text.trim();

    if (placa.isEmpty || motorista.isEmpty || idMotorista.isEmpty || empresa.isEmpty) {
      _showErrorSnackBar('Preencha todos os campos');
      return;
    }

    if (_selectedConferente == null) {
      _showErrorSnackBar('Selecione um conferente');
      return;
    }

    setState(() => isLoading = true);

    try {
      final success = await Api.registerSupplierEntry(
        placa: placa,
        motorista: motorista,
        idMotorista: idMotorista,
        empresa: empresa,
        conferenteId: _selectedConferente!['id'].toString(),
      );

      if (!success) throw Exception('Falha ao registrar entrada');

      setState(() {
        showSuccess = true;
        isLoading = false;
      });

      _placaController.clear();
      _motoristaController.clear();
      _idMotoristaController.clear();
      _empresaController.clear();

      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => showSuccess = false);
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showErrorSnackBar('Erro ao registrar entrada: $e');
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required TextInputType keyboardType,
    int? maxLength,
    bool uppercase = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLength: maxLength,
        textCapitalization: uppercase ? TextCapitalization.characters : TextCapitalization.words,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
            fontSize: 18,
          ),
          prefixIcon: Icon(icon, color: const Color(0xFFFF6A00), size: 32),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Color(0xFFD1D5DB), width: 3),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Color(0xFFD1D5DB), width: 3),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Color(0xFFFF6A00), width: 4),
          ),
          counterText: '',
        ),
      ),
    );
  }

  // GARANTE QUE O DROPDOWN SÓ É CONSTRUÍDO QUANDO TUDO ESTIVER PRONTO
  Widget _buildConferenteWidget() {
    // Carregando
    if (_isLoadingConferentes) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFD1D5DB), width: 3),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(strokeWidth: 3, color: Color(0xFFFF6A00)),
            ),
            SizedBox(width: 16),
            Text('Carregando conferente...', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    // Sem internet, mas tem cache
    if (_hasInternetError && _selectedConferente != null) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFD1D5DB), width: 3),
        ),
        child: Row(
          children: [
            const Icon(FeatherIcons.userCheck, color: Color(0xFFFF6A00), size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('CONFERENTE', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF6B7280))),
                  Text(_selectedConferente!['nome'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                ],
              ),
            ),
            const Icon(FeatherIcons.wifiOff, color: Colors.red, size: 20),
          ],
        ),
      );
    }

    // Apenas 1 conferente → mostra fixo
    if (_conferentes.length <= 1) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFD1D5DB), width: 3),
        ),
        child: Row(
          children: [
            const Icon(FeatherIcons.userCheck, color: Color(0xFFFF6A00), size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('CONFERENTE', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF6B7280))),
                  Text(_selectedConferente?['nome'] ?? 'Nenhum', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Dropdown completo — SÓ AQUI GARANTE QUE _selectedConferente É DA LISTA
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD1D5DB), width: 3),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Map<String, dynamic>>(
          value: _selectedConferente,
          isExpanded: true,
          hint: const Text('Selecione o conferente', style: TextStyle(fontSize: 18)),
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFFFF6A00), size: 32),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
          items: _conferentes.map((c) {
            return DropdownMenuItem<Map<String, dynamic>>(
              value: c,
              child: Text(c['nome']),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedConferente = value;
              });
              _saveConferenteToCache(value['id'].toString(), value['nome']);
            }
          },
        ),
      ),
    );
  }

  Widget _buildRegisterButton() {
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
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : _registerEntry,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: isLoading
            ? const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(FeatherIcons.logIn, color: Colors.white, size: 32),
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
                  child: const Icon(FeatherIcons.checkCircle, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('SUCESSO!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                      SizedBox(height: 4),
                      Text('Entrada registrada com sucesso', style: TextStyle(fontSize: 16, color: Color(0xFF15803D), fontWeight: FontWeight.bold)),
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
            // Card de instrução
            Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6A00).withOpacity(0.15),
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
                      color: const Color(0xFFFF6A00),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(FeatherIcons.logIn, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Registre a entrada do fornecedor',
                      style: TextStyle(fontSize: 16, color: Color(0xFF7C2D12), fontWeight: FontWeight.bold, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),

            // CONFERENTE — SÓ MOSTRA QUANDO TUDO ESTIVER PRONTO
            _buildConferenteWidget(),

            // Campos de entrada
            _buildTextField(
              controller: _placaController,
              label: 'PLACA DO VEÍCULO',
              icon: FeatherIcons.truck,
              keyboardType: TextInputType.text,
              maxLength: 8,
              uppercase: true,
            ),
            _buildTextField(
              controller: _motoristaController,
              label: 'NOME DO MOTORISTA',
              icon: FeatherIcons.user,
              keyboardType: TextInputType.name,
            ),
            _buildTextField(
              controller: _idMotoristaController,
              label: 'ID DO MOTORISTA',
              icon: FeatherIcons.creditCard,
              keyboardType: TextInputType.text,
              maxLength: 20,
            ),
            _buildTextField(
              controller: _empresaController,
              label: 'NOME DA EMPRESA',
              icon: FeatherIcons.package,
              keyboardType: TextInputType.text,
            ),

            const SizedBox(height: 20),
            _buildRegisterButton(),
            if (showSuccess) _buildSuccessCard(),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _placaController.dispose();
    _motoristaController.dispose();
    _idMotoristaController.dispose();
    _empresaController.dispose();
    super.dispose();
  }
}