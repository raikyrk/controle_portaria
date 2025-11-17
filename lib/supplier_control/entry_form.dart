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

  final _placaController = TextEditingController();
  final _motoristaController = TextEditingController();
  final _idMotoristaController = TextEditingController();
  final _empresaController = TextEditingController();


  final _placaFocus = FocusNode();
  final _motoristaFocus = FocusNode();
  final _idMotoristaFocus = FocusNode();
  final _empresaFocus = FocusNode();


  List<Map<String, dynamic>> _conferentes = [];
  Map<String, dynamic>? _selectedConferente;
  String? _cachedConferenteId;

  bool _isLoadingConferentes = true;
  bool _hasInternetError = false;


  bool isLoading = false;
  bool showSuccess = false;

  late AnimationController _animationController;
  Animation<double>? _fadeAnimation;
  Animation<Offset>? _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
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
        final Map<String, Map<String, dynamic>> uniqueMap = {};
        for (var conferente in data) {
          final id = conferente['id'].toString();
          uniqueMap[id] = conferente;
        }
        _conferentes = uniqueMap.values.toList();
        
        _hasInternetError = false;

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
          _showSnackBar(
            'Modo offline - usando último conferente',
            type: SnackBarType.warning,
          );
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
      _showSnackBar('Preencha todos os campos obrigatórios', type: SnackBarType.error);
      return;
    }

    if (_selectedConferente == null) {
      _showSnackBar('Selecione um conferente', type: SnackBarType.error);
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

      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) setState(() => showSuccess = false);
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showSnackBar('Erro ao registrar entrada', type: SnackBarType.error);
    }
  }

  void _showSnackBar(String message, {SnackBarType type = SnackBarType.error}) {
    final config = _getSnackBarConfig(type);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(config.icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: config.color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  _SnackBarConfig _getSnackBarConfig(SnackBarType type) {
    switch (type) {
      case SnackBarType.success:
        return _SnackBarConfig(
          color: const Color(0xFF059669),
          icon: FeatherIcons.checkCircle,
        );
      case SnackBarType.warning:
        return _SnackBarConfig(
          color: const Color(0xFFF59E0B),
          icon: FeatherIcons.alertTriangle,
        );
      case SnackBarType.error:
        return _SnackBarConfig(
          color: const Color(0xFFDC2626),
          icon: FeatherIcons.alertCircle,
        );
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required TextInputType keyboardType,
    required FocusNode focusNode,
    int? maxLength,
    bool uppercase = false,
  }) {
    return AnimatedBuilder(
      animation: focusNode,
      builder: (context, child) {
        final isFocused = focusNode.hasFocus;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: isFocused
                ? [
                    BoxShadow(
                      color: const Color(0xFFFF6A00).withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [],
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: keyboardType,
            maxLength: maxLength,
            textCapitalization: uppercase ? TextCapitalization.characters : TextCapitalization.words,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(
                fontWeight: FontWeight.w600,
                color: isFocused ? const Color(0xFFFF6A00) : const Color(0xFF6B7280),
                fontSize: 14,
              ),
              prefixIcon: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isFocused 
                      ? const Color(0xFFFF6A00).withOpacity(0.1)
                      : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isFocused ? const Color(0xFFFF6A00) : const Color(0xFF6B7280),
                  size: 24,
                ),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFFF6A00), width: 2.5),
              ),
              counterText: '',
            ),
          ),
        );
      },
    );
  }

  Widget _buildConferenteWidget() {
    if (_isLoadingConferentes) {
      return Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Color(0xFFFF6A00),
                ),
              ),
            ),
            const SizedBox(width: 14),
            const Text(
              'Carregando conferentes...',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      );
    }

    if (_hasInternetError && _selectedConferente != null) {
      return Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFEF3C7), width: 2),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFFFFBEB),
              const Color(0xFFFEF3C7).withOpacity(0.3),
            ],
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(FeatherIcons.wifiOff, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'MODO OFFLINE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFD97706),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedConferente!['nome'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF92400E),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (_conferentes.length <= 1) {
      return Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6A00).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(FeatherIcons.userCheck, color: Color(0xFFFF6A00), size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CONFERENTE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6B7280),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedConferente?['nome'] ?? 'Nenhum',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6A00).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(FeatherIcons.users, color: Color(0xFFFF6A00), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Map<String, dynamic>>(
                value: _selectedConferente,
                isExpanded: true,
                hint: const Text(
                  'Selecione o conferente',
                  style: TextStyle(fontSize: 15, color: Color(0xFF9CA3AF)),
                ),
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Color(0xFFFF6A00),
                  size: 28,
                ),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(12),
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
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterButton() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF6A00), Color(0xFFFF8B3D)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6A00).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : _registerEntry,
          borderRadius: BorderRadius.circular(16),
          child: Center(
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
                      Icon(FeatherIcons.checkCircle, color: Colors.white, size: 24),
                      SizedBox(width: 12),
                      Text(
                        'REGISTRAR ENTRADA',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessCard() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            margin: const EdgeInsets.only(top: 20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFECFDF5), Color(0xFFD1FAE5)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF6EE7B7), width: 2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF059669).withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF059669), Color(0xFF047857)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF059669).withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(FeatherIcons.checkCircle, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ENTRADA REGISTRADA',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF047857),
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Dados salvos com sucesso',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF065F46),
                          fontWeight: FontWeight.w600,
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

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.only(bottom: 28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF6A00), Color(0xFFFF8B3D)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6A00).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(FeatherIcons.truck, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CONTROLE DE ENTRADA',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Registre a entrada de fornecedores',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
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
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFFAFAFA),
            const Color(0xFFF3F4F6).withOpacity(0.5),
          ],
        ),
      ),
      child: _fadeAnimation != null && _slideAnimation != null
          ? FadeTransition(
              opacity: _fadeAnimation!,
              child: SlideTransition(
                position: _slideAnimation!,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeaderCard(),
                      _buildConferenteWidget(),
                      _buildTextField(
                        controller: _placaController,
                        label: 'PLACA DO VEÍCULO',
                        icon: FeatherIcons.truck,
                        keyboardType: TextInputType.text,
                        focusNode: _placaFocus,
                        maxLength: 8,
                        uppercase: true,
                      ),
                      _buildTextField(
                        controller: _motoristaController,
                        label: 'NOME DO MOTORISTA',
                        icon: FeatherIcons.user,
                        keyboardType: TextInputType.name,
                        focusNode: _motoristaFocus,
                      ),
                      _buildTextField(
                        controller: _idMotoristaController,
                        label: 'ID DO MOTORISTA',
                        icon: FeatherIcons.creditCard,
                        keyboardType: TextInputType.text,
                        focusNode: _idMotoristaFocus,
                        maxLength: 20,
                      ),
                      _buildTextField(
                        controller: _empresaController,
                        label: 'NOME DA EMPRESA',
                        icon: FeatherIcons.package,
                        keyboardType: TextInputType.text,
                        focusNode: _empresaFocus,
                      ),
                      const SizedBox(height: 8),
                      _buildRegisterButton(),
                      if (showSuccess) _buildSuccessCard(),
                    ],
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(), 
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _placaController.dispose();
    _motoristaController.dispose();
    _idMotoristaController.dispose();
    _empresaController.dispose();
    _placaFocus.dispose();
    _motoristaFocus.dispose();
    _idMotoristaFocus.dispose();
    _empresaFocus.dispose();
    super.dispose();
  }
}

enum SnackBarType { success, warning, error }

class _SnackBarConfig {
  final Color color;
  final IconData icon;

  _SnackBarConfig({required this.color, required this.icon});
}