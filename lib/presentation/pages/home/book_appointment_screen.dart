import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:juan_heart/core/app_exports.dart';
import 'package:juan_heart/models/appointment_model.dart';
import 'package:juan_heart/models/referral_data.dart';
import 'package:juan_heart/routes/app_routes.dart';
import 'package:juan_heart/services/appointment_service.dart';
import 'package:juan_heart/services/appointment_validation_service.dart';
import 'package:juan_heart/services/pdf_report_service.dart';
import 'package:juan_heart/presentation/pages/home/facility_selection_screen.dart';
import 'package:uuid/uuid.dart';

class BookAppointmentScreen extends StatefulWidget {
  const BookAppointmentScreen({Key? key}) : super(key: key);

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();

  // Form controllers
  final _facilityNameController = TextEditingController();
  final _doctorNameController = TextEditingController();
  final _patientNameController = TextEditingController();
  final _patientPhoneController = TextEditingController();
  final _notesController = TextEditingController();

  // Form values
  DateTime _selectedDate = DateTime.now();
  String? _selectedTime;
  AppointmentType _selectedType = AppointmentType.consultation;
  List<TimeSlot> _availableSlots = [];
  bool _isLoadingSlots = false;

  // Selected facility (user must select before booking)
  HealthcareFacility? _selectedFacility;

  // NEW: Assessment-driven booking
  bool _fromAssessment = false;
  Map<String, dynamic>? _assessmentData;
  CareRecommendation? _recommendation;

  @override
  void initState() {
    super.initState();
    _loadArguments();
  }

