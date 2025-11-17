// lib/supplier_control/exit_form.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'api.dart';

// Widget reutilizável para o ícone do caminhão (evita repetir código)
class _TruckIcon extends StatelessWidget {
  const _TruckIcon({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFF6A00).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(FeatherIcons.truck, color: Color(0xFFFF6A00), size: 24),
    );
  }
}

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
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    _slideAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
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
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(FeatherIcons.alertCircle, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Erro', style: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(message, style: const TextStyle(fontSize: 15, color: Colors.white)),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        duration: const Duration(seconds: 4),
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
      isScrollControlled: true,
      builder: (_) => Container(
        height: 340,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 50,
              height: 5,
              decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(10)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6), width: 1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(FeatherIcons.x, size: 20, color: Color(0xFFEF4444)),
                    label: const Text('Cancelar', style: TextStyle(color: Color(0xFFEF4444), fontSize: 17, fontWeight: FontWeight.w600)),
                  ),
                  const Text('Horário de Saída', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _exitTime = TimeOfDay(hour: tempDuration.inHours, minute: tempDuration.inMinutes % 60);
                      });
                      Navigator.pop(context);
                    },
                    icon: const Icon(FeatherIcons.check, size: 20, color: Color(0xFF16A34A)),
                    label: const Text('Confirmar', style: TextStyle(color: Color(0xFF16A34A), fontSize: 17, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: CupertinoPicker(
                      itemExtent: 50,
                      scrollController: FixedExtentScrollController(initialItem: initialTime.hour),
                      selectionOverlay: Container(
                        decoration: BoxDecoration(
                          border: Border.symmetric(
                            horizontal: BorderSide(color: const Color(0xFFFF6A00).withOpacity(0.3), width: 2),
                          ),
                        ),
                      ),
                      children: List.generate(24, (i) => Center(child: Text(i.toString().padLeft(2, '0'), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: Color(0xFF111827))))),
                      onSelectedItemChanged: (i) => tempDuration = Duration(hours: i, minutes: tempDuration.inMinutes % 60),
                    ),
                  ),
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text(':', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFFFF6A00)))),
                  Expanded(
                    child: CupertinoPicker(
                      itemExtent: 50,
                      scrollController: FixedExtentScrollController(initialItem: initialTime.minute),
                      selectionOverlay: Container(
                        decoration: BoxDecoration(
                          border: Border.symmetric(
                            horizontal: BorderSide(color: const Color(0xFFFF6A00).withOpacity(0.3), width: 2),
                          ),
                        ),
                      ),
                      children: List.generate(60, (i) => Center(child: Text(i.toString().padLeft(2, '0'), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: Color(0xFF111827))))),
                      onSelectedItemChanged: (i) => tempDuration = Duration(hours: tempDuration.inHours, minutes: i),
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

  // ---------- UI COMPONENTS ----------
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFF6A00), Color(0xFFFF8534)]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: const Color(0xFFFF6A00).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
            child: const Icon(FeatherIcons.logOut, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 20),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Registro de Saída', style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                SizedBox(height: 4),
                Text('Selecione o fornecedor que está saindo', style: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500, height: 1.4)),
              ],
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
        border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: DropdownButtonHideUnderline(
          child: DropdownButton<Map<String, dynamic>>(
            value: selectedSupplier,
            isExpanded: true,
            hint: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(children: [_TruckIcon(), SizedBox(width: 16), Text('Selecione o fornecedor', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFF9CA3AF)))]),
            ),
            icon: const Padding(padding: EdgeInsets.all(16), child: Icon(Icons.keyboard_arrow_down_rounded, size: 28, color: Color(0xFF6B7280))),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
            dropdownColor: Colors.white,
            menuMaxHeight: 600,
            borderRadius: BorderRadius.circular(20),
            elevation: 16,
            itemHeight: null,
            selectedItemBuilder: (_) => suppliersInside.map((s) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(children: [const _TruckIcon(), SizedBox(width: 16), Text(s['placa'], style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold))]),
            )).toList(),
            items: suppliersInside.map((s) {
              return DropdownMenuItem<Map<String, dynamic>>(
                value: s,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFFF6A00), Color(0xFFFF8534)]), borderRadius: BorderRadius.circular(10)),
                            child: Text(s['placa'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF10B981))),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(FeatherIcons.clock, size: 14, color: Color(0xFF10B981)),
                              const SizedBox(width: 6),
                              Text(s['horario_chegada'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                            ]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(s['motorista'], style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(s['empresa'], style: const TextStyle(fontSize: 14, color: Colors.grey), overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              );
            }).toList(),
            onChanged: isLoading ? null : (value) => setState(() => selectedSupplier = value),
          ),
        ),
      ),
    );
  }

  Widget _buildSupplierInfoCard() {
    if (selectedSupplier == null) return const SizedBox.shrink();

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 700),
      curve: Curves.elasticOut,
      builder: (_, value, child) {
        final anim = value.clamp(0.0, 1.0); // CORREÇÃO DO ERRO DE OPACITY
        return Transform.scale(
          scale: anim,
          child: Opacity(opacity: anim, child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [const Color(0xFFFFFBEB), const Color(0xFFFEF3C7).withOpacity(0.7)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFFBBF24).withOpacity(0.3), width: 2),
          boxShadow: [BoxShadow(color: const Color(0xFFFBBF24).withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)]),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: const Color(0xFFFBBF24).withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: const Icon(FeatherIcons.info, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                const Expanded(child: Text('Fornecedor Selecionado', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF78350F), letterSpacing: 0.5))),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoRow(FeatherIcons.user, 'Motorista', selectedSupplier!['motorista']),
            const SizedBox(height: 14),
            _buildInfoRow(FeatherIcons.package, 'Empresa', selectedSupplier!['empresa']),
            const SizedBox(height: 14),
            _buildInfoRow(FeatherIcons.clock, 'Entrada', selectedSupplier!['horario_chegada'], isHighlight: true),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {bool isHighlight = false}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isHighlight ? const Color(0xFFECFDF5) : Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isHighlight ? const Color(0xFF10B981).withOpacity(0.3) : const Color(0xFFE5E7EB), width: 1.5),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: isHighlight ? const Color(0xFF10B981) : const Color(0xFF6B7280)),
          const SizedBox(width: 12),
          Text('$label: ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isHighlight ? const Color(0xFF10B981) : const Color(0xFF6B7280))),
          Expanded(child: Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isHighlight ? const Color(0xFF10B981) : const Color(0xFF111827)))),
        ],
      ),
    );
  }

  Widget _buildExitTimeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(children: [
          Icon(FeatherIcons.logOut, size: 20, color: Color(0xFFDC2626)),
          SizedBox(width: 10),
          Text('Horário de Saída', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
          SizedBox(width: 4),
          Text('*', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
        ]),
        const SizedBox(height: 14),
        InkWell(
          onTap: () => _selectExitTime(context),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _exitTime != null ? const Color(0xFFDC2626) : const Color(0xFFE5E7EB), width: 2),
              boxShadow: [BoxShadow(color: _exitTime != null ? const Color(0xFFDC2626).withOpacity(0.1) : Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: _exitTime != null ? const Color(0xFFDC2626).withOpacity(0.1) : const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(12)),
                  child: Icon(FeatherIcons.clock, size: 22, color: _exitTime != null ? const Color(0xFFDC2626) : const Color(0xFF9CA3AF)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    _exitTime != null ? '${_exitTime!.hour.toString().padLeft(2, '0')}:${_exitTime!.minute.toString().padLeft(2, '0')}' : 'Toque para selecionar',
                    style: TextStyle(fontSize: 18, fontWeight: _exitTime != null ? FontWeight.bold : FontWeight.w600, color: _exitTime != null ? const Color(0xFFDC2626) : const Color(0xFF9CA3AF), letterSpacing: _exitTime != null ? 1.5 : 0),
                  ),
                ),
                Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF6B7280), size: 24)),
              ],
            ),
          ),
        ),
        if (_exitTime == null)
          const Padding(
            padding: EdgeInsets.only(top: 8, left: 4),
            child: Row(children: [Icon(FeatherIcons.alertCircle, size: 14, color: Color(0xFFEF4444)), SizedBox(width: 6), Text('Campo obrigatório', style: TextStyle(color: Color(0xFFEF4444), fontSize: 13, fontWeight: FontWeight.w500))]),
          ),
      ],
    );
  }

  Widget _buildRegisterButton() {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF16A34A), Color(0xFF15803D)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: const Color(0xFF16A34A).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: ElevatedButton(
        onPressed: isRegistering ? null : _registerExit,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), padding: const EdgeInsets.symmetric(vertical: 18)),
        child: isRegistering
            ? const SizedBox(width: 32, height: 32, child: CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle), child: const Icon(FeatherIcons.checkCircle, color: Colors.white, size: 24)),
                const SizedBox(width: 14),
                const Text('REGISTRAR SAÍDA', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              ]),
      ),
    );
  }

  Widget _buildSuccessCard() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.elasticOut,
      builder: (_, value, child) {
        final anim = value.clamp(0.0, 1.0); // CORREÇÃO DO ERRO DE OPACITY
        return Transform.scale(scale: anim, child: Opacity(opacity: anim, child: child));
      },
      child: Container(
        margin: const EdgeInsets.only(top: 28),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF16A34A), Color(0xFF15803D)]),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: [BoxShadow(color: const Color(0xFF16A34A).withOpacity(0.5), blurRadius: 30, spreadRadius: 2, offset: const Offset(0, 12))],
        ),
        child: Column(
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOut,
              builder: (_, scaleValue, child) => Transform.scale(
                scale: scaleValue,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 8))]),
                  child: const Icon(FeatherIcons.checkCircle, color: Color(0xFF16A34A), size: 64),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('SAÍDA REGISTRADA!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.5), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
              child: const Text('Fornecedor liberado com sucesso', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: const Color(0xFFF3F4F6), shape: BoxShape.circle), child: const Icon(FeatherIcons.inbox, size: 64, color: Color(0xFF9CA3AF))),
            const SizedBox(height: 24),
            const Text('Nenhum fornecedor dentro', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF6B7280))),
            const SizedBox(height: 8),
            const Text('Não há fornecedores para registrar saída no momento', style: TextStyle(fontSize: 15, color: Color(0xFF9CA3AF)), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(_slideAnimation),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              if (isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Column(children: [CircularProgressIndicator(color: Color(0xFFFF6A00), strokeWidth: 3), SizedBox(height: 16), Text('Carregando fornecedores...', style: TextStyle(fontSize: 15, color: Color(0xFF6B7280), fontWeight: FontWeight.w500))]),
                  ),
                )
              else if (suppliersInside.isEmpty)
                _buildEmptyState()
              else ...[
                _buildDropdown(),
                if (selectedSupplier != null) ...[_buildSupplierInfoCard(), _buildExitTimeField(), const SizedBox(height: 24), _buildRegisterButton()],
              ],
              if (showSuccess) _buildSuccessCard(),
            ],
          ),
        ),
      ),
    );
  }
}