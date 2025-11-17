// lib/supplier_control/exit_form.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'api.dart';

class ExitForm extends StatefulWidget {
  const ExitForm({super.key});

  @override
  State<ExitForm> createState() => _ExitFormState();
}

class _ExitFormState extends State<ExitForm>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> suppliersInside = [];
  Map<String, dynamic>? selectedSupplier;
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
    _loadSuppliersInside();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadSuppliersInside() async {
    setState(() => isLoading = true);
    try {
      final data = await Api.fetchSuppliersInsideToday();
      setState(() {
        suppliersInside = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showErrorSnackBar('Erro ao carregar fornecedores: $e');
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

  // ---------- SELETOR DE HORÁRIO ----------
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

  // ---------- REGISTRO DE SAÍDA ----------
  Future<void> _registerExit() async {
    if (selectedSupplier == null) {
      _showErrorSnackBar('Selecione um fornecedor');
      return;
    }
    if (_exitTime == null) {
      _showErrorSnackBar('Selecione o horário de saída');
      return;
    }

    setState(() => isRegistering = true);

    try {
      // API aceita apenas a placa (sem horário ainda)
      final success = await Api.registerSupplierExit(selectedSupplier!['placa']);

      if (!success) throw Exception('Falha ao registrar saída');

      setState(() {
        showSuccess = true;
        isRegistering = false;
        selectedSupplier = null;
        _exitTime = null;
      });

      _loadSuppliersInside();

      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) setState(() => showSuccess = false);
      });
    } catch (e) {
      setState(() => isRegistering = false);
      _showErrorSnackBar('Erro ao registrar saída: $e');
    }
  }

  // ---------- UI ----------
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
            color: const Color(0xFFFF6A00).withValues(alpha: 0.15),
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
              'Selecione o fornecedor que está saindo',
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
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Map<String, dynamic>>(
          value: selectedSupplier,
          isExpanded: true,
          hint: Row(
            children: const [
              Icon(FeatherIcons.truck, color: Color(0xFFFF6A00), size: 28),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'FORNECEDOR NA PORTARIA',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6B7280),
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Selecione a placa do veículo',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 36, color: Color(0xFFFF6A00)),
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
          dropdownColor: Colors.white,
          menuMaxHeight: 450,
          borderRadius: BorderRadius.circular(16),
          elevation: 8,
          selectedItemBuilder: (_) => suppliersInside.map((s) {
            return Row(
              children: [
                const Icon(FeatherIcons.truck, color: Color(0xFFFF6A00), size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('FORNECEDOR NA PORTARIA',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF6B7280))),
                      const SizedBox(height: 4),
                      Text(s['placa'],
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
          items: suppliersInside.map((s) {
            return DropdownMenuItem<Map<String, dynamic>>(
              value: s,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey[200]!, width: 1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6A00),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            s['placa'],
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF16A34A), width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(FeatherIcons.clock, size: 14, color: Color(0xFF16A34A)),
                              const SizedBox(width: 4),
                              Text(s['horario_chegada'],
                                  style: const TextStyle(
                                      fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(FeatherIcons.user, size: 14, color: Color(0xFF6B7280)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(s['motorista'],
                              style: const TextStyle(fontSize: 18, color: Color(0xFF374151), fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(FeatherIcons.package, size: 16, color: Color(0xFF6B7280)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(s['empresa'],
                              style: const TextStyle(fontSize: 18, color: Color(0xFF6B7280), fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
          onChanged: isLoading ? null : (value) => setState(() => selectedSupplier = value),
        ),
      ),
    );
  }

  Widget _buildSupplierInfoCard() {
    if (selectedSupplier == null) return const SizedBox.shrink();

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
                color: const Color(0xFFFBBF24).withValues(alpha: 0.3),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBBF24),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(FeatherIcons.info, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Text('FORNECEDOR SELECIONADO',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0B0B0B))),
                ],
              ),
              const SizedBox(height: 16),
              _buildInfoRow(FeatherIcons.user, 'MOTORISTA', selectedSupplier!['motorista']),
              const SizedBox(height: 12),
              _buildInfoRow(FeatherIcons.package, 'EMPRESA', selectedSupplier!['empresa']),
              const SizedBox(height: 12),
              _buildInfoRow(FeatherIcons.clock, 'ENTRADA', selectedSupplier!['horario_chegada'], isHighlight: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {bool isHighlight = false}) {
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
        Row(
          children: const [
            Icon(FeatherIcons.logOut, size: 18, color: Color(0xFFDC2626)),
            SizedBox(width: 8),
            Text('Horário de Saída *',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          ],
        ),
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
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 3))
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
                        color: _exitTime != null ? const Color(0xFFDC2626) : const Color(0xFF64748B)),
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
              ],
            ),
          ),
        ),
        if (_exitTime == null)
          const Padding(
            padding: EdgeInsets.only(top: 6, left: 4),
            child: Text('Obrigatório', style: TextStyle(color: Color(0xFFEF4444), fontSize: 12)),
          ),
      ],
    );
  }

  Widget _buildRegisterButton() {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF16A34A), Color(0xFF15803D)]),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: const Color(0xFF16A34A).withValues(alpha: 0.5), blurRadius: 14, offset: const Offset(0, 6)),
        ],
      ),
      child: ElevatedButton(
        onPressed: isRegistering ? null : _registerExit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        child: isRegistering
            ? const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(FeatherIcons.checkCircle, color: Colors.white, size: 28),
                  SizedBox(width: 12),
                  Text('REGISTRAR SAÍDA',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                ],
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
              BoxShadow(color: const Color(0xFF16A34A).withValues(alpha: 0.6), blurRadius: 30, spreadRadius: 5, offset: const Offset(0, 8)),
            ],
          ),
          child: const Column(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white,
                child: Icon(FeatherIcons.checkCircle, color: Color(0xFF16A34A), size: 56),
              ),
              SizedBox(height: 20),
              Text('SAÍDA REGISTRADA!',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2),
                  textAlign: TextAlign.center),
              SizedBox(height: 8),
              Text('Fornecedor liberado com sucesso',
                  style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w500),
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
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInfoCard(),
            _buildDropdown(),
            const SizedBox(height: 24),
            if (selectedSupplier != null) _buildSupplierInfoCard(),
            if (selectedSupplier != null) const SizedBox(height: 20),
            if (selectedSupplier != null) _buildExitTimeField(),
            if (selectedSupplier != null) const SizedBox(height: 20),
            if (selectedSupplier != null) _buildRegisterButton(),
            if (showSuccess) _buildSuccessCard(),
          ],
        ),
      ),
    );
  }
}