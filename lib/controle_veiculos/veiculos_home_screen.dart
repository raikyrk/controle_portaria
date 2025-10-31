// veiculos_home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'date_time.dart';
import 'entrada_form.dart';
import 'saida_form.dart'; // ADICIONADO

class VeiculosHomeScreen extends StatefulWidget {
  const VeiculosHomeScreen({super.key});

  @override
  State<VeiculosHomeScreen> createState() => _VeiculosHomeScreenState();
}

class _VeiculosHomeScreenState extends State<VeiculosHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF7F7F7), Color(0xFFE5E7EB)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // === BOTÃO VOLTAR + CABEÇALHO ===
                Row(
                  children: [
                    // BOTÃO VOLTAR
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF6A00), Color(0xFFFF8B3D)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF6A00).withOpacity(0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(FeatherIcons.arrowLeft, color: Colors.white, size: 24),
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/menu');
                        },
                        tooltip: 'Voltar ao Menu',
                      ),
                    ),
                    const SizedBox(width: 16),
                    // TÍTULO CENTRALIZADO
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFFFF6A00), Color(0xFFFF8B3D)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 10,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            child: const Icon(
                              FeatherIcons.truck,
                              color: Colors.white,
                              size: 50,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Controle de Veículos',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0B0B0B),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Sistema de Registro - Portaria',
                            style: TextStyle(
                              fontSize: 18,
                              color: Color(0xFF6B7280),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 56),
                  ],
                ),

                const SizedBox(height: 20),

                // DATA/HORA
                const DateTimeCard(),

                const SizedBox(height: 20),

                // TAB BAR
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: const BoxDecoration(),
                    dividerColor: Colors.transparent,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                    tabs: [
                      _TabButton(
                        isActive: _tabController.index == 0,
                        icon: FeatherIcons.logIn,
                        label: 'ENTRADA',
                        activeGradient: const LinearGradient(
                          colors: [Color(0xFFFF6A00), Color(0xFFFF8B3D)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        inactiveColor: const Color(0xFFF9FAFB),
                      ),
                      _TabButton(
                        isActive: _tabController.index == 1,
                        icon: FeatherIcons.logOut,
                        label: 'SAÍDA',
                        activeGradient: const LinearGradient(
                          colors: [Color(0xFFE11D48), Color(0xFFDC2626)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        inactiveColor: const Color(0xFFF9FAFB),
                      ),
                    ],
                  ),
                ),

                // CONTEÚDO
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(top: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: TabBarView(
                        controller: _tabController,
                        children: const [
                          EntradaForm(),
                          SaidaForm(),
                        ],
                      ),
                    ),
                  ),
                ),

                // RODAPÉ
                Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        FeatherIcons.shield,
                        color: Color(0xFF6B7280),
                        size: 18,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Sistema Seguro de Controle de Veículos v1.0',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

// BOTÃO PERSONALIZADO
class _TabButton extends StatelessWidget {
  final bool isActive;
  final IconData icon;
  final String label;
  final LinearGradient activeGradient;
  final Color inactiveColor;

  const _TabButton({
    required this.isActive,
    required this.icon,
    required this.label,
    required this.activeGradient,
    required this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
      decoration: BoxDecoration(
        gradient: isActive ? activeGradient : null,
        color: isActive ? null : inactiveColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: activeGradient.colors.first.withOpacity(0.5),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 28,
            color: isActive ? Colors.white : const Color(0xFF6B7280),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: isActive ? Colors.white : const Color(0xFF6B7280),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}