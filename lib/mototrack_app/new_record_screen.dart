import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';
import 'package:controle_portaria/mototrack_app/service_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NewRecordScreen extends StatefulWidget {
  const NewRecordScreen({super.key});

  @override
  _NewRecordScreenState createState() => _NewRecordScreenState();
}

class _NewRecordScreenState extends State<NewRecordScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  String? _selectedConferente;
  String? _selectedMotoboy;
  String? _selectedPlaca;
  TimeOfDay? _arrivalTime;
  List<String> _conferentes = [];
  List<Map<String, dynamic>> _motoboys = [];
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _loadSavedConferente(); 
    _fetchData();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }


  Future<void> _loadSavedConferente() async {
    final prefs = await SharedPreferences.getInstance();
    final savedConferente = prefs.getString('selectedConferente');
    if (savedConferente != null) {
      setState(() {
        _selectedConferente = savedConferente;
      });
    }
  }


  Future<void> _saveConferente(String? conferente) async {
    final prefs = await SharedPreferences.getInstance();
    if (conferente != null) {
      await prefs.setString('selectedConferente', conferente);
    } else {
      await prefs.remove('selectedConferente');
    }
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final conferentes = await ApiService().fetchConferentes();
      final motoboys = await ApiService().fetchMotoboys();
      setState(() {
        _conferentes = conferentes;
        _motoboys = motoboys;
        
        if (_selectedConferente != null && !_conferentes.contains(_selectedConferente)) {
          _selectedConferente = null;
          _saveConferente(null); 
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar dados: $e. Tente novamente.'),
            backgroundColor: const Color(0xFFEF4444),
            action: SnackBarAction(
              label: 'Recarregar',
              onPressed: _fetchData,
              textColor: Colors.white,
            ),
          ),
        );
      }
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    TimeOfDay initialTime = _arrivalTime ?? TimeOfDay.now();
    Duration initialDuration = Duration(hours: initialTime.hour, minutes: initialTime.minute);
    await showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        Duration tempDuration = initialDuration;
        return Container(
          height: 250,
          color: Colors.white,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(
                          color: Color(0xFFEF4444),
                          fontSize: 16,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _arrivalTime = TimeOfDay(
                            hour: tempDuration.inHours,
                            minute: tempDuration.inMinutes % 60,
                          );
                        });
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Confirmar',
                        style: TextStyle(
                          color: Color(0xFFFF6A00),
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 100,
                      child: CupertinoPicker(
                        itemExtent: 32.0,
                        scrollController: FixedExtentScrollController(initialItem: initialTime.hour),
                        children: List<Widget>.generate(24, (index) => Center(child: Text('$index'.padLeft(2, '0')))),
                        onSelectedItemChanged: (index) {
                          tempDuration = Duration(hours: index, minutes: tempDuration.inMinutes % 60);
                        },
                      ),
                    ),
                    const Text(':', style: TextStyle(fontSize: 20)),
                    SizedBox(
                      width: 100,
                      child: CupertinoPicker(
                        itemExtent: 32.0,
                        scrollController: FixedExtentScrollController(initialItem: initialTime.minute),
                        children: List<Widget>.generate(60, (index) => Center(child: Text('$index'.padLeft(2, '0')))),
                        onSelectedItemChanged: (index) {
                          tempDuration = Duration(hours: tempDuration.inHours, minutes: index);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _onMotoboyChanged(String? selectedMotoboy) {
    setState(() {
      _selectedMotoboy = selectedMotoboy;
      _selectedPlaca = null;
      if (selectedMotoboy != null) {
        final motoboy = _motoboys.firstWhere(
          (m) => m['nome'] == selectedMotoboy,
          orElse: () => <String, Object>{},
        );
        print('Motoboy selecionado: $motoboy');
        if (motoboy.isNotEmpty && motoboy['placa'] != null) {
          _selectedPlaca = motoboy['placa'] as String;
          print('Placa definida: $_selectedPlaca');
        }
      }
    });
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_arrivalTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor, selecione o horário de chegada'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
        return;
      }
      final String date = DateFormat('dd/MM/yyyy').format(DateTime.now());
      final String timestamp = DateTime.now().toIso8601String();
      final String arrivalTime =
          '${_arrivalTime!.hour.toString().padLeft(2, '0')}:${_arrivalTime!.minute.toString().padLeft(2, '0')}';
      try {
        final response = await ApiService().saveRegistro({
          'data_registro': date,
          'timestamp_registro': timestamp,
          'conferente': _selectedConferente,
          'motoboy': _selectedMotoboy,
          'placa': _selectedPlaca,
          'horario_chegada': arrivalTime,
        });
        if (mounted) {
          if (response['success']) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Registro salvo com sucesso!'),
                backgroundColor: Color(0xFF22C55E),
              ),
            );
            _clearForm();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erro ao salvar: ${response['error']}'),
                backgroundColor: const Color(0xFFEF4444),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao salvar registro: $e'),
              backgroundColor: const Color(0xFFEF4444),
            ),
          );
        }
      }
    }
  }

  void _clearForm() {
    _formKey.currentState!.reset();
    setState(() {
      _selectedMotoboy = null;
      _selectedPlaca = null;
      _arrivalTime = null;

    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF9FAFB), Color(0xFFF3F4F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Align(
                        alignment: Alignment.topLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Container(
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
                        ),
                      ),
                      _buildHeader(),
                      const SizedBox(height: 16),
                      if (_isLoading)
                        const Center(child: CircularProgressIndicator())
                      else
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 672),
                                child: _buildFormCard(),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                      _buildFooter(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Novo Registro de Motoboy',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0B0B0B),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Preencha todos os campos obrigatórios',
          style: TextStyle(
            fontSize: 13,
            color: const Color(0xFF6B7280),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color.fromRGBO(255, 255, 255, 0.98),
            Color.fromRGBO(255, 255, 255, 0.96),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 40,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFF6A00), Color(0xFFFF8B3D)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            padding: const EdgeInsets.all(24),
            child: const Row(
              children: [
                Icon(FeatherIcons.edit3, color: Colors.white, size: 24),
                SizedBox(width: 12),
                Text(
                  'Informações do Registro',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(32),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildInputField(
                    label: 'Data *',
                    icon: FeatherIcons.calendar,
                    child: TextFormField(
                      initialValue: DateFormat('dd/MM/yyyy').format(DateTime.now()),
                      readOnly: true,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildDropdownField(
                    label: 'Conferente *',
                    icon: FeatherIcons.userCheck,
                    value: _selectedConferente,
                    items: _conferentes,
                    onChanged: (value) {
                      setState(() => _selectedConferente = value);
                      _saveConferente(value); 
                    },
                    validator: (value) => value == null ? 'Selecione um conferente' : null,
                  ),
                  const SizedBox(height: 24),
                  _buildDropdownField(
                    label: 'Motoboy *',
                    icon: FeatherIcons.users,
                    value: _selectedMotoboy,
                    items: _motoboys.map((m) => m['nome'] as String).toList(),
                    onChanged: _onMotoboyChanged,
                    validator: (value) => value == null ? 'Selecione um motoboy' : null,
                  ),
                  const SizedBox(height: 24),
                  _buildPlacaField(),
                  const SizedBox(height: 24),
                  _buildTimeField(),
                  const SizedBox(height: 32),
                  _buildInfoBox(),
                  const SizedBox(height: 32),
                  _buildActionButtons(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlacaField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(FeatherIcons.creditCard, size: 16, color: Color(0xFFFF6A00)),
            const SizedBox(width: 8),
            const Text(
              'Placa da Moto *',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0B0B0B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(FeatherIcons.creditCard, size: 20, color: Color(0xFFFF6A00)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _selectedPlaca ?? 'Selecione um motoboy primeiro',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _selectedPlaca != null
                        ? const Color(0xFFFF6A00)
                        : const Color(0xFF6B7280),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_selectedPlaca == null && _selectedMotoboy != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Text(
              'Placa carregada automaticamente',
              style: TextStyle(
                fontSize: 12,
                color: Colors.green[700],
              ),
            ),
          ),
        if (_selectedMotoboy == null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Text(
              'Selecione um motoboy para carregar a placa',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red[700],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFFFF6A00)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0B0B0B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: child,
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFFFF6A00)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0B0B0B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: Color(0xFF0B0B0B),
            ),
            icon: const Icon(FeatherIcons.chevronDown, size: 20),
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Row(
                  children: [
                    const Icon(FeatherIcons.user, size: 18, color: Color(0xFF6B7280)),
                    const SizedBox(width: 12),
                    Text(item),
                  ],
                ),
              );
            }).toList(),
            onChanged: onChanged,
            validator: validator,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(FeatherIcons.logIn, size: 16, color: Color(0xFF22C55E)),
            const SizedBox(width: 8),
            const Text(
              'Horário de Chegada *',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0B0B0B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () => _selectTime(context),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(FeatherIcons.clock, size: 20, color: Color(0xFF22C55E)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _arrivalTime != null
                        ? '${_arrivalTime!.hour.toString().padLeft(2, '0')}:${_arrivalTime!.minute.toString().padLeft(2, '0')}'
                        : 'Selecione o horário',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _arrivalTime != null
                          ? const Color(0xFF22C55E)
                          : const Color(0xFF6B7280),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_arrivalTime == null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Text(
              'Selecione o horário de chegada',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red[700],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInfoBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
        border: const Border(
          left: BorderSide(color: Color(0xFFFF6A00), width: 4),
        ),
      ),
      child: Row(
        children: [
          const Icon(FeatherIcons.info, size: 20, color: Color(0xFFFF6A00)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Campos obrigatórios marcados com *',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0B0B0B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'A placa é carregada automaticamente ao selecionar o motoboy',
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: _clearForm,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF0B0B0B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFFE5E7EB), width: 2),
            ),
          ),
          child: const Row(
            children: [
              Icon(FeatherIcons.refreshCw, size: 16),
              SizedBox(width: 8),
              Text(
                'Limpar',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
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
          child: ElevatedButton(
            onPressed: _submitForm,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Row(
              children: [
                Icon(FeatherIcons.checkCircle, size: 16, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Salvar Registro',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(FeatherIcons.shield, size: 16, color: Color(0xFF6B7280)),
          const SizedBox(width: 8),
          Text(
            'Todos os dados são salvos de forma segura',
            style: TextStyle(
              fontSize: 13,
              color: const Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}