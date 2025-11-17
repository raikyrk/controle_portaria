// lib/controle_veiculos/saida_form.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'services_api.dart';

class SaidaForm extends StatefulWidget {
  const SaidaForm({super.key});

  @override
  State<SaidaForm> createState() => _SaidaFormState();
}

class _SaidaFormState extends State<SaidaForm>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> veiculosDentro = [];
  Map<String, dynamic>? selectedVehicle;
  TimeOfDay? _exitTime;
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

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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

 
  Future<void> _selectExitTime(BuildContext context) async {
    TimeOfDay initialTime = _exitTime ?? TimeOfDay.now();
    Duration tempDuration = Duration(hours: initialTime.hour, minutes: initialTime.minute);

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: 300,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar',
                        style: TextStyle(color: Color(0xFFEF4444), fontSize: 17)),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _exitTime = TimeOfDay(
                          hour: tempDuration.inHours,
                          minute: tempDuration.inMinutes % 60,
                        );
                      });
                      Navigator.pop(context);
                    },
                    child: const Text('Confirmar',
                        style: TextStyle(
                            color: Color(0xFFFF6A00),
                            fontSize: 17,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 110,
                    child: CupertinoPicker(
                      itemExtent: 40,
                      scrollController: FixedExtentScrollController(initialItem: initialTime.hour),
                      children: List.generate(
                          24,
                          (i) => Center(
                              child: Text(i.toString().padLeft(2, '0'),
                                  style: const TextStyle(fontSize: 24)))),
                      onSelectedItemChanged: (i) {
                        tempDuration = Duration(hours: i, minutes: tempDuration.inMinutes % 60);
                      },
                    ),
                  ),
                  const Text(':', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                  SizedBox(
                    width: 110,
                    child: CupertinoPicker(
                      itemExtent: 40,
                      scrollController: FixedExtentScrollController(initialItem: initialTime.minute),
                      children: List.generate(
                          60,
                          (i) => Center(
                              child: Text(i.toString().padLeft(2, '0'),
                                  style: const TextStyle(fontSize: 24)))),
                      onSelectedItemChanged: (i) {
                        tempDuration = Duration(hours: tempDuration.inHours, minutes: i);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Future<void> _registerSaida() async {
    if (selectedVehicle == null) {
      _showErrorSnackBar('Selecione um veículo');
      return;
    }
    if (_exitTime == null) {
      _showErrorSnackBar('Selecione o horário de saída');
      return;
    }

    setState(() => isRegistering = true);

    final horarioFormatado = '${_exitTime!.hour.toString().padLeft(2, '0')}:${_exitTime!.minute.toString().padLeft(2, '0')}';

    try {
      final success = await ApiService.registerSaida(
        selectedVehicle!['placa'],
        horarioFormatado,
      );

      if (!success) throw Exception('Falha ao registrar saída no servidor');

      setState(() {
        showSuccess = true;
        isRegistering = false;
        selectedVehicle = null;
        _exitTime = null;
      });

      _loadVeiculosDentro();

      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) {
          setState(() => showSuccess = false);
        }
      });
    } catch (e) {
      setState(() => isRegistering = false);
      _showErrorSnackBar('Erro ao registrar saída: $e');
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
            child: const Icon(FeatherIcons.logOut, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Selecione o veículo que está saindo',
              style: TextStyle(
                fontSize: 16,
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
      border: Border.all(color: const Color(0xFFD1D5DB), width: 3),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 15,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<Map<String, dynamic>>(
        value: selectedVehicle,
        isExpanded: true,
        hint: Row(
          children: const [
            Icon(FeatherIcons.truck, color: Color(0xFFFF6A00), size: 26),
            SizedBox(width: 12),
            Text(
              'Selecione o veículo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey),
            ),
          ],
        ),
        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32, color: Color(0xFFFF6A00)),
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
        dropdownColor: Colors.white,
        menuMaxHeight: 400,
        borderRadius: BorderRadius.circular(16),
        elevation: 8,
        onChanged: isLoading ? null : (value) => setState(() => selectedVehicle = value),
        items: veiculosDentro.map((v) {
          return DropdownMenuItem<Map<String, dynamic>>(
            value: v,
            child: SizedBox(
              height: 48, 
              child: Row(
                children: [
                  
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6A00),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      v['placa'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  Expanded(
                    child: Text(
                      '${v['motorista']} • ${v['modelo']}',
                      style: const TextStyle(fontSize: 15),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  Text(
                    v['horario_chegada'],
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF16A34A),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
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
      builder: (_, value, child) => Transform.scale(
        scale: value,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFFBBF24), width: 2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFBBF24).withOpacity(0.3),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('VEÍCULO SELECIONADO',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildInfoRow(FeatherIcons.user, 'MOTORISTA', selectedVehicle!['motorista']),
              const SizedBox(height: 12),
              _buildInfoRow(FeatherIcons.tag, 'MODELO', selectedVehicle!['modelo']),
              const SizedBox(height: 12),
              _buildInfoRow(FeatherIcons.clock, 'ENTRADA',
                  selectedVehicle!['horario_chegada'], isHighlight: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      {bool isHighlight = false}) {
    return Row(
      children: [
        Icon(icon,
            size: 24,
            color: isHighlight ? const Color(0xFF16A34A) : const Color(0xFF78716C)),
        const SizedBox(width: 12),
        Text('$label: ',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isHighlight ? const Color(0xFF16A34A) : const Color(0xFF78716C))),
        Expanded(
          child: Text(value,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isHighlight ? const Color(0xFF16A34A) : const Color(0xFF0B0B0B))),
        ),
      ],
    );
  }

  Widget _buildExitTimeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Horário de Saída *',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        InkWell(
          onTap: () => _selectExitTime(context),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3))
              ],
            ),
            child: Row(
              children: [
                const Icon(FeatherIcons.clock, size: 22, color: Color(0xFFDC2626)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _exitTime != null
                        ? '${_exitTime!.hour.toString().padLeft(2, '0')}:${_exitTime!.minute.toString().padLeft(2, '0')}'
                        : 'Toque para selecionar',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: _exitTime != null
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF64748B)),
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFF64748B)),
              ],
            ),
          ),
        ),
        if (_exitTime == null)
          const Padding(
            padding: EdgeInsets.only(top: 6, left: 4),
            child: Text('Obrigatório',
                style: TextStyle(color: Color(0xFFEF4444), fontSize: 12)),
          ),
      ],
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      height: 58,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF16A34A), Color(0xFF15803D)]),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF16A34A).withOpacity(0.5),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: isRegistering ? null : _registerSaida,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
          child: isRegistering
              ? const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                )
              : const Text('REGISTRAR SAÍDA',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2)),
        ),
      ),
    );
  }

  Widget _buildSuccessCard() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.elasticOut,
      builder: (_, value, child) => Transform.scale(
        scale: value,
        child: Container(
          margin: const EdgeInsets.only(top: 24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF16A34A), Color(0xFF15803D)]),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF16A34A).withOpacity(0.6),
                blurRadius: 30,
                spreadRadius: 5,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Column(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white,
                child: Icon(FeatherIcons.checkCircle,
                    color: Color(0xFF16A34A), size: 56),
              ),
              SizedBox(height: 20),
              Text('SAÍDA REGISTRADA!',
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2),
                  textAlign: TextAlign.center),
              SizedBox(height: 8),
              Text('Veículo liberado com sucesso',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInfoCard(),
            _buildDropdown(),
            const SizedBox(height: 24),
            if (selectedVehicle != null) _buildVehicleInfoCard(),
            if (selectedVehicle != null) const SizedBox(height: 20),
            if (selectedVehicle != null) _buildExitTimeField(),
            if (selectedVehicle != null) const SizedBox(height: 20),
            if (selectedVehicle != null) _buildRegisterButton(),
            if (showSuccess) _buildSuccessCard(),
          ],
        ),
      ),
    );
  }
}