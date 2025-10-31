// saida_form.dart
import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'services_api.dart';

class SaidaForm extends StatefulWidget {
  const SaidaForm({super.key});

  @override
  _SaidaFormState createState() => _SaidaFormState();
}

class _SaidaFormState extends State<SaidaForm>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> veiculosDentro = [];
  Map<String, dynamic>? selectedVehicle;
  bool isLoading = false;
  bool isRegistering = false;
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
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _loadVeiculosDentro();
    _animationController.forward();
  }

  Future<void> _loadVeiculosDentro() async {
    setState(() => isLoading = true);
    try {
      final data = await ApiService.fetchVeiculosDentroHoje();
      setState(() {
        veiculosDentro = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showErrorSnackBar('Erro ao carregar veículos: $e');
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

  Future<void> _registerSaida() async {
    if (selectedVehicle == null) {
      _showErrorSnackBar('Selecione um veículo');
      return;
    }

    setState(() => isRegistering = true);

    try {
      final success = await ApiService.registerSaida(selectedVehicle!['placa']);
      if (!success) throw Exception('Falha ao registrar saída');

      setState(() {
        showSuccess = true;
        isRegistering = false;
        selectedVehicle = null;
      });

      _loadVeiculosDentro();

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
              'Selecione o veículo que está saindo',
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

  Widget _buildDropdown() {
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
      child: DropdownButtonFormField<Map<String, dynamic>>(
        value: selectedVehicle,
        hint: const Text(
          'Selecione a placa',
          style: TextStyle(fontSize: 18, color: Color(0xFF6B7280)),
        ),
        decoration: InputDecoration(
          labelText: 'VEÍCULO NA PORTARIA',
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF374151),
            fontSize: 18,
          ),
          prefixIcon: const Icon(FeatherIcons.truck, color: Color(0xFFFF6A00), size: 32),
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
        items: veiculosDentro.map((v) {
          return DropdownMenuItem<Map<String, dynamic>>(
            value: v,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  v['placa'],
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${v['motorista']} • ${v['modelo']} • ${v['horario_chegada']}',
                  style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: isLoading ? null : (value) {
          setState(() {
            selectedVehicle = value;
          });
        },
        dropdownColor: Colors.white,
        isExpanded: true,
      ),
    );
  }

  Widget _buildRefreshButton() {
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
        onPressed: isLoading ? null : _loadVeiculosDentro,
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
                  strokeWidth: 4,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(FeatherIcons.refreshCw, color: Colors.white, size: 32),
                  SizedBox(width: 16),
                  Text(
                    'ATUALIZAR LISTA',
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
    if (selectedVehicle == null) return const SizedBox.shrink();

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
                      child: const Icon(FeatherIcons.info, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'VEÍCULO SELECIONADO',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0B0B0B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildInfoRow(FeatherIcons.user, 'MOTORISTA', selectedVehicle!['motorista']),
                const SizedBox(height: 16),
                _buildInfoRow(FeatherIcons.tag, 'MODELO', selectedVehicle!['modelo']),
                const SizedBox(height: 16),
                _buildInfoRow(
                  FeatherIcons.clock,
                  'ENTRADA',
                  selectedVehicle!['horario_chegada'],
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
            _buildDropdown(),
            const SizedBox(height: 24),
            _buildRefreshButton(),
            if (selectedVehicle != null) _buildVehicleInfoCard(),
            if (selectedVehicle != null) const SizedBox(height: 24),
            if (selectedVehicle != null) _buildRegisterButton(),
            if (showSuccess) _buildSuccessCard(),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}