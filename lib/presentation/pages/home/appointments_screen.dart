import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:juan_heart/core/app_exports.dart';
import 'package:juan_heart/models/appointment_model.dart';
import 'package:juan_heart/routes/app_routes.dart';
import 'package:juan_heart/services/appointment_service.dart';
import 'package:juan_heart/services/appointment_history_pdf_service.dart';
import 'package:juan_heart/services/sync_queue_service.dart';
import 'package:juan_heart/presentation/pages/home/reschedule_appointment_dialog.dart';
import 'package:juan_heart/presentation/pages/teleconsult/pre_consultation_screen.dart';
import 'package:juan_heart/presentation/pages/teleconsult/waiting_room_screen.dart';
import 'package:juan_heart/presentation/widgets/standard_card.dart';
import 'package:juan_heart/presentation/widgets/standard_button.dart';
import 'package:juan_heart/presentation/pages/home/home.dart';
import 'package:juan_heart/presentation/widgets/date_range_selector.dart';
import 'package:juan_heart/themes/jh_text_styles.dart';
import 'package:juan_heart/themes/jh_colors.dart';
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

  /// Check if there are any failed syncs
  bool get _hasFailedSyncs {
    return _appointments.any((apt) => apt.syncStatus == 'failed');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstant.whiteBackground,
      appBar: AppBar(
        backgroundColor: ColorConstant.whiteBackground,
        automaticallyImplyLeading: false,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              Get.to(() => const AppointmentHistoryView());
            },
            icon: Icon(
              Icons.history,
              color: ColorConstant.trustBlue,
            ),
          ),
        ],
        title: Text(
          Get.locale?.languageCode == 'fil'
              ? 'Mga Appointment'
              : 'Appointments',
          style: JHTextStyles.h4.copyWith(
            color: ColorConstant.bluedark,
          ),
        ),
      ),
      body: Column(
        children: [
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
      floatingActionButton: _hasFailedSyncs ? _buildRetryFAB() : null,
    );
  }

  /// Build Floating Action Button for retrying failed syncs
  Widget _buildRetryFAB() {
    final isFilipino = Get.locale?.languageCode == 'fil';

    return SafeArea(
      child: FloatingActionButton.extended(
        onPressed: _retryFailedSyncs,
        backgroundColor: Colors.orange[600],
        icon: const Icon(Icons.refresh, color: Colors.white),
        label: Text(
          isFilipino ? 'I-retry ang mga Failed Syncs' : 'Retry Failed Syncs',
          style: JHTextStyles.bodySmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// Retry all failed sync operations
  Future<void> _retryFailedSyncs() async {
    final isFilipino = Get.locale?.languageCode == 'fil';

    // Show loading dialog
    Get.dialog(
      WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                isFilipino
                    ? 'Muling sinusubukan ang failed syncs...'
                    : 'Retrying failed syncs...',
                style: JHTextStyles.bodySmall,
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );

    try {
      // Retry failed operations
      await SyncQueueService().retryFailedOperations();

      // Wait a bit for sync to process
      await Future.delayed(const Duration(seconds: 2));

      // Refresh appointments list
      await _loadAppointments();

      // Close loading dialog
      Get.back();

      // Show success message
      Get.snackbar(
        isFilipino ? 'Tagumpay!' : 'Success!',
        isFilipino
            ? 'Mga failed syncs ay muling sinubukan. Pakicheck ang sync status.'
            : 'Failed syncs have been retried. Check sync status for updates.',
        backgroundColor: Colors.green[600],
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      // Close loading dialog
      Get.back();

      // Show error message
      Get.snackbar(
        isFilipino ? 'Error' : 'Error',
        isFilipino
            ? 'Hindi ma-retry ang failed syncs: $e'
            : 'Failed to retry syncs: $e',
        backgroundColor: Colors.red[600],
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
    }
  }

  Widget _buildFilterTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
      child: Row(
        children: [
          _buildFilterChip(
              'all', Get.locale?.languageCode == 'fil' ? 'Lahat' : 'All'),
          const SizedBox(width: 8),
          _buildFilterChip('upcoming',
              Get.locale?.languageCode == 'fil' ? 'Paparating' : 'Upcoming'),
          const SizedBox(width: 8),
          _buildFilterChip('completed',
              Get.locale?.languageCode == 'fil' ? 'Tapos Na' : 'Completed'),
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
          color: isSelected ? ColorConstant.trustBlue : ColorConstant.softWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isSelected ? ColorConstant.trustBlue : ColorConstant.cardBorder,
          ),
        ),
        child: Text(
          label,
          style: JHTextStyles.bodySmall.copyWith(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : ColorConstant.gentleGray,
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
              style: JHTextStyles.h4.copyWith(
                color: ColorConstant.bluedark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              Get.locale?.languageCode == 'fil'
                  ? 'Magsimula sa isang Heart Risk Assessment upang malaman kung kailangan mo ng appointment'
                  : 'Start with a Heart Risk Assessment to see if you need an appointment',
              style: JHTextStyles.bodySmall.copyWith(
                color: ColorConstant.gentleGray,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            StandardButton.primary(
              text: Get.locale?.languageCode == 'fil'
                  ? 'Magsimula ng Assessment'
                  : 'Start Assessment',
              onPressed: () {
                showCustomDialog(
                  context,
                  targetRoute: AppRoutes.medicalTriageAssessmentScreen,
                );
              },
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
    return StandardCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: appointment.getStatusColor().withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
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
                  style: JHTextStyles.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    color: appointment.getStatusColor(),
                  ),
                ),
                const Spacer(),
                if (appointment.isToday)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: ColorConstant.lightRed,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      Get.locale?.languageCode == 'fil' ? 'NGAYON' : 'TODAY',
                      style: JHTextStyles.label.copyWith(
                        color: Colors.white,
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
                        style: JHTextStyles.h5.copyWith(
                          color: ColorConstant.bluedark,
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
                      style: JHTextStyles.bodySmall.copyWith(
                        color: ColorConstant.gentleGray,
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
                      DateFormat('MMMM dd, yyyy')
                          .format(appointment.appointmentDate),
                      style: JHTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: ColorConstant.bluedark,
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
                      style: JHTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: ColorConstant.bluedark,
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
                            style: JHTextStyles.caption.copyWith(
                              color: ColorConstant.gentleGray,
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
                color: appointment
                    .getQuestionnaireStatusColor()
                    .withValues(alpha: 0.1),
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
                    style: JHTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: appointment.getQuestionnaireStatusColor(),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Pre-consultation and waiting room buttons
          if (appointment.needsQuestionnaire ||
              appointment.canJoinWaitingRoom())
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
                    StandardButton.secondary(
                      text: Get.locale?.languageCode == 'fil'
                          ? 'Sagutan ang Form'
                          : 'Fill Questionnaire',
                      onPressed: () => _fillQuestionnaire(appointment),
                    ),

                  // Join Waiting Room button
                  if (appointment.canJoinWaitingRoom()) ...[
                    if (appointment.needsQuestionnaire)
                      const SizedBox(height: 8),
                    StandardButton.primary(
                      text: Get.locale?.languageCode == 'fil'
                          ? 'Sumali sa Waiting Room'
                          : 'Join Waiting Room',
                      onPressed: () => _joinWaitingRoom(appointment),
                    ),
                  ],
                ],
              ),
            ),

          // Mark as Completed button (for today's or past appointments)
          if (_canMarkAsCompleted(appointment))
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ColorConstant.softWhite,
                border: Border(
                  top: BorderSide(color: ColorConstant.cardBorder),
                ),
              ),
              child: StandardButton.primary(
                text: Get.locale?.languageCode == 'fil'
                    ? 'Markahan bilang Tapos'
                    : 'Mark as Completed',
                onPressed: () => _markAsCompleted(appointment),
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
                  bottomLeft: Radius.circular(15),
                  bottomRight: Radius.circular(15),
                ),
                border: Border(
                  top: BorderSide(color: ColorConstant.cardBorder),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: StandardButton.outline(
                      text: Get.locale?.languageCode == 'fil'
                          ? 'Kanselahin'
                          : 'Cancel',
                      onPressed: () {
                        _showCancelDialog(appointment);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StandardButton.secondary(
                      text: Get.locale?.languageCode == 'fil'
                          ? 'I-reschedule'
                          : 'Reschedule',
                      onPressed: () {
                        _showRescheduleDialog(appointment);
                      },
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
          style: JHTextStyles.h5,
        ),
        content: Text(
          Get.locale?.languageCode == 'fil'
              ? 'Sigurado ka bang gusto mong kanselahin ang appointment na ito?'
              : 'Are you sure you want to cancel this appointment?',
          style: JHTextStyles.bodyBase,
        ),
        actions: [
          StandardButton.outline(
            text: Get.locale?.languageCode == 'fil' ? 'Hindi' : 'No',
            onPressed: () => Get.back(),
            width: 80,
          ),
          const SizedBox(width: 8),
          StandardButton.primary(
            text: Get.locale?.languageCode == 'fil'
                ? 'Oo, Kanselahin'
                : 'Yes, Cancel',
            onPressed: () async {
              Get.back();

              // Show loading
              Get.dialog(
                const Center(child: CircularProgressIndicator()),
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
            width: 150,
          ),
        ],
      ),
    );
  }

  /// Helper method to determine if appointment can be marked as completed
  bool _canMarkAsCompleted(Appointment appointment) {
    // Must not already be completed, cancelled, or no-show
    if (appointment.status == AppointmentStatus.completed ||
        appointment.status == AppointmentStatus.cancelled ||
        appointment.status == AppointmentStatus.noShow) {
      return false;
    }

    // Appointment date must have passed or be today
    final now = DateTime.now();
    final appointmentDateTime = appointment.appointmentDate;

    // Check if appointment date is today or in the past
    return appointmentDateTime.year <= now.year &&
        appointmentDateTime.month <= now.month &&
        appointmentDateTime.day <= now.day;
  }

  void _markAsCompleted(Appointment appointment) {
    Get.dialog(
      AlertDialog(
        title: Text(
          Get.locale?.languageCode == 'fil'
              ? 'Markahan bilang Tapos?'
              : 'Mark as Completed?',
          style: JHTextStyles.h5,
        ),
        content: Text(
          Get.locale?.languageCode == 'fil'
              ? 'Sigurado ka bang tapos na ang appointment na ito? Makakatanggap ka ng follow-up reminder pagkatapos ng 7 araw.'
              : 'Are you sure this appointment is completed? You will receive a follow-up reminder in 7 days.',
          style: JHTextStyles.bodyBase,
        ),
        actions: [
          StandardButton.outline(
            text: Get.locale?.languageCode == 'fil' ? 'Hindi' : 'No',
            onPressed: () => Get.back(),
            width: 80,
          ),
          const SizedBox(width: 8),
          StandardButton.primary(
            text: Get.locale?.languageCode == 'fil'
                ? 'Oo, Tapos na'
                : 'Yes, Completed',
            onPressed: () async {
              Get.back();

              // Show loading
              Get.dialog(
                const Center(child: CircularProgressIndicator()),
                barrierDismissible: false,
              );

              // Mark as completed
              final success =
                  await AppointmentService.markAsCompleted(appointment.id);

              Get.back(); // Close loading

              if (success) {
                // Reload appointments
                _loadAppointments();

                Get.snackbar(
                  Get.locale?.languageCode == 'fil' ? 'Tapos Na' : 'Completed',
                  Get.locale?.languageCode == 'fil'
                      ? 'Ang appointment ay natapos na. Makakatanggap ka ng follow-up reminder sa loob ng 7 araw.'
                      : 'Appointment marked as completed. You will receive a follow-up reminder in 7 days.',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: ColorConstant.reassuringGreen,
                  colorText: Colors.white,
                  margin: const EdgeInsets.all(16),
                  borderRadius: 12,
                  duration: const Duration(seconds: 4),
                );
              } else {
                Get.snackbar(
                  Get.locale?.languageCode == 'fil' ? 'Error' : 'Error',
                  Get.locale?.languageCode == 'fil'
                      ? 'Hindi ma-update ang appointment'
                      : 'Could not update appointment',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                  margin: const EdgeInsets.all(16),
                  borderRadius: 12,
                );
              }
            },
            width: 150,
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
        backgroundColor = JHColors.success; // Green
        textColor = Colors.white;
        label = isFilipino ? 'Naka-sync' : 'Synced';
        break;
      case 'pending':
        icon = Icons.cloud_upload;
        backgroundColor = JHColors.warning; // Orange
        textColor = Colors.white;
        label = isFilipino ? 'Nag-sync' : 'Syncing';
        break;
      case 'failed':
        icon = Icons.cloud_off;
        backgroundColor = JHColors.danger; // Red
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

    final badge = Container(
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
            style: JHTextStyles.label.copyWith(
              color: textColor,
            ),
          ),
        ],
      ),
    );

    // Make failed status tappable to show error details
    if (appointment.syncStatus == 'failed' &&
        appointment.syncErrorMessage != null) {
      return GestureDetector(
        onTap: () => _showSyncErrorDialog(appointment),
        child: badge,
      );
    }

    return badge;
  }

  /// Show dialog with sync error details
  void _showSyncErrorDialog(Appointment appointment) {
    final isFilipino = Get.locale?.languageCode == 'fil';

    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[700]),
            const SizedBox(width: 12),
            Text(
              isFilipino ? 'Detalye ng Error' : 'Sync Error Details',
              style: JHTextStyles.h5.copyWith(
                color: Colors.red[700],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isFilipino
                  ? 'Ang appointment na ito ay nabigo sa pag-sync sa backend:'
                  : 'This appointment failed to sync to the backend:',
              style: JHTextStyles.bodySmall,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 20, color: Colors.red[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      appointment.syncErrorMessage ?? 'Unknown error',
                      style: JHTextStyles.caption.copyWith(
                        color: Colors.red[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isFilipino
                  ? 'Maaari mong subukang i-sync muli ang appointment na ito gamit ang "Retry Failed Syncs" button sa ibaba.'
                  : 'You can retry syncing this appointment using the "Retry Failed Syncs" button below.',
              style: JHTextStyles.caption.copyWith(
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          StandardButton.secondary(
            text: isFilipino ? 'Isara' : 'Close',
            onPressed: () => Get.back(),
            width: 100,
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
            style: JHTextStyles.h5,
          ),
          content: Text(
            Get.locale?.languageCode == 'fil'
                ? 'Kailangan mong sagutan muna ang pre-consultation form bago sumali sa waiting room.'
                : 'Please complete the pre-consultation questionnaire before joining the waiting room.',
            style: JHTextStyles.bodyBase,
          ),
          actions: [
            StandardButton.grey(
              text: Get.locale?.languageCode == 'fil' ? 'Kanselahin' : 'Cancel',
              onPressed: () => Get.back(),
              width: 120,
            ),
            const SizedBox(width: 8),
            StandardButton.secondary(
              text: Get.locale?.languageCode == 'fil'
                  ? 'Sagutan Ngayon'
                  : 'Fill Now',
              onPressed: () {
                Get.back();
                _fillQuestionnaire(appointment);
              },
              width: 150,
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

class AppointmentHistoryView extends StatefulWidget {
  const AppointmentHistoryView({super.key});

  @override
  State<AppointmentHistoryView> createState() => _AppointmentHistoryViewState();
}

class _AppointmentHistoryViewState extends State<AppointmentHistoryView> {
  bool _isLoading = true;
  List<Appointment> _appointments = [];
  DateRangeOption _selectedRange = DateRangeOption.last30Days;
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  String? _selectedFacility;
  AppointmentStatus? _selectedStatus;
  int _page = 1;
  static const int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final data = await AppointmentService.getAppointments();
      setState(() {
        _appointments = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      Get.snackbar('Error', 'Failed to load history: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          Get.locale?.languageCode == 'fil'
              ? 'Kasaysayan ng Appointment'
              : 'Appointment History',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _exportHistory,
          ),
        ],
      ),
      body: _isLoading ? _buildLoading() : _buildBody(),
    );
  }

  Widget _buildLoading() => const Center(child: CircularProgressIndicator());

  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh: () async {
        await _loadHistory();
        _page = 1;
      },
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildFiltersSection(),
          const SizedBox(height: 16),
          _buildHistoryList(),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DateRangeSelector(
          selectedRange: _selectedRange,
          onRangeSelected: (option) async {
            if (option == DateRangeOption.custom) {
              final range = await _pickCustomRange();
              if (range == null) return;
              setState(() {
                _selectedRange = option;
                _customStartDate = range.start;
                _customEndDate = range.end;
                _page = 1;
              });
            } else {
              setState(() {
                _selectedRange = option;
                _customStartDate = null;
                _customEndDate = null;
                _page = 1;
              });
            }
          },
          customStartDate: _customStartDate,
          customEndDate: _customEndDate,
        ),
        const SizedBox(height: 12),
        _buildFacilityDropdown(),
        const SizedBox(height: 12),
        _buildStatusChips(),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _resetFilters,
            child: Text(
              Get.locale?.languageCode == 'fil' ? 'I-reset' : 'Reset',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFacilityDropdown() {
    final facilities = _facilityOptions();
    return DropdownButtonFormField<String>(
      value: _selectedFacility,
      decoration: InputDecoration(
        labelText:
            Get.locale?.languageCode == 'fil' ? 'Pasilidad' : 'Facility',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      items: [
        DropdownMenuItem(
          value: null,
          child: Text(Get.locale?.languageCode == 'fil' ? 'Lahat' : 'All'),
        ),
        ...facilities.map(
          (facility) => DropdownMenuItem(
            value: facility,
            child: Text(facility),
          ),
        ),
      ],
      onChanged: (value) {
        setState(() {
          _selectedFacility = value;
          _page = 1;
        });
      },
    );
  }

  Widget _buildStatusChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(
          label: Text(
            Get.locale?.languageCode == 'fil' ? 'Lahat' : 'All',
          ),
          selected: _selectedStatus == null,
          onSelected: (_) {
            setState(() {
              _selectedStatus = null;
              _page = 1;
            });
          },
        ),
        ...AppointmentStatus.values.map(
          (status) => ChoiceChip(
            label: Text(status.name.toUpperCase()),
            selected: _selectedStatus == status,
            onSelected: (_) {
              setState(() {
                _selectedStatus = status;
                _page = 1;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryList() {
    final filtered = _filteredAppointments();
    final visible = _visibleAppointments(filtered);

    if (filtered.isEmpty) {
      return _buildEmptyHistory();
    }

    return Column(
      children: [
        ...visible.map(_buildHistoryCard),
        if (visible.length < filtered.length)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: StandardButton.secondary(
              text: Get.locale?.languageCode == 'fil'
                  ? 'Mag-load ng Mas Marami'
                  : 'Load More',
              onPressed: () => setState(() => _page += 1),
            ),
          ),
      ],
    );
  }

  Widget _buildHistoryCard(Appointment appointment) {
    return StandardCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusRow(appointment),
          const SizedBox(height: 12),
          Text(
            appointment.facilityName,
            style: JHTextStyles.h5.copyWith(color: ColorConstant.bluedark),
          ),
          const SizedBox(height: 6),
          Text(
            appointment.doctorName,
            style: JHTextStyles.bodySmall.copyWith(
              color: ColorConstant.gentleGray,
            ),
          ),
          const SizedBox(height: 8),
          _buildMetaRow(appointment),
          if (appointment.notes?.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ColorConstant.softWhite,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  appointment.notes!,
                  style: JHTextStyles.caption.copyWith(
                    color: ColorConstant.gentleGray,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(Appointment appointment) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: appointment.getStatusColor().withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            appointment.getStatusText(Get.locale?.languageCode ?? 'en'),
            style: JHTextStyles.caption.copyWith(
              color: appointment.getStatusColor(),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Spacer(),
        Text(
          DateFormat('MMM dd, yyyy').format(appointment.appointmentDate),
          style: JHTextStyles.bodySmall.copyWith(
            color: ColorConstant.gentleGray,
          ),
        ),
      ],
    );
  }

  Widget _buildMetaRow(Appointment appointment) {
    return Row(
      children: [
        Icon(Icons.access_time, size: 16, color: ColorConstant.trustBlue),
        const SizedBox(width: 6),
        Text(
          appointment.appointmentTime,
          style: JHTextStyles.bodySmall.copyWith(
            color: ColorConstant.bluedark,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 12),
        Icon(Icons.local_hospital, size: 16, color: ColorConstant.trustBlue),
        const SizedBox(width: 6),
        Text(
          appointment.getTypeText(Get.locale?.languageCode ?? 'en'),
          style: JHTextStyles.bodySmall.copyWith(
            color: ColorConstant.bluedark,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyHistory() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: ColorConstant.softWhite,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.history, size: 48, color: ColorConstant.gentleGray),
          const SizedBox(height: 12),
          Text(
            Get.locale?.languageCode == 'fil'
                ? 'Wala pang nakaraang appointments.'
                : 'No past appointments yet.',
            style: JHTextStyles.bodyBase.copyWith(
              color: ColorConstant.gentleGray,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  List<Appointment> _filteredAppointments() {
    final now = DateTime.now();
    final range = _activeRange();

    return _appointments.where((appointment) {
      final past = appointment.appointmentDate.isBefore(now) ||
          appointment.status == AppointmentStatus.completed ||
          appointment.status == AppointmentStatus.cancelled ||
          appointment.status == AppointmentStatus.noShow;
      if (!past) return false;

      if (range != null) {
        final date = appointment.appointmentDate;
        if (date.isBefore(range.start) || date.isAfter(range.end)) {
          return false;
        }
      }

      if (_selectedFacility != null &&
          appointment.facilityName != _selectedFacility) {
        return false;
      }

      if (_selectedStatus != null && appointment.status != _selectedStatus) {
        return false;
      }

      return true;
    }).toList()
      ..sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));
  }

  List<Appointment> _visibleAppointments(List<Appointment> filtered) {
    final limit = _page * _pageSize;
    if (filtered.length <= limit) return filtered;
    return filtered.sublist(0, limit);
  }

  DateTimeRange? _activeRange() {
    final now = DateTime.now();
    switch (_selectedRange) {
      case DateRangeOption.last7Days:
        return DateTimeRange(
          start: now.subtract(const Duration(days: 7)),
          end: now,
        );
      case DateRangeOption.last30Days:
        return DateTimeRange(
          start: now.subtract(const Duration(days: 30)),
          end: now,
        );
      case DateRangeOption.last90Days:
        return DateTimeRange(
          start: now.subtract(const Duration(days: 90)),
          end: now,
        );
      case DateRangeOption.lastYear:
        return DateTimeRange(
          start: now.subtract(const Duration(days: 365)),
          end: now,
        );
      case DateRangeOption.custom:
        if (_customStartDate != null && _customEndDate != null) {
          return DateTimeRange(
            start: _customStartDate!,
            end: _customEndDate!,
          );
        }
        return null;
      case DateRangeOption.allTime:
        return null;
    }
  }

  List<String> _facilityOptions() {
    final set = _appointments.map((apt) => apt.facilityName).toSet().toList()
      ..sort();
    return set;
  }

  Future<DateTimeRange?> _pickCustomRange() async {
    return await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      currentDate: DateTime.now(),
    );
  }

  void _resetFilters() {
    setState(() {
      _selectedRange = DateRangeOption.last30Days;
      _customStartDate = null;
      _customEndDate = null;
      _selectedFacility = null;
      _selectedStatus = null;
      _page = 1;
    });
  }

  Future<void> _exportHistory() async {
    final data = _filteredAppointments();
    await AppointmentHistoryPdfService.export(
      context: context,
      appointments: data,
      dateRange: _activeRange(),
      facility: _selectedFacility,
      status: _selectedStatus,
    );
  }
}
