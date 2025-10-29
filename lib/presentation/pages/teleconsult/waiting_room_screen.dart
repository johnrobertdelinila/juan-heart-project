import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:juan_heart/core/app_exports.dart';
import 'package:juan_heart/models/appointment_model.dart';
import 'package:intl/intl.dart';
import 'dart:async';

/// Enum for doctor availability status
enum DoctorStatus {
  available,
  busy,
  offline,
}

class WaitingRoomScreen extends StatefulWidget {
  final Appointment appointment;

  const WaitingRoomScreen({Key? key, required this.appointment})
      : super(key: key);

  @override
  State<WaitingRoomScreen> createState() => _WaitingRoomScreenState();
}

class _WaitingRoomScreenState extends State<WaitingRoomScreen>
    with SingleTickerProviderStateMixin {
  // Mock data for demonstration
  int _queuePosition = 3;
  int _estimatedWaitMinutes = 15;
  DoctorStatus _doctorStatus = DoctorStatus.busy;
  bool _isReady = false;

  Timer? _countdownTimer;
  Timer? _statusUpdateTimer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startMockUpdates();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _startMockUpdates() {
    // Simulate queue updates every 30 seconds
    _statusUpdateTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!mounted) return;

      setState(() {
        if (_queuePosition > 1) {
          _queuePosition--;
          _estimatedWaitMinutes = _queuePosition * 5;
        } else if (_queuePosition == 1) {
          _doctorStatus = DoctorStatus.available;
          _isReady = true;
          timer.cancel();
        }
      });
    });

    // Countdown timer for wait time
    _countdownTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (!mounted) return;

      setState(() {
        if (_estimatedWaitMinutes > 0) {
          _estimatedWaitMinutes--;
        }
      });
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _statusUpdateTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _joinCall() {
    final isFilipino = Get.locale?.languageCode == 'fil';

    Get.dialog(
      AlertDialog(
        title: Text(
          isFilipino ? 'Sumali sa Call' : 'Join Call',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          isFilipino
              ? 'Ang video call feature ay darating na sa susunod na update. Salamat sa inyong pag-intindi!'
              : 'Video call feature is coming in a future update. Thank you for your patience!',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('OK'),
          ),
        ],
      ),
    );
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
          isFilipino ? 'Waiting Room' : 'Waiting Room',
          style: TextStyle(
            color: ColorConstant.bluedark,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Appointment details card
            _buildAppointmentCard(isFilipino),
            const SizedBox(height: 20),

            // Doctor status
            _buildDoctorStatusCard(isFilipino),
            const SizedBox(height: 20),

            // Queue position
            if (!_isReady) _buildQueueCard(isFilipino),
            if (!_isReady) const SizedBox(height: 20),

            // Ready to join
            if (_isReady) _buildReadyCard(isFilipino),
            if (_isReady) const SizedBox(height: 20),

            // Preparation tips
            _buildPreparationTips(isFilipino),
            const SizedBox(height: 20),

            // Technical checklist
            _buildTechnicalChecklist(isFilipino),
            const SizedBox(height: 20),

            // Join button
            if (_isReady) _buildJoinButton(isFilipino),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(bool isFilipino) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isFilipino ? 'Detalye ng Appointment' : 'Appointment Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
                color: ColorConstant.bluedark,
              ),
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.local_hospital,
              isFilipino ? 'Pasilidad' : 'Facility',
              widget.appointment.facilityName,
            ),
            _buildDetailRow(
              Icons.person,
              isFilipino ? 'Doktor' : 'Doctor',
              widget.appointment.doctorName.isNotEmpty
                  ? widget.appointment.doctorName
                  : (isFilipino ? 'Hindi pa natukoy' : 'To be assigned'),
            ),
            _buildDetailRow(
              Icons.calendar_today,
              isFilipino ? 'Petsa' : 'Date',
              '${DateFormat('MMM dd, yyyy').format(widget.appointment.appointmentDate)} at ${widget.appointment.appointmentTime}',
            ),
            _buildDetailRow(
              Icons.medical_services,
              'Type',
              widget.appointment.getTypeText(isFilipino ? 'fil' : 'en'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: ColorConstant.lightRed),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: ColorConstant.bluedark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorStatusCard(bool isFilipino) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (_doctorStatus) {
      case DoctorStatus.available:
        statusColor = Colors.green;
        statusText = isFilipino ? 'Available' : 'Available';
        statusIcon = Icons.check_circle;
        break;
      case DoctorStatus.busy:
        statusColor = Colors.orange;
        statusText = isFilipino ? 'Busy' : 'Busy';
        statusIcon = Icons.access_time;
        break;
      case DoctorStatus.offline:
        statusColor = Colors.grey;
        statusText = isFilipino ? 'Offline' : 'Offline';
        statusIcon = Icons.cancel;
        break;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(statusIcon, color: statusColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isFilipino ? 'Status ng Doktor' : 'Doctor Status',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQueueCard(bool isFilipino) {
    return Card(
      elevation: 2,
      color: ColorConstant.lightRed.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              isFilipino ? 'Inyong Posisyon sa Pila' : 'Your Position in Queue',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$_queuePosition',
                  style: TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                    color: ColorConstant.lightRed,
                    fontFamily: 'Poppins',
                    height: 1,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, left: 4),
                  child: Text(
                    isFilipino
                        ? '${_queuePosition == 1 ? 'tao' : 'tao'} ang nauna'
                        : '${_queuePosition == 1 ? 'person' : 'people'} ahead',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.access_time, size: 20, color: ColorConstant.lightRed),
                  const SizedBox(width: 8),
                  Text(
                    isFilipino
                        ? 'Tinatayang Paghihintay: $_estimatedWaitMinutes min'
                        : 'Estimated Wait: $_estimatedWaitMinutes min',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: ColorConstant.bluedark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              backgroundColor: Colors.grey[200],
              color: ColorConstant.lightRed,
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadyCard(bool isFilipino) {
    return ScaleTransition(
      scale: _pulseAnimation,
      child: Card(
        elevation: 4,
        color: Colors.green[50],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.green[300]!, width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(Icons.videocam, color: Colors.green[700], size: 48),
              const SizedBox(height: 12),
              Text(
                isFilipino ? 'Handa na Kayo!' : 'You\'re Ready!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                  color: Colors.green[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isFilipino
                    ? 'Ang doktor ay handa na para sa inyong consultation'
                    : 'The doctor is ready for your consultation',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.green[800],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreparationTips(bool isFilipino) {
    final tips = isFilipino
        ? [
            'Maghanap ng tahimik na lugar para sa consultation',
            'Ihanda ang inyong medical records at test results',
            'Isulat ang mga tanong na gusto ninyong itanong',
            'Siguraduhing maayos ang internet connection',
          ]
        : [
            'Find a quiet place for the consultation',
            'Prepare your medical records and test results',
            'Write down questions you want to ask',
            'Ensure stable internet connection',
          ];

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
                Icon(Icons.lightbulb_outline,
                    color: ColorConstant.lightRed, size: 24),
                const SizedBox(width: 12),
                Text(
                  isFilipino ? 'Mga Paalala' : 'Preparation Tips',
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
            ...tips.map((tip) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 18, color: ColorConstant.lightRed),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          tip,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildTechnicalChecklist(bool isFilipino) {
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
                Icon(Icons.settings_outlined,
                    color: ColorConstant.lightRed, size: 24),
                const SizedBox(width: 12),
                Text(
                  isFilipino ? 'Technical Checklist' : 'Technical Checklist',
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
            _buildChecklistItem(
              Icons.wifi,
              isFilipino ? 'Internet connection' : 'Internet connection',
              true,
            ),
            _buildChecklistItem(
              Icons.videocam,
              isFilipino ? 'Camera access' : 'Camera access',
              true,
            ),
            _buildChecklistItem(
              Icons.mic,
              isFilipino ? 'Microphone access' : 'Microphone access',
              true,
            ),
            _buildChecklistItem(
              Icons.volume_up,
              isFilipino ? 'Speaker/headphones' : 'Speaker/headphones',
              true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistItem(IconData icon, String label, bool isChecked) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            isChecked ? Icons.check_circle : Icons.cancel,
            color: isChecked ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 12),
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJoinButton(bool isFilipino) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _joinCall,
        icon: const Icon(Icons.videocam, size: 24),
        label: Text(
          isFilipino ? 'Sumali sa Video Call' : 'Join Video Call',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green[600],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
      ),
    );
  }
}
