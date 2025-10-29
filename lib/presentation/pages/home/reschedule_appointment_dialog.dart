import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:juan_heart/core/app_exports.dart';
import 'package:juan_heart/models/appointment_model.dart';
import 'package:juan_heart/services/appointment_service.dart';
import 'package:juan_heart/services/appointment_validation_service.dart';

class RescheduleAppointmentDialog extends StatefulWidget {
  final Appointment appointment;

  const RescheduleAppointmentDialog({
    Key? key,
    required this.appointment,
  }) : super(key: key);

  @override
  State<RescheduleAppointmentDialog> createState() =>
      _RescheduleAppointmentDialogState();
}

class _RescheduleAppointmentDialogState
    extends State<RescheduleAppointmentDialog> {
  late DateTime _selectedDate;
  String? _selectedTime;
  List<TimeSlot> _availableSlots = [];
  bool _isLoadingSlots = false;

  @override
  void initState() {
    super.initState();
    // Initialize with current appointment date
    _selectedDate = widget.appointment.appointmentDate;
    _selectedTime = widget.appointment.appointmentTime;
    _loadAvailableSlots();
  }

  Future<void> _loadAvailableSlots() async {
    setState(() => _isLoadingSlots = true);

    try {
      final slots = await AppointmentService.getAvailableTimeSlots(
        widget.appointment.facilityId,
        _selectedDate,
      );

      setState(() {
        _availableSlots = slots;
        _isLoadingSlots = false;
        // Reset selected time if it's no longer available
        if (_selectedTime != null &&
            !slots.any((s) => s.time == _selectedTime && s.isAvailable)) {
          _selectedTime = null;
        }
      });
    } catch (e) {
      setState(() => _isLoadingSlots = false);
      print('Error loading time slots: $e');
    }
  }

  Future<void> _selectDate() async {
    final isFilipino = Get.locale?.languageCode == 'fil';
    final now = DateTime.now();
    final maxDate = now.add(const Duration(days: 90));

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isAfter(now) ? _selectedDate : now,
      firstDate: now,
      lastDate: maxDate,
      helpText: isFilipino ? 'Pumili ng Petsa' : 'Select Date',
      cancelText: isFilipino ? 'Kanselahin' : 'Cancel',
      confirmText: isFilipino ? 'OK' : 'OK',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: ColorConstant.lightRed,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _selectedTime = null; // Reset time selection
      });
      await _loadAvailableSlots();
    }
  }

  Future<void> _rescheduleAppointment() async {
    final isFilipino = Get.locale?.languageCode == 'fil';

    if (_selectedTime == null) {
      Get.snackbar(
        isFilipino ? 'Error' : 'Error',
        isFilipino
            ? 'Pumili ng oras para sa appointment'
            : 'Please select an appointment time',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // Show loading dialog
    Get.dialog(
      const Center(
        child: CircularProgressIndicator(),
      ),
      barrierDismissible: false,
    );

    try {
      // Validate reschedule
      final validationError =
          await AppointmentValidationService.validateReschedule(
        appointment: widget.appointment,
        newDate: _selectedDate,
        newTime: _selectedTime!,
      );

      if (validationError != null) {
        Get.back(); // Close loading dialog
        Get.snackbar(
          isFilipino ? 'Hindi Pwede' : 'Validation Error',
          validationError,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 4),
        );
        return;
      }

      // Perform reschedule
      final success = await AppointmentService.rescheduleAppointment(
        widget.appointment.id,
        _selectedDate,
        _selectedTime!,
      );

      Get.back(); // Close loading dialog

      if (success) {
        // Show success dialog
        await Get.dialog(
          AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[600], size: 28),
                const SizedBox(width: 12),
                Text(
                  isFilipino ? 'Na-reschedule!' : 'Rescheduled!',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
            content: Text(
              isFilipino
                  ? 'Ang iyong appointment ay successfully na-reschedule.\n\n'
                      'Bagong petsa: ${DateFormat('MMMM d, yyyy').format(_selectedDate)}\n'
                      'Bagong oras: $_selectedTime'
                  : 'Your appointment has been successfully rescheduled.\n\n'
                      'New date: ${DateFormat('MMMM d, yyyy').format(_selectedDate)}\n'
                      'New time: $_selectedTime',
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Get.back(); // Close success dialog
                  Get.back(result: true); // Close reschedule dialog with success result
                },
                child: Text(
                  isFilipino ? 'OK' : 'OK',
                  style: TextStyle(
                    color: ColorConstant.lightRed,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          barrierDismissible: false,
        );
      } else {
        Get.snackbar(
          isFilipino ? 'Error' : 'Error',
          isFilipino
              ? 'Hindi ma-reschedule ang appointment. Subukan ulit.'
              : 'Failed to reschedule appointment. Please try again.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.back(); // Close loading dialog
      print('Error rescheduling appointment: $e');
      Get.snackbar(
        isFilipino ? 'Error' : 'Error',
        isFilipino
            ? 'May nangyaring error. Subukan ulit.'
            : 'An unexpected error occurred. Please try again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFilipino = Get.locale?.languageCode == 'fil';

    return Scaffold(
      backgroundColor: ColorConstant.whiteBackground,
      appBar: AppBar(
        backgroundColor: ColorConstant.whiteBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: ColorConstant.bluedark),
          onPressed: () => Get.back(),
        ),
        title: Text(
          isFilipino ? 'I-reschedule ang Appointment' : 'Reschedule Appointment',
          style: TextStyle(
            color: ColorConstant.bluedark,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Current Appointment Info
          _buildCurrentAppointmentCard(isFilipino),
          const SizedBox(height: 24),

          // New Date Selection
          _buildDateSelectionCard(isFilipino),
          const SizedBox(height: 16),

          // Time Slot Selection
          _buildTimeSlotSection(isFilipino),
          const SizedBox(height: 24),

          // Reschedule Button
          _buildRescheduleButton(isFilipino),
          const SizedBox(height: 16),

          // Info Card
          _buildInfoCard(isFilipino),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCurrentAppointmentCard(bool isFilipino) {
    return Card(
      elevation: 2,
      color: Colors.blue[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                const SizedBox(width: 8),
                Text(
                  isFilipino
                      ? 'Kasalukuyang Appointment'
                      : 'Current Appointment',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.calendar_today,
              isFilipino ? 'Petsa:' : 'Date:',
              DateFormat('EEEE, MMMM d, yyyy')
                  .format(widget.appointment.appointmentDate),
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.access_time,
              isFilipino ? 'Oras:' : 'Time:',
              widget.appointment.appointmentTime,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.local_hospital,
              isFilipino ? 'Pasilidad:' : 'Facility:',
              widget.appointment.facilityName,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.person,
              isFilipino ? 'Doktor:' : 'Doctor:',
              widget.appointment.doctorName,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.blue[600]),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.blue[800],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: Colors.blue[900],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateSelectionCard(bool isFilipino) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isFilipino ? 'Pumili ng Bagong Petsa' : 'Select New Date',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
                color: ColorConstant.bluedark,
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _selectDate,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: ColorConstant.lightRed),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios,
                        size: 16, color: Colors.grey[600]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSlotSection(bool isFilipino) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isFilipino ? 'Pumili ng Bagong Oras' : 'Select New Time',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
                color: ColorConstant.bluedark,
              ),
            ),
            const SizedBox(height: 12),
            if (_isLoadingSlots)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              _buildTimeSlotGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSlotGrid() {
    final availableSlots =
        _availableSlots.where((slot) => slot.isAvailable).toList();
    final bookedSlots =
        _availableSlots.where((slot) => !slot.isAvailable).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Available slots
        if (availableSlots.isNotEmpty) ...[
          Text(
            'Available Slots',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.green[700],
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: availableSlots.map((slot) {
              final isSelected = _selectedTime == slot.time;
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedTime = slot.time;
                  });
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? ColorConstant.lightRed
                        : Colors.green[50],
                    border: Border.all(
                      color: isSelected
                          ? ColorConstant.lightRed
                          : Colors.green[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    slot.time,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.green[800],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
        if (availableSlots.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'No available time slots for this date',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        // Booked slots (for reference)
        if (bookedSlots.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Booked Slots',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: bookedSlots.map((slot) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  border: Border.all(color: Colors.grey[400]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  slot.time,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildRescheduleButton(bool isFilipino) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _rescheduleAppointment,
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorConstant.lightRed,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          isFilipino ? 'I-reschedule ang Appointment' : 'Reschedule Appointment',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(bool isFilipino) {
    return Card(
      elevation: 1,
      color: Colors.orange[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                const SizedBox(width: 8),
                Text(
                  isFilipino ? 'Paalala' : 'Important Note',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isFilipino
                  ? '• Hindi pwedeng mag-reschedule ng mas mababa sa 2 oras bago ang appointment\n'
                      '• Minimum 2 oras pagitan ng mga appointments\n'
                      '• Ang appointment status ay babalik sa "Pending" pagkatapos i-reschedule'
                  : '• Cannot reschedule less than 2 hours before appointment\n'
                      '• Minimum 2 hours gap between appointments\n'
                      '• Appointment status will reset to "Pending" after reschedule',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange[700],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
