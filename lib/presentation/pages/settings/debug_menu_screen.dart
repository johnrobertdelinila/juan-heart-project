import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:juan_heart/core/app_exports.dart';
import 'package:juan_heart/models/appointment_model.dart';
import 'package:juan_heart/services/appointment_service.dart';
import 'package:juan_heart/services/appointment_notification_service.dart';
import 'package:juan_heart/services/notification_service.dart';
import 'package:juan_heart/services/conflict_resolver.dart';
import 'package:juan_heart/services/crash_reporting_service.dart';
import 'package:juan_heart/presentation/widgets/standard_button.dart';
import 'package:juan_heart/presentation/widgets/standard_card.dart';
import 'package:juan_heart/presentation/pages/settings/conflict_resolution_screen.dart';
import 'package:juan_heart/themes/jh_text_styles.dart';

/// Debug menu for testing notification system
/// Only visible in debug builds
class DebugMenuScreen extends StatefulWidget {
  const DebugMenuScreen({super.key});

  @override
  State<DebugMenuScreen> createState() => _DebugMenuScreenState();
}

class _DebugMenuScreenState extends State<DebugMenuScreen> {
  final _notificationService = AppointmentNotificationService();
  List<Appointment> _appointments = [];
  bool _isLoading = false;
  int _pendingNotificationsCount = 0;
  Map<String, dynamic> _conflictStats = {};
  int _conflictCount = 0;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
    _loadPendingNotifications();
    _loadConflictStatistics();
  }

  Future<void> _loadAppointments() async {
    setState(() => _isLoading = true);

    try {
      final appointments = await AppointmentService.getAppointments();
      setState(() {
        _appointments = appointments
            .where((apt) =>
                apt.status != AppointmentStatus.cancelled &&
                apt.status != AppointmentStatus.noShow)
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading appointments: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadPendingNotifications() async {
    try {
      final pending = await _notificationService.getPendingNotifications();
      setState(() {
        _pendingNotificationsCount = pending.length;
      });
    } catch (e) {
      print('Error loading pending notifications: $e');
    }
  }

  Future<void> _loadConflictStatistics() async {
    try {
      final stats = await ConflictResolver.instance.getConflictStatistics();
      final count = await ConflictResolver.instance.getManualReviewCount();
      setState(() {
        _conflictStats = stats;
        _conflictCount = count;
      });
    } catch (e) {
      print('Error loading conflict statistics: $e');
    }
  }

  Future<void> _testFollowUpReminder(Appointment appointment) async {
    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      await _notificationService.testFollowUpReminderImmediately(appointment);
      await _loadPendingNotifications();

      Get.back(); // Close loading

      Get.snackbar(
        'Test Notification Scheduled',
        'Follow-up reminder will fire in 10 seconds for ${appointment.facilityName}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: ColorConstant.reassuringGreen,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      Get.back(); // Close loading

      Get.snackbar(
        'Error',
        'Failed to schedule test notification: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    }
  }

  Future<void> _clearAllNotifications() async {
    Get.dialog(
      AlertDialog(
        title: Text(
          'Clear All Notifications?',
          style: JHTextStyles.h5,
        ),
        content: Text(
          'This will clear all notifications from the notification center. Scheduled notifications will remain.',
          style: JHTextStyles.bodyBase,
        ),
        actions: [
          StandardButton.outline(
            text: 'Cancel',
            onPressed: () => Get.back(),
            width: 80,
          ),
          const SizedBox(width: 8),
          StandardButton.primary(
            text: 'Clear All',
            onPressed: () async {
              Get.back();

              try {
                Get.dialog(
                  const Center(child: CircularProgressIndicator()),
                  barrierDismissible: false,
                );

                await NotificationService.instance.clearAllNotifications();

                Get.back(); // Close loading

                Get.snackbar(
                  'Cleared',
                  'All notifications have been cleared',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: ColorConstant.reassuringGreen,
                  colorText: Colors.white,
                  margin: const EdgeInsets.all(16),
                  borderRadius: 12,
                );
              } catch (e) {
                Get.back(); // Close loading

                Get.snackbar(
                  'Error',
                  'Failed to clear notifications: $e',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                  margin: const EdgeInsets.all(16),
                  borderRadius: 12,
                );
              }
            },
            width: 100,
          ),
        ],
      ),
    );
  }

  Future<void> _showPendingNotifications() async {
    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      final pending = await _notificationService.getPendingNotifications();

      Get.back(); // Close loading

      Get.dialog(
        AlertDialog(
          title: Text(
            'Pending Notifications (${pending.length})',
            style: JHTextStyles.h5,
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: pending.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'No pending notifications',
                      style: JHTextStyles.bodyBase,
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: pending.length,
                    itemBuilder: (context, index) {
                      final notification = pending[index];
                      return ListTile(
                        dense: true,
                        title: Text(
                          notification.title ?? 'No title',
                          style: JHTextStyles.label.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          notification.body ?? 'No body',
                          style: JHTextStyles.caption,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Text(
                          'ID: ${notification.id}',
                          style: JHTextStyles.caption.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            StandardButton.primary(
              text: 'Close',
              onPressed: () => Get.back(),
              width: 80,
            ),
          ],
        ),
      );
    } catch (e) {
      Get.back(); // Close loading

      Get.snackbar(
        'Error',
        'Failed to load pending notifications: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstant.whiteBackground,
      appBar: AppBar(
        backgroundColor: ColorConstant.whiteBackground,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: ColorConstant.bluedark),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Debug Menu',
          style: JHTextStyles.h4.copyWith(
            color: ColorConstant.bluedark,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Warning banner
                  StandardCard(
                    backgroundColor:
                        ColorConstant.warningColor.withValues(alpha: 0.1),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: ColorConstant.warningColor,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Debug tools for QA testing only. Not visible in production builds.',
                            style: JHTextStyles.label.copyWith(
                              color: ColorConstant.gentleGray,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Notification info card
                  StandardCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.notifications_active,
                              color: ColorConstant.trustBlue,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Notification Status',
                              style: JHTextStyles.bodyBase.copyWith(
                                fontWeight: FontWeight.bold,
                                color: ColorConstant.bluedark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow('Pending Notifications',
                            '$_pendingNotificationsCount'),
                        _buildInfoRow(
                            'Active Appointments', '${_appointments.length}'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Quick actions
                  StandardCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quick Actions',
                          style: JHTextStyles.bodyBase.copyWith(
                            fontWeight: FontWeight.bold,
                            color: ColorConstant.bluedark,
                          ),
                        ),
                        const SizedBox(height: 16),
                        StandardButton.secondary(
                          text: 'View Pending Notifications',
                          onPressed: _showPendingNotifications,
                        ),
                        const SizedBox(height: 12),
                        StandardButton.outline(
                          text: 'Clear All Notifications',
                          onPressed: _clearAllNotifications,
                        ),
                        const SizedBox(height: 12),
                        StandardButton.outline(
                          text: 'Refresh',
                          onPressed: () {
                            _loadAppointments();
                            _loadPendingNotifications();
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Crashlytics Test section
                  StandardCard(
                    backgroundColor: Colors.red.withValues(alpha: 0.05),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.bug_report,
                              color: Colors.red,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Crashlytics Test',
                              style: JHTextStyles.bodyBase.copyWith(
                                fontWeight: FontWeight.bold,
                                color: ColorConstant.bluedark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Force a crash to verify Firebase Crashlytics is collecting crash reports.',
                          style: JHTextStyles.label.copyWith(
                            color: ColorConstant.gentleGray,
                          ),
                        ),
                        const SizedBox(height: 16),
                        StandardButton.compact(
                          text: 'Test Crash',
                          onPressed: _testCrashlytics,
                          backgroundColor: Colors.red,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Conflict Resolution section
                  StandardCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.sync_problem,
                              color: ColorConstant.warningColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Conflict Resolution',
                              style: JHTextStyles.bodyBase.copyWith(
                                fontWeight: FontWeight.bold,
                                color: ColorConstant.bluedark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow('Pending Review', '$_conflictCount'),
                        _buildInfoRow('Total Resolved',
                            '${_conflictStats['totalConflicts'] ?? 0}'),
                        if (_conflictStats['lastConflictAt'] != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Last conflict: ${_formatTimestamp(_conflictStats['lastConflictAt'])}',
                            style: JHTextStyles.label.copyWith(
                              color: ColorConstant.gentleGray,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        StandardButton.secondary(
                          text: 'View Conflict Log',
                          onPressed: () async {
                            await Get.to(
                                () => const ConflictResolutionScreen());
                            _loadConflictStatistics();
                          },
                        ),
                        const SizedBox(height: 12),
                        StandardButton.outline(
                          text: 'Clear Conflict Log',
                          onPressed: _clearConflictLog,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Test follow-up reminders
                  Text(
                    'Test Follow-Up Reminders',
                    style: JHTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: ColorConstant.gentleGray,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap an appointment to schedule a test follow-up notification (fires in 10 seconds)',
                    style: JHTextStyles.label.copyWith(
                      color: ColorConstant.gentleGray,
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_appointments.isEmpty)
                    StandardCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'No active appointments available for testing',
                          style: JHTextStyles.bodySmall.copyWith(
                            color: ColorConstant.gentleGray,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else
                    ..._appointments
                        .map((appointment) =>
                            _buildAppointmentTestCard(appointment))
                        .toList(),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: JHTextStyles.bodySmall.copyWith(
              color: ColorConstant.gentleGray,
            ),
          ),
          Text(
            value,
            style: JHTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.bold,
              color: ColorConstant.bluedark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentTestCard(Appointment appointment) {
    return StandardCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.local_hospital,
                color: ColorConstant.trustBlue,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  appointment.facilityName,
                  style: JHTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: ColorConstant.bluedark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            appointment.doctorName,
            style: JHTextStyles.label.copyWith(
              color: ColorConstant.gentleGray,
            ),
          ),
          const SizedBox(height: 12),
          StandardButton.secondary(
            text: 'Test Follow-Up (10s)',
            onPressed: () => _testFollowUpReminder(appointment),
          ),
        ],
      ),
    );
  }

  Future<void> _testCrashlytics() async {
    Get.dialog(
      AlertDialog(
        title: Text(
          'Test Crashlytics',
          style: JHTextStyles.h5,
        ),
        content: Text(
          'This will force a test crash to verify Crashlytics is working. The app will close immediately.\n\nCheck Firebase Console in a few minutes to see the crash report.',
          style: JHTextStyles.bodyBase,
        ),
        actions: [
          StandardButton.outline(
            text: 'Cancel',
            onPressed: () => Get.back(),
            width: 80,
          ),
          const SizedBox(width: 8),
          StandardButton.compact(
            text: 'Test Crash',
            onPressed: () async {
              Get.back();

              // Wait a second to let dialog close
              await Future.delayed(const Duration(seconds: 1));

              // Force a test crash
              await CrashReportingService.instance.testCrash();
            },
            width: 100,
            backgroundColor: Colors.red,
          ),
        ],
      ),
    );
  }

  Future<void> _clearConflictLog() async {
    Get.dialog(
      AlertDialog(
        title: Text(
          'Clear Conflict Log?',
          style: JHTextStyles.h5,
        ),
        content: Text(
          'This will clear all conflict resolution history. Pending conflicts will remain.',
          style: JHTextStyles.bodyBase,
        ),
        actions: [
          StandardButton.outline(
            text: 'Cancel',
            onPressed: () => Get.back(),
            width: 80,
          ),
          const SizedBox(width: 8),
          StandardButton.primary(
            text: 'Clear',
            onPressed: () async {
              Get.back();

              try {
                Get.dialog(
                  const Center(child: CircularProgressIndicator()),
                  barrierDismissible: false,
                );

                await ConflictResolver.instance.clearConflictLog();
                await _loadConflictStatistics();

                Get.back(); // Close loading

                Get.snackbar(
                  'Cleared',
                  'Conflict log has been cleared',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: ColorConstant.reassuringGreen,
                  colorText: Colors.white,
                  margin: const EdgeInsets.all(16),
                  borderRadius: 12,
                );
              } catch (e) {
                Get.back(); // Close loading

                Get.snackbar(
                  'Error',
                  'Failed to clear conflict log: $e',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                  margin: const EdgeInsets.all(16),
                  borderRadius: 12,
                );
              }
            },
            width: 80,
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    try {
      DateTime dateTime;
      if (timestamp is String) {
        dateTime = DateTime.parse(timestamp);
      } else if (timestamp is DateTime) {
        dateTime = timestamp;
      } else {
        return 'Unknown';
      }

      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inDays < 1) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
      }
    } catch (e) {
      return 'Unknown';
    }
  }
}
