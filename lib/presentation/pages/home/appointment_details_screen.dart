import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:juan_heart/core/app_exports.dart';
import 'package:juan_heart/models/appointment_model.dart';
import 'package:juan_heart/presentation/widgets/standard_button.dart';
import 'package:juan_heart/routes/app_routes.dart';
import 'package:juan_heart/themes/jh_text_styles.dart';

class AppointmentDetailsScreen extends StatelessWidget {
  final Appointment appointment;

  const AppointmentDetailsScreen({super.key, required this.appointment});

  bool get _isFilipino => Get.locale?.languageCode == 'fil';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstant.whiteBackground,
      appBar: AppBar(
        title: Text(
          _isFilipino ? 'Detalye ng Appointment' : 'Appointment Details',
          style: JHTextStyles.h5.copyWith(color: ColorConstant.bluedark),
        ),
        backgroundColor: ColorConstant.whiteBackground,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildStatusCard(),
          const SizedBox(height: 16),
          _buildScheduleCard(),
          const SizedBox(height: 16),
          if (appointment.notes != null && appointment.notes!.isNotEmpty)
            _buildNotesCard(),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StandardButton.primary(
              text: _isFilipino ? 'Buksan ang Mga Appointment' : 'Open Appointments',
              onPressed: () {
                Get.toNamed(
                  AppRoutes.home,
                  arguments: {'initialTab': 2},
                );
              },
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Get.back(),
              child: Text(
                _isFilipino ? 'Isara' : 'Close',
                style: JHTextStyles.bodySmall.copyWith(
                  color: ColorConstant.trustBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appointment.getStatusColor().withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: appointment.getStatusColor().withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: appointment.getStatusColor(),
            child: Icon(
              appointment.getStatusIcon(),
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment.getStatusText(Get.locale?.languageCode ?? 'en'),
                  style: JHTextStyles.h5.copyWith(
                    color: appointment.getStatusColor(),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  appointment.facilityName,
                  style: JHTextStyles.bodyBase.copyWith(
                    color: ColorConstant.bluedark,
                  ),
                ),
                if (appointment.doctorName != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    appointment.doctorName!,
                    style: JHTextStyles.bodySmall.copyWith(
                      color: ColorConstant.gentleGray,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ColorConstant.softWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ColorConstant.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isFilipino ? 'Iskedyul' : 'Schedule',
            style: JHTextStyles.label.copyWith(
              color: ColorConstant.gentleGray,
            ),
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            icon: Icons.calendar_today,
            label: _isFilipino ? 'Petsa' : 'Date',
            value: DateFormat('EEEE, MMM d, yyyy').format(
              appointment.appointmentDate,
            ),
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            icon: Icons.schedule,
            label: _isFilipino ? 'Oras' : 'Time',
            value: appointment.appointmentTime,
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            icon: Icons.local_hospital,
            label: _isFilipino ? 'Uri ng Pagbisita' : 'Visit Type',
            value: appointment.getTypeText(Get.locale?.languageCode ?? 'en'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ColorConstant.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isFilipino ? 'Mga Tala' : 'Notes',
            style: JHTextStyles.label.copyWith(
              color: ColorConstant.gentleGray,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            appointment.notes!,
            style: JHTextStyles.bodyBase.copyWith(
              color: ColorConstant.bluedark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: ColorConstant.lightBlueBackground,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: ColorConstant.trustBlue, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: JHTextStyles.caption.copyWith(
                  color: ColorConstant.gentleGray,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: JHTextStyles.bodyBase.copyWith(
                  color: ColorConstant.bluedark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
