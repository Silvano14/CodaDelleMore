import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../constants/colors.dart';

class BookingsSectionWidget extends StatelessWidget {
  final bool bookingsEnabled;
  final ValueChanged<bool> onBookingsEnabledChanged;
  final TextEditingController contactPhoneController;
  final TextEditingController priceController;
  final DateTime? bookingDeadline;
  final VoidCallback onSelectDeadline;
  final VoidCallback onClearDeadline;

  const BookingsSectionWidget({
    super.key,
    required this.bookingsEnabled,
    required this.onBookingsEnabledChanged,
    required this.contactPhoneController,
    required this.priceController,
    this.bookingDeadline,
    required this.onSelectDeadline,
    required this.onClearDeadline,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          Text(
            bookingsEnabled
                ? 'Le prenotazioni sono aperte'
                : 'Le prenotazioni sono chiuse',
            style: TextStyle(
              fontSize: 12,
              color: bookingsEnabled ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(height: 16),
          _buildPhoneField(),
          const SizedBox(height: 12),
          _buildPriceAndDeadlineRow(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(Icons.book_online, color: Colors.grey[700], size: 20),
        const SizedBox(width: 8),
        Text(
          'Prenotazioni',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const Spacer(),
        Switch(
          value: bookingsEnabled,
          onChanged: onBookingsEnabledChanged,
          activeTrackColor: AppColors.primary,
        ),
      ],
    );
  }

  Widget _buildPhoneField() {
    return TextFormField(
      controller: contactPhoneController,
      decoration: InputDecoration(
        labelText: 'Telefono per prenotazioni',
        hintText: 'es. 346 1234567',
        prefixIcon: const Icon(Icons.phone),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      keyboardType: TextInputType.phone,
    );
  }

  Widget _buildPriceAndDeadlineRow() {
    return Row(
      children: [
        Expanded(child: _buildPriceField()),
        const SizedBox(width: 12),
        Expanded(child: _buildDeadlineField()),
      ],
    );
  }

  Widget _buildPriceField() {
    return TextFormField(
      controller: priceController,
      decoration: InputDecoration(
        labelText: 'Prezzo',
        hintText: 'es. 15',
        prefixIcon: const Icon(Icons.euro),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*[,.]?\d{0,2}')),
      ],
    );
  }

  Widget _buildDeadlineField() {
    return InkWell(
      onTap: onSelectDeadline,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Scadenza',
          prefixIcon: const Icon(Icons.event_busy),
          suffixIcon: bookingDeadline != null
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: onClearDeadline,
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
        ),
        child: Text(
          bookingDeadline != null
              ? DateFormat('dd/MM').format(bookingDeadline!)
              : 'Nessuna',
          style: TextStyle(
            color: bookingDeadline != null ? Colors.black : Colors.grey,
          ),
        ),
      ),
    );
  }
}
