import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:juan_heart/core/app_exports.dart';
import 'package:juan_heart/models/appointment_model.dart';
import 'package:juan_heart/routes/app_routes.dart';
import 'package:juan_heart/services/appointment_service.dart';
import 'package:juan_heart/presentation/pages/home/book_appointment_screen.dart';
import 'package:juan_heart/presentation/pages/home/reschedule_appointment_dialog.dart';
import 'package:juan_heart/presentation/pages/teleconsult/pre_consultation_screen.dart';
import 'package:juan_heart/presentation/pages/teleconsult/waiting_room_screen.dart';
import 'package:intl/intl.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  List<Appointment> _appointments = [];
  bool _isLoading = true;
  String _filterStatus = 'all'; // all, upcoming, completed

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  // Public method to allow external refresh
  void refreshAppointments() {
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() => _isLoading = true);

    try {
      final appointments = await AppointmentService.getAppointments();

      setState(() {
        _appointments = appointments;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading appointments: $e');
      setState(() => _isLoading = false);
    }
  }

  List<Appointment> get _filteredAppointments {
    switch (_filterStatus) {
      case 'upcoming':
        return _appointments.where((apt) => apt.isUpcoming).toList();
      case 'completed':
        return _appointments
            .where((apt) => apt.status == AppointmentStatus.completed)
            .toList();
      default:
        return _appointments;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstant.whiteBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildFilterTabs(),
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : _appointments.isEmpty
                      ? _buildEmptyState()
                      : _buildAppointmentsList(),
            ),
          ],
        ),
      ),
      // FAB removed - booking now integrated into post-assessment flow
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                Get.locale?.languageCode == 'fil'
                    ? 'Mga Appointment'
                    : 'Appointments',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                Get.locale?.languageCode == 'fil'
                    ? 'Pamahalaan ang inyong mga appointment'
                    : 'Manage your appointments',
                style: TextStyle(
                  fontSize: 14,
                  color: ColorConstant.gentleGray,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () {
              // TODO: Show appointment history or settings
            },
            icon: Icon(
              Icons.history,
              color: ColorConstant.trustBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
      child: Row(
        children: [
          _buildFilterChip('all', Get.locale?.languageCode == 'fil' ? 'Lahat' : 'All'),
          const SizedBox(width: 8),
          _buildFilterChip('upcoming', Get.locale?.languageCode == 'fil' ? 'Paparating' : 'Upcoming'),
          const SizedBox(width: 8),
          _buildFilterChip('completed', Get.locale?.languageCode == 'fil' ? 'Tapos Na' : 'Completed'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String status, String label) {
    final isSelected = _filterStatus == status;
    return GestureDetector(
      onTap: () {
        setState(() => _filterStatus = status);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? ColorConstant.trustBlue
              : ColorConstant.softWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? ColorConstant.trustBlue
                : ColorConstant.cardBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : ColorConstant.gentleGray,
            fontFamily: 'Poppins',
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: CircularProgressIndicator(
        color: ColorConstant.trustBlue,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 80,
              color: ColorConstant.lightRed,
            ),
            const SizedBox(height: 24),
            Text(
              Get.locale?.languageCode == 'fil'
                  ? 'Wala Pa Kayong Appointment'
                  : 'No Appointments Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: ColorConstant.bluedark,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              Get.locale?.languageCode == 'fil'
                  ? 'Magsimula sa isang Heart Risk Assessment upang malaman kung kailangan mo ng appointment'
                  : 'Start with a Heart Risk Assessment to see if you need an appointment',
              style: TextStyle(
                fontSize: 14,
                color: ColorConstant.gentleGray,
                fontFamily: 'Poppins',
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to assessment screen
                Get.toNamed(AppRoutes.medicalTriageAssessmentScreen);
              },
              icon: const Icon(Icons.monitor_heart),
              label: Text(
                Get.locale?.languageCode == 'fil'
                    ? 'Magsimula ng Assessment'
                    : 'Start Assessment',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConstant.lightRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentsList() {
    final appointments = _filteredAppointments;

    if (appointments.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadAppointments,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
        itemCount: appointments.length,
        itemBuilder: (context, index) {
          return _buildAppointmentCard(appointments[index]);
        },
      ),
    );
  }

  Widget _buildAppointmentCard(Appointment appointment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ColorConstant.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: appointment.getStatusColor().withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  appointment.getStatusIcon(),
                  size: 16,
                  color: appointment.getStatusColor(),
                ),
                const SizedBox(width: 8),
                Text(
                  appointment.getStatusText(Get.locale?.languageCode ?? 'en'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: appointment.getStatusColor(),
                    fontFamily: 'Poppins',
                  ),
                ),
                const Spacer(),
                if (appointment.isToday)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: ColorConstant.lightRed,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      Get.locale?.languageCode == 'fil' ? 'NGAYON' : 'TODAY',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                if (appointment.isToday && appointment.syncStatus != null)
                  const SizedBox(width: 8),
                // Sync status indicator
                if (appointment.syncStatus != null)
                  _buildSyncStatusBadge(appointment),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.local_hospital,
                      color: ColorConstant.trustBlue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        appointment.facilityName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: ColorConstant.bluedark,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.person,
                      color: ColorConstant.gentleGray,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      appointment.doctorName,
                      style: TextStyle(
                        fontSize: 14,
                        color: ColorConstant.gentleGray,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: ColorConstant.trustBlue,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('MMMM dd, yyyy').format(appointment.appointmentDate),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: ColorConstant.bluedark,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.access_time,
                      color: ColorConstant.trustBlue,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      appointment.appointmentTime,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: ColorConstant.bluedark,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
                if (appointment.notes != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ColorConstant.softWhite,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.notes,
                          size: 16,
                          color: ColorConstant.gentleGray,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            appointment.notes!,
                            style: TextStyle(
                              fontSize: 12,
                              color: ColorConstant.gentleGray,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Questionnaire status badge (for upcoming appointments)
          if (appointment.isUpcoming) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: appointment.getQuestionnaireStatusColor().withOpacity(0.1),
                border: Border(
                  top: BorderSide(color: ColorConstant.cardBorder),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    appointment.hasCompletedQuestionnaire
                        ? Icons.check_circle
                        : Icons.assignment,
                    size: 16,
                    color: appointment.getQuestionnaireStatusColor(),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    Get.locale?.languageCode == 'fil'
                        ? 'Pre-consultation: ${appointment.getQuestionnaireStatusText('fil')}'
                        : 'Pre-consultation: ${appointment.getQuestionnaireStatusText('en')}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: appointment.getQuestionnaireStatusColor(),
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Pre-consultation and waiting room buttons
          if (appointment.needsQuestionnaire || appointment.canJoinWaitingRoom())
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ColorConstant.softWhite,
                border: Border(
                  top: BorderSide(color: ColorConstant.cardBorder),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Fill Questionnaire button
                  if (appointment.needsQuestionnaire)
                    ElevatedButton.icon(
                      onPressed: () => _fillQuestionnaire(appointment),
                      icon: const Icon(Icons.assignment, size: 18),
                      label: Text(
                        Get.locale?.languageCode == 'fil'
                            ? 'Sagutan ang Form'
                            : 'Fill Questionnaire',
                        style: const TextStyle(fontFamily: 'Poppins'),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorConstant.trustBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),

                  // Join Waiting Room button
                  if (appointment.canJoinWaitingRoom()) ...[
                    if (appointment.needsQuestionnaire) const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () => _joinWaitingRoom(appointment),
                      icon: const Icon(Icons.video_call, size: 18),
                      label: Text(
                        Get.locale?.languageCode == 'fil'
                            ? 'Sumali sa Waiting Room'
                            : 'Join Waiting Room',
                        style: const TextStyle(fontFamily: 'Poppins'),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorConstant.lightRed,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ],
                ],
              ),
            ),

          // Action buttons (Cancel/Reschedule)
          if (appointment.status == AppointmentStatus.pending ||
              appointment.status == AppointmentStatus.confirmed)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ColorConstant.softWhite,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                border: Border(
                  top: BorderSide(color: ColorConstant.cardBorder),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _showCancelDialog(appointment);
                      },
                      icon: const Icon(Icons.cancel, size: 18),
                      label: Text(
                        Get.locale?.languageCode == 'fil' ? 'Kanselahin' : 'Cancel',
                        style: const TextStyle(fontFamily: 'Poppins'),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ColorConstant.lightRed,
                        side: BorderSide(color: ColorConstant.lightRed),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _showRescheduleDialog(appointment);
                      },
                      icon: const Icon(Icons.edit_calendar, size: 18),
                      label: Text(
                        Get.locale?.languageCode == 'fil' ? 'I-reschedule' : 'Reschedule',
                        style: const TextStyle(fontFamily: 'Poppins'),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorConstant.trustBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }


  void _showCancelDialog(Appointment appointment) {
    Get.dialog(
      AlertDialog(
        title: Text(
          Get.locale?.languageCode == 'fil'
              ? 'Kanselahin ang Appointment?'
              : 'Cancel Appointment?',
          style: const TextStyle(fontFamily: 'Poppins'),
        ),
        content: Text(
          Get.locale?.languageCode == 'fil'
              ? 'Sigurado ka bang gusto mong kanselahin ang appointment na ito?'
              : 'Are you sure you want to cancel this appointment?',
          style: const TextStyle(fontFamily: 'Poppins'),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              Get.locale?.languageCode == 'fil' ? 'Hindi' : 'No',
              style: const TextStyle(fontFamily: 'Poppins'),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();

              // Show loading
              Get.dialog(
                Center(child: CircularProgressIndicator()),
                barrierDismissible: false,
              );

              // Cancel appointment
              final success = await AppointmentService.cancelAppointment(
                appointment.id,
                reason: 'User cancelled',
              );

              Get.back(); // Close loading

              if (success) {
                // Reload appointments
                _loadAppointments();

                Get.snackbar(
                  Get.locale?.languageCode == 'fil' ? 'Kanselado' : 'Cancelled',
                  Get.locale?.languageCode == 'fil'
                      ? 'Ang appointment ay kanselado na'
                      : 'Appointment has been cancelled',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: ColorConstant.lightRed,
                  colorText: Colors.white,
                  margin: const EdgeInsets.all(16),
                  borderRadius: 12,
                );
              } else {
                Get.snackbar(
                  Get.locale?.languageCode == 'fil' ? 'Error' : 'Error',
                  Get.locale?.languageCode == 'fil'
                      ? 'Hindi makansela ang appointment'
                      : 'Failed to cancel appointment',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                  margin: const EdgeInsets.all(16),
                  borderRadius: 12,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorConstant.lightRed,
            ),
            child: Text(
              Get.locale?.languageCode == 'fil' ? 'Oo, Kanselahin' : 'Yes, Cancel',
              style: const TextStyle(fontFamily: 'Poppins'),
            ),
          ),
        ],
      ),
    );
  }

  void _showRescheduleDialog(Appointment appointment) async {
    final result = await Get.to(() => RescheduleAppointmentDialog(
          appointment: appointment,
        ));

    if (result == true) {
      // Refresh appointments list after successful reschedule
      _loadAppointments();
    }
  }

  /// Navigate to pre-consultation questionnaire screen
  void _fillQuestionnaire(Appointment appointment) async {
    final result = await Get.to(() => PreConsultationScreen(
          appointment: appointment,
        ));

    if (result == true) {
      // Questionnaire was submitted, update appointment status
      try {
        final updatedAppointment = appointment.copyWith(
          questionnaireStatus: 'submitted',
        );
        await AppointmentService.updateAppointment(updatedAppointment);

        Get.snackbar(
          Get.locale?.languageCode == 'fil' ? 'Tagumpay!' : 'Success!',
          Get.locale?.languageCode == 'fil'
              ? 'Naisumite na ang pre-consultation form'
              : 'Pre-consultation form submitted successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: ColorConstant.trustBlue,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
        );

        // Refresh appointments list
        _loadAppointments();
      } catch (e) {
        print('Error updating questionnaire status: $e');
      }
    } else if (result == false) {
      // Questionnaire was saved as draft
      try {
        final updatedAppointment = appointment.copyWith(
          questionnaireStatus: 'draft',
        );
        await AppointmentService.updateAppointment(updatedAppointment);

        // Refresh appointments list
        _loadAppointments();
      } catch (e) {
        print('Error updating questionnaire status: $e');
      }
    }
  }

  /// Build sync status badge
  Widget _buildSyncStatusBadge(Appointment appointment) {
    final isFilipino = Get.locale?.languageCode == 'fil';

    IconData icon;
    Color backgroundColor;
    Color textColor;
    String label;

    switch (appointment.syncStatus) {
      case 'synced':
        icon = Icons.cloud_done;
        backgroundColor = const Color(0xFF4CAF50); // Green
        textColor = Colors.white;
        label = isFilipino ? 'Naka-sync' : 'Synced';
        break;
      case 'pending':
        icon = Icons.cloud_upload;
        backgroundColor = const Color(0xFFFFA500); // Orange
        textColor = Colors.white;
        label = isFilipino ? 'Nag-sync' : 'Syncing';
        break;
      case 'failed':
        icon = Icons.cloud_off;
        backgroundColor = const Color(0xFFF44336); // Red
        textColor = Colors.white;
        label = isFilipino ? 'Hindi nag-sync' : 'Failed';
        break;
      default:
        // Unknown status - show as pending
        icon = Icons.cloud_queue;
        backgroundColor = Colors.grey;
        textColor = Colors.white;
        label = isFilipino ? 'Naghihintay' : 'Waiting';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: textColor,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: textColor,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  /// Navigate to waiting room screen
  void _joinWaitingRoom(Appointment appointment) {
    // Check if questionnaire is completed
    if (!appointment.hasCompletedQuestionnaire) {
      Get.dialog(
        AlertDialog(
          title: Text(
            Get.locale?.languageCode == 'fil'
                ? 'Punan Muna ang Form'
                : 'Complete Questionnaire First',
            style: const TextStyle(fontFamily: 'Poppins'),
          ),
          content: Text(
            Get.locale?.languageCode == 'fil'
                ? 'Kailangan mong sagutan muna ang pre-consultation form bago sumali sa waiting room.'
                : 'Please complete the pre-consultation questionnaire before joining the waiting room.',
            style: const TextStyle(fontFamily: 'Poppins'),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text(
                Get.locale?.languageCode == 'fil' ? 'Kanselahin' : 'Cancel',
                style: const TextStyle(fontFamily: 'Poppins'),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Get.back();
                _fillQuestionnaire(appointment);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConstant.trustBlue,
              ),
              child: Text(
                Get.locale?.languageCode == 'fil' ? 'Sagutan Ngayon' : 'Fill Now',
                style: const TextStyle(fontFamily: 'Poppins'),
              ),
            ),
          ],
        ),
      );
      return;
    }

    // Navigate to waiting room
    Get.to(() => WaitingRoomScreen(appointment: appointment));
  }
}