  /// NEW: Load arguments if coming from assessment flow
  void _loadArguments() {
    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null) {
      _fromAssessment = args['fromAssessment'] as bool? ?? false;
      _assessmentData = args['assessmentData'] as Map<String, dynamic>?;
      _recommendation = args['recommendation'] as CareRecommendation?;

      // Pre-populate facility if provided
      final facility = args['selectedFacility'] as HealthcareFacility?;
      if (facility != null) {
        _selectedFacility = facility;
        _facilityNameController.text = facility.name;
        // Load available slots for this facility
        _loadAvailableSlots();
      }
    }
  }

  @override
  void dispose() {
    _facilityNameController.dispose();
    _doctorNameController.dispose();
    _patientNameController.dispose();
    _patientPhoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectFacility() async {
    final isFilipino = Get.locale?.languageCode == 'fil';

    final facility = await Get.to(() => const FacilitySelectionScreen());

    if (facility != null && facility is HealthcareFacility) {
      setState(() {
        _selectedFacility = facility;
        _facilityNameController.text = facility.name;
      });

      // Load available slots for this facility
      await _loadAvailableSlots();

      Get.snackbar(
        isFilipino ? 'Napili!' : 'Selected!',
        isFilipino
            ? 'Facility: ${facility.name}'
            : 'Facility: ${facility.name}',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    }
  }

  Future<void> _loadAvailableSlots() async {
    if (_selectedFacility == null) return;

    setState(() => _isLoadingSlots = true);

    try {
      final slots = await AppointmentService.getAvailableTimeSlots(
        _selectedFacility!.id,
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
    final now = DateTime.now();
    final maxDate = now.add(const Duration(days: 90));

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: now,
      lastDate: maxDate,
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

  Future<void> _bookAppointment() async {
    final isFilipino = Get.locale?.languageCode == 'fil';

    // Check if facility is selected
    if (_selectedFacility == null) {
      Get.snackbar(
        isFilipino ? 'Error' : 'Error',
        isFilipino
            ? 'Pumili muna ng facility'
            : 'Please select a facility first',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

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
      // Validate booking
      final validationError =
          await AppointmentValidationService.validateBooking(
        facilityId: _selectedFacility!.id,
        appointmentDate: _selectedDate,
        appointmentTime: _selectedTime!,
        doctorName: _doctorNameController.text.trim(),
        appointmentType: _selectedType,
      );

      if (validationError != null) {
        Get.back(); // Close loading dialog
        Get.snackbar(
          'Validation Error',
          validationError,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 4),
        );
        return;
      }

      // Validate appointment data
      final dataError =
          AppointmentValidationService.validateAppointmentData(
        facilityId: _selectedFacility!.id,
        facilityName: _facilityNameController.text.trim(),
        doctorName: _doctorNameController.text.trim(),
        appointmentDate: _selectedDate,
        appointmentTime: _selectedTime!,
        type: _selectedType,
        patientName: _patientNameController.text.trim(),
        patientPhone: _patientPhoneController.text.trim(),
      );

      if (dataError != null) {
        Get.back(); // Close loading dialog
        Get.snackbar(
          'Validation Error',
          dataError,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      // Create appointment with assessment data if available
      final appointment = Appointment(
        id: _uuid.v4(),
        facilityId: _selectedFacility!.id,
        facilityName: _selectedFacility!.name,
        doctorName: _doctorNameController.text.trim(),
        appointmentDate: _selectedDate,
        appointmentTime: _selectedTime!,
        status: AppointmentStatus.pending,
        type: _selectedType,
        patientName: _patientNameController.text.trim().isNotEmpty
            ? _patientNameController.text.trim()
            : null,
        contactNumber: _patientPhoneController.text.trim().isNotEmpty
            ? _patientPhoneController.text.trim()
            : null,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        // NEW: Include assessment data if coming from assessment flow
        assessmentId: _fromAssessment && _assessmentData != null
            ? _assessmentData!['id'] as String?
            : null,
        riskScore: _fromAssessment && _recommendation != null
            ? _recommendation!.riskScore
            : null,
        riskCategory: _fromAssessment && _recommendation != null
            ? _recommendation!.riskCategory
            : null,
        assessmentData: _fromAssessment ? _assessmentData : null,
      );

      // Save appointment
      final success = await AppointmentService.saveAppointment(appointment);

      Get.back(); // Close loading dialog

      if (success) {
        // Navigate to Appointments tab with success data
        Get.offAllNamed(
          AppRoutes.home,
          arguments: {
            'initialTab': 2,
            'showSuccessDialog': true,
            'appointmentData': {
              'facilityName': _selectedFacility!.name,
              'date': DateFormat.yMMMd().format(appointment.appointmentDate),
              'time': appointment.appointmentTime,
              'type': appointment.type.toString().split('.').last,
              'hasAssessment': _fromAssessment,
            },
          },
        );
      } else {
        Get.snackbar(
          'Error',
          'Failed to book appointment. Please try again.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.back(); // Close loading dialog
      print('Error booking appointment: $e');
      Get.snackbar(
        'Error',
        'An unexpected error occurred. Please try again.',
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
          icon: Icon(Icons.arrow_back, color: ColorConstant.bluedark),
          onPressed: () => Get.back(),
        ),
        title: Text(
          isFilipino ? 'Mag-book ng Appointment' : 'Book Appointment',
          style: TextStyle(
            color: ColorConstant.bluedark,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Facility Selection Card (Step 1)
            _buildFacilitySelectionCard(isFilipino),
            const SizedBox(height: 16),

            // Assessment Summary (if from assessment flow)
            if (_fromAssessment && _recommendation != null) ...[
              _buildAssessmentSummaryCard(isFilipino),
              const SizedBox(height: 16),
            ],

            // Date Selection Card (Step 2)
            _buildDateSelectionCard(isFilipino),
            const SizedBox(height: 16),

            // Time Slot Selection
            _buildTimeSlotSection(isFilipino),
            const SizedBox(height: 16),

            // Appointment Type
            _buildAppointmentTypeCard(isFilipino),
            const SizedBox(height: 16),

            // Facility Information
            _buildFacilityInfoCard(isFilipino),
            const SizedBox(height: 16),

            // Patient Information (Optional)
            _buildPatientInfoCard(isFilipino),
            const SizedBox(height: 16),

            // Additional Notes
            _buildNotesCard(isFilipino),
            const SizedBox(height: 24),

            // Book Button
            _buildBookButton(isFilipino),
            const SizedBox(height: 16),

            // Validation Rules Info
            _buildValidationInfo(isFilipino),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildFacilitySelectionCard(bool isFilipino) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  isFilipino ? 'Pumili ng Pasilidad' : 'Select Facility',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                    color: ColorConstant.bluedark,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: ColorConstant.lightRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isFilipino ? 'HAKBANG 1' : 'STEP 1',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: ColorConstant.lightRed,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _fromAssessment ? null : _selectFacility, // Disable selection if from assessment
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _selectedFacility != null
                        ? ColorConstant.lightRed
                        : Colors.grey[300]!,
                    width: _selectedFacility != null ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  color: _selectedFacility != null
                      ? ColorConstant.lightRed.withOpacity(0.05)
                      : Colors.transparent,
                ),
                child: _selectedFacility == null
                    ? Row(
                        children: [
                          Icon(Icons.local_hospital,
                              color: Colors.grey[600], size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              isFilipino
                                  ? 'Pindutin para pumili ng healthcare facility'
                                  : 'Tap to select a healthcare facility',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios,
                              size: 16, color: Colors.grey[600]),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: ColorConstant.lightRed.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  _selectedFacility!.typeIcon,
                                  color: ColorConstant.lightRed,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selectedFacility!.name,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'Poppins',
                                        color: ColorConstant.bluedark,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _selectedFacility!.typeName,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.check_circle,
                                  color: ColorConstant.lightRed, size: 24),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.location_on,
                                  size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  _selectedFacility!.address,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          if (_selectedFacility!.distanceKm != null) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.directions_car,
                                    size: 14, color: ColorConstant.lightRed),
                                const SizedBox(width: 4),
                                Text(
                                  _selectedFacility!.distanceText,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: ColorConstant.lightRed,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 12),
                          // Show different message based on whether facility can be changed
                          Row(
                            children: [
                              Icon(
                                _fromAssessment ? Icons.lock : Icons.edit,
                                size: 12,
                                color: _fromAssessment ? Colors.grey[600] : ColorConstant.lightRed,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _fromAssessment
                                    ? (isFilipino
                                        ? 'Pre-selected mula sa assessment'
                                        : 'Pre-selected from assessment')
                                    : (isFilipino
                                        ? 'Pindutin para magpalit ng facility'
                                        : 'Tap to change facility'),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _fromAssessment ? Colors.grey[600] : ColorConstant.lightRed,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
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
            Row(
              children: [
                Text(
                  isFilipino ? 'Pumili ng Petsa' : 'Select Date',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                    color: ColorConstant.bluedark,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: ColorConstant.lightRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isFilipino ? 'HAKBANG 2' : 'STEP 2',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: ColorConstant.lightRed,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _selectDate,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
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
            Row(
              children: [
                Text(
                  isFilipino ? 'Pumili ng Oras' : 'Select Time',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                    color: ColorConstant.bluedark,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: ColorConstant.lightRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isFilipino ? 'HAKBANG 3' : 'STEP 3',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: ColorConstant.lightRed,
                    ),
                  ),
                ),
              ],
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
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
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

  Widget _buildAppointmentTypeCard(bool isFilipino) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isFilipino ? 'Uri ng Appointment' : 'Appointment Type',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
                color: ColorConstant.bluedark,
              ),
            ),
            const SizedBox(height: 12),
            ...AppointmentType.values.map((type) {
              return RadioListTile<AppointmentType>(
                title: Text(
                  Appointment(
                    id: '',
                    facilityId: '',
                    facilityName: '',
                    doctorName: '',
                    appointmentDate: DateTime.now(),
                    appointmentTime: '',
                    status: AppointmentStatus.pending,
                    type: type,
                  ).getTypeText(isFilipino ? 'fil' : 'en'),
                  style: const TextStyle(fontSize: 14),
                ),
                value: type,
                groupValue: _selectedType,
                activeColor: ColorConstant.lightRed,
                onChanged: (AppointmentType? value) {
                  if (value != null) {
                    setState(() {
                      _selectedType = value;
                    });
                  }
                },
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildFacilityInfoCard(bool isFilipino) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isFilipino ? 'Impormasyon ng Pasilidad' : 'Facility Information',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
                color: ColorConstant.bluedark,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _facilityNameController,
              decoration: InputDecoration(
                labelText: isFilipino ? 'Pangalan ng Pasilidad' : 'Facility Name',
                hintText: isFilipino
                    ? 'e.g., Philippine Heart Center'
                    : 'e.g., Philippine Heart Center',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.local_hospital),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return isFilipino
                      ? 'Kailangan ang pangalan ng pasilidad'
                      : 'Facility name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _doctorNameController,
              decoration: InputDecoration(
                labelText: isFilipino ? 'Pangalan ng Doktor' : 'Doctor Name',
                hintText: isFilipino ? 'e.g., Dr. Juan Cruz' : 'e.g., Dr. Juan Cruz',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return isFilipino
                      ? 'Kailangan ang pangalan ng doktor'
                      : 'Doctor name is required';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientInfoCard(bool isFilipino) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isFilipino
                  ? 'Impormasyon ng Pasyente (Opsyonal)'
                  : 'Patient Information (Optional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
                color: ColorConstant.bluedark,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _patientNameController,
              decoration: InputDecoration(
                labelText: isFilipino ? 'Pangalan ng Pasyente' : 'Patient Name',
                hintText: isFilipino ? 'e.g., Juan Dela Cruz' : 'e.g., Juan Dela Cruz',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _patientPhoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText:
                    isFilipino ? 'Numero ng Telepono' : 'Phone Number',
                hintText: '+639XXXXXXXXX or 09XXXXXXXXX',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.phone),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesCard(bool isFilipino) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isFilipino ? 'Karagdagang Tala' : 'Additional Notes',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
                color: ColorConstant.bluedark,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: isFilipino
                    ? 'Isulat ang anumang karagdagang impormasyon...'
                    : 'Enter any additional information...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookButton(bool isFilipino) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _bookAppointment,
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorConstant.lightRed,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          isFilipino ? 'Mag-book ng Appointment' : 'Book Appointment',
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

  Widget _buildValidationInfo(bool isFilipino) {
    return Card(
      elevation: 1,
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
                  isFilipino ? 'Mga Patakaran sa Booking' : 'Booking Rules',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isFilipino
                  ? '• Maaaring mag-book hanggang 90 araw\n'
                      '• Maksimum 3 appointments kada araw\n'
                      '• Minimum 2 oras pagitan ng appointments\n'
                      '• Emergency: Ngayon o bukas lamang\n'
                      '• Cancellation: 2 oras bago ang appointment'
                  : '• Book up to 90 days in advance\n'
                      '• Maximum 3 appointments per day\n'
                      '• Minimum 2 hours between appointments\n'
                      '• Emergency: Today or tomorrow only\n'
                      '• Cancellation: 2 hours before appointment',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue[700],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// NEW: Assessment Summary Card (shown when booking from assessment flow)
  Widget _buildAssessmentSummaryCard(bool isFilipino) {
    if (_recommendation == null) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              _recommendation!.indicatorColor.withOpacity(0.1),
              _recommendation!.indicatorColor.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.favorite,
                    color: _recommendation!.indicatorColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isFilipino ? 'Resulta ng Assessment' : 'Assessment Result',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                      color: ColorConstant.bluedark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _recommendation!.indicatorColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _recommendation!.indicatorColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _recommendation!.riskCategory.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${isFilipino ? "Marka" : "Score"}: ${_recommendation!.riskScore}/100',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: ColorConstant.bluedark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _recommendation!.actionTitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[800],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.info_outline, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      isFilipino
                          ? 'Ang inyong assessment data ay ikakabit sa appointment na ito'
                          : 'Your assessment data will be attached to this appointment',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[700],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
