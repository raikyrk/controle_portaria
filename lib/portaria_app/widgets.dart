import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:controle_portaria/portaria_app/models.dart' as models;

class CustomDropdown<T> extends StatelessWidget {
  final List<T> items;
  final T? selectedItem;
  final String hint;
  final String Function(T) displayText;
  final void Function(T?) onChanged;
  final bool Function(T) isDisabled;

  const CustomDropdown({
    super.key,
    required this.items,
    required this.selectedItem,
    required this.hint,
    required this.displayText,
    required this.onChanged,
    required this.isDisabled,
  });

  @override
  Widget build(BuildContext context) {
    // Verificar se selectedItem está na lista de items, caso contrário, usar null
    final validSelectedItem = items.contains(selectedItem) ? selectedItem : null;

    return DropdownButtonFormField<T>(
      value: validSelectedItem,
      hint: Text(
        hint,
        style: GoogleFonts.poppins(color: Colors.grey[700]),
      ),
      items: items.map((item) {
        return DropdownMenuItem<T>(
          value: item,
          enabled: !isDisabled(item),
          child: Text(
            displayText(item),
            style: GoogleFonts.poppins(
              color: isDisabled(item) ? Colors.grey[400] : Colors.black,
            ),
          ),
        );
      }).toList(),
      onChanged: (value) => onChanged(value),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF374151), width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF374151), width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFF97316), width: 2),
        ),
      ),
      style: GoogleFonts.poppins(),
      dropdownColor: Colors.white,
      isExpanded: true,
    );
  }
}

class RouteTag extends StatelessWidget {
  final String route;
  final int index;
  final VoidCallback onRemove;

  const RouteTag({
    super.key,
    required this.route,
    required this.index,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        '${index + 1}. $route',
        style: GoogleFonts.poppins(color: Colors.white),
      ),
      backgroundColor: const Color(0xFFF97316),
      deleteIcon: const Icon(Icons.close, color: Colors.white, size: 18),
      onDeleted: onRemove,
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}

class SummaryCard extends StatelessWidget {
  final String vehicle;
  final List<String> routes;
  final String driver;
  final String kmDeparture;
  final String lateralSeal;
  final String rearSeal;

  const SummaryCard({
    super.key,
    required this.vehicle,
    required this.routes,
    required this.driver,
    required this.kmDeparture,
    required this.lateralSeal,
    required this.rearSeal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumo',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          _buildSummaryRow(FontAwesomeIcons.truck, 'Veículo', vehicle),
          _buildSummaryRow(FontAwesomeIcons.route, 'Rota', routes.join(', ')),
          _buildSummaryRow(FontAwesomeIcons.user, 'Motorista', driver),
          _buildSummaryRow(FontAwesomeIcons.gaugeHigh, 'KM Saída', kmDeparture),
          if (lateralSeal.isNotEmpty)
            _buildSummaryRow(FontAwesomeIcons.lock, 'Lacre Lateral', lateralSeal),
          if (rearSeal.isNotEmpty)
            _buildSummaryRow(FontAwesomeIcons.lock, 'Lacre Traseiro', rearSeal),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFF97316), size: 20),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: GoogleFonts.poppins(color: Colors.grey[600]),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class HistoryItem extends StatelessWidget {
  final models.Trip trip;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const HistoryItem({
    super.key,
    required this.trip,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        leading: const Icon(FontAwesomeIcons.carSide, color: Color(0xFFF97316)),
        title: Text(
          trip.vehicle,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rota: ${trip.route.join(", ")}',
              style: GoogleFonts.poppins(),
            ),
            Text(
              'Motorista: ${trip.driver}',
              style: GoogleFonts.poppins(),
            ),
            if (trip.lateralSeal != null && trip.lateralSeal!.isNotEmpty)
              Text(
                'Lacre Lateral: ${trip.lateralSeal}',
                style: GoogleFonts.poppins(),
              ),
            if (trip.rearSeal != null && trip.rearSeal!.isNotEmpty)
              Text(
                'Lacre Traseiro: ${trip.rearSeal}',
                style: GoogleFonts.poppins(),
              ),
            Text(
              'Status: ${trip.status}',
              style: GoogleFonts.poppins(),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(FontAwesomeIcons.penToSquare, color: Color(0xFFF97316)),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(FontAwesomeIcons.trash, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}