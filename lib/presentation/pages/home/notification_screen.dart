import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:juan_heart/bloc/notification_bloc/notification_bloc.dart';
import 'package:juan_heart/bloc/notification_bloc/notification_event.dart';
import 'package:juan_heart/bloc/notification_bloc/notification_state.dart';
import 'package:juan_heart/core/utils/color_constants.dart';
import 'package:juan_heart/models/notification_model.dart';
import 'package:juan_heart/models/notification_category.dart';
import 'package:juan_heart/services/notification_service.dart';
import 'package:juan_heart/themes/jh_text_styles.dart';

/// Notification screen with BLoC integration.
/// Displays notifications with filtering, grouping, and swipe actions.
/// Follows Material Design 3 and Juan Heart UI/UX guidelines.
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => NotificationScreenState();
}

class NotificationScreenState extends State<NotificationScreen> {
  NotificationCategory? _selectedFilter;

  @override
  void initState() {
    super.initState();
    // Load notifications on init
    context.read<NotificationBloc>().add(const LoadNotifications());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstant.whiteBackground,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: _buildNotificationList(),
          ),
        ],
      ),
    );
  }

  /// Build AppBar with unread badge and clear all button
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: ColorConstant.whiteBackground,
      automaticallyImplyLeading: false,
      elevation: 0,
      centerTitle: true,
      title: Text(
        Get.locale?.languageCode == 'fil' ? 'Mga Abiso' : 'Notifications',
        semanticsLabel: Get.locale?.languageCode == 'fil'
            ? 'Mga Abiso'
            : 'Notifications',
        style: JHTextStyles.h4.copyWith(
          color: ColorConstant.bluedark,
        ),
      ),
      actions: [
        BlocBuilder<NotificationBloc, NotificationState>(
          builder: (context, state) {
            if (state is NotificationsLoaded &&
                state.notifications.isNotEmpty) {
              return Row(
                children: [
                  // Unread count badge
                  if (state.hasUnread)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: ColorConstant.emergencyBadge,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${state.unreadCount}',
                        style: JHTextStyles.bodySmall.copyWith(
                          color: ColorConstant.whiteText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  // Clear all button
                  IconButton(
                    icon: Icon(
                      Icons.delete_sweep,
                      color: ColorConstant.bluedark,
                      semanticLabel: Get.locale?.languageCode == 'fil'
                          ? 'Tanggalin lahat'
                          : 'Clear all',
                    ),
                    onPressed: () => _showClearAllDialog(),
                  ),
                  const SizedBox(width: 8),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  /// Build filter chips for category filtering
  Widget _buildFilterChips() {
    return BlocBuilder<NotificationBloc, NotificationState>(
      builder: (context, state) {
        if (state is! NotificationsLoaded || !state.hasNotifications) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  label: Get.locale?.languageCode == 'fil' ? 'Lahat' : 'All',
                  isSelected: _selectedFilter == null,
                  onTap: () => _applyFilter(null),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: Get.locale?.languageCode == 'fil'
                      ? 'Hindi Nabasa'
                      : 'Unread',
                  isSelected: false,
                  icon: Icons.mark_email_unread,
                  onTap: () {
                    context
                        .read<NotificationBloc>()
                        .add(const LoadUnreadNotifications());
                  },
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: NotificationCategory.appointment
                      .getDisplayName(Get.locale?.languageCode == 'fil'),
                  isSelected: _selectedFilter == NotificationCategory.appointment,
                  icon: NotificationCategory.appointment.iconData,
                  onTap: () =>
                      _applyFilter(NotificationCategory.appointment),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: NotificationCategory.healthAlert
                      .getDisplayName(Get.locale?.languageCode == 'fil'),
                  isSelected: _selectedFilter == NotificationCategory.healthAlert,
                  icon: NotificationCategory.healthAlert.iconData,
                  onTap: () =>
                      _applyFilter(NotificationCategory.healthAlert),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: NotificationCategory.followUp
                      .getDisplayName(Get.locale?.languageCode == 'fil'),
                  isSelected: _selectedFilter == NotificationCategory.followUp,
                  icon: NotificationCategory.followUp.iconData,
                  onTap: () => _applyFilter(NotificationCategory.followUp),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: NotificationCategory.system
                      .getDisplayName(Get.locale?.languageCode == 'fil'),
                  isSelected: _selectedFilter == NotificationCategory.system,
                  icon: NotificationCategory.system.iconData,
                  onTap: () => _applyFilter(NotificationCategory.system),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Build individual filter chip
  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    IconData? icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? ColorConstant.lightBlue
              : ColorConstant.whiteBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? ColorConstant.lightBlue
                : ColorConstant.lightGray.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? ColorConstant.whiteText
                    : ColorConstant.bluedark,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: JHTextStyles.caption.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? ColorConstant.whiteText
                    : ColorConstant.bluedark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build notification list with BLoC
  Widget _buildNotificationList() {
    return BlocConsumer<NotificationBloc, NotificationState>(
      listener: (context, state) {
        // Show error snackbar if needed
        if (state is NotificationError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: ColorConstant.emergencyBadge,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is NotificationsLoading) {
          return _buildLoadingState();
        }

        if (state is NotificationsLoaded) {
          if (state.notifications.isEmpty) {
            return _buildEmptyState();
          }

          return _buildNotificationListView(state.notifications);
        }

        if (state is NotificationError && state.hasCachedData) {
          return _buildNotificationListView(
            state.previousState!.notifications,
          );
        }

        return _buildEmptyState();
      },
    );
  }

  /// Build loading state
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(ColorConstant.lightBlue),
          ),
          const SizedBox(height: 16),
          Text(
            Get.locale?.languageCode == 'fil'
                ? 'Naglo-load ng mga abiso...'
                : 'Loading notifications...',
            style: JHTextStyles.bodySmall.copyWith(
              color: ColorConstant.bluedark.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 80,
              color: ColorConstant.lightGray,
            ),
            const SizedBox(height: 24),
            Text(
              Get.locale?.languageCode == 'fil'
                  ? 'Walang mga abiso'
                  : 'No notifications',
              style: JHTextStyles.h5.copyWith(
                color: ColorConstant.bluedark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              Get.locale?.languageCode == 'fil'
                  ? 'Makikita mo dito ang lahat ng iyong mga abiso'
                  : 'You will see all your notifications here',
              textAlign: TextAlign.center,
              style: JHTextStyles.bodySmall.copyWith(
                color: ColorConstant.bluedark.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build notification list view with grouping
  Widget _buildNotificationListView(List<NotificationModel> notifications) {
    final groupedNotifications = _groupNotificationsByDate(notifications);

    return RefreshIndicator(
      onRefresh: () async {
        context.read<NotificationBloc>().add(const RefreshNotifications());
        // Wait for state update
        await Future.delayed(const Duration(milliseconds: 500));
      },
      color: ColorConstant.lightBlue,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: groupedNotifications.length,
        itemBuilder: (context, index) {
          final group = groupedNotifications[index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date header
              _buildDateHeader(group['label'] as String),
              // Notifications for this date
              ...(group['notifications'] as List<NotificationModel>)
                  .map((notification) => _buildNotificationTile(notification))
                  .toList(),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  /// Build date header
  Widget _buildDateHeader(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        label,
        style: JHTextStyles.bodySmall.copyWith(
          fontWeight: FontWeight.w600,
          color: ColorConstant.bluedark.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  /// Build notification tile with slidable actions
  Widget _buildNotificationTile(NotificationModel notification) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Slidable(
        key: ValueKey(notification.id),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            if (!notification.isRead)
              SlidableAction(
                onPressed: (_) => _markAsRead(notification),
                backgroundColor: ColorConstant.trustBlue,
                foregroundColor: ColorConstant.whiteText,
                icon: Icons.check,
                label: Get.locale?.languageCode == 'fil' ? 'Nabasa' : 'Read',
              ),
            SlidableAction(
              onPressed: (_) => _deleteNotification(notification),
              backgroundColor: ColorConstant.emergencyBadge,
              foregroundColor: ColorConstant.whiteText,
              icon: Icons.delete,
              label: Get.locale?.languageCode == 'fil'
                  ? 'Tanggalin'
                  : 'Delete',
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            color: notification.isRead
                ? ColorConstant.whiteBackground
                : ColorConstant.lightBlueBackground.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: ColorConstant.lightGray.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            // Category icon
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: notification.category.backgroundColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                notification.category.iconData,
                color: notification.category.color,
                size: 24,
              ),
            ),
            // Title and body
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    notification.title,
                    style: JHTextStyles.bodySmall.copyWith(
                      fontWeight: notification.isRead
                          ? FontWeight.w500
                          : FontWeight.w700,
                      color: ColorConstant.bluedark,
                    ),
                  ),
                ),
                // Unread indicator
                if (!notification.isRead)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: ColorConstant.trustBlue,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  notification.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: JHTextStyles.caption.copyWith(
                    color: ColorConstant.bluedark.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTimestamp(notification.timestamp),
                  style: JHTextStyles.caption.copyWith(
                    fontSize: 11,
                    color: ColorConstant.bluedark.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
            // Tap to mark as read and navigate
            onTap: () async => await _handleNotificationTap(notification),
          ),
        ),
      ),
    );
  }

  /// Group notifications by date
  List<Map<String, dynamic>> _groupNotificationsByDate(
    List<NotificationModel> notifications,
  ) {
    final groups = <String, List<NotificationModel>>{};

    for (final notification in notifications) {
      final label = _getDateGroupLabel(notification.timestamp);
      if (!groups.containsKey(label)) {
        groups[label] = [];
      }
      groups[label]!.add(notification);
    }

    return groups.entries
        .map((entry) => {
              'label': entry.key,
              'notifications': entry.value,
            })
        .toList();
  }

  /// Get date group label (Today, Yesterday, etc.)
  String _getDateGroupLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final weekAgo = today.subtract(const Duration(days: 7));

    final notificationDate = DateTime(date.year, date.month, date.day);

    if (notificationDate == today) {
      return Get.locale?.languageCode == 'fil' ? 'Ngayon' : 'Today';
    } else if (notificationDate == yesterday) {
      return Get.locale?.languageCode == 'fil' ? 'Kahapon' : 'Yesterday';
    } else if (notificationDate.isAfter(weekAgo)) {
      return Get.locale?.languageCode == 'fil' ? 'Linggong Ito' : 'This Week';
    } else {
      return Get.locale?.languageCode == 'fil' ? 'Mas Luma' : 'Older';
    }
  }

  /// Format timestamp for display
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final notificationDate =
        DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (notificationDate == today) {
      // Show time only for today
      return DateFormat('h:mm a').format(timestamp);
    } else {
      // Show date for older
      return DateFormat('MMM d, yyyy').format(timestamp);
    }
  }

  /// Apply category filter
  void _applyFilter(NotificationCategory? category) {
    setState(() {
      _selectedFilter = category;
    });

    context.read<NotificationBloc>().add(
          FilterNotificationsByCategory(category: category),
        );
  }

  /// Handle notification tap
  Future<void> _handleNotificationTap(NotificationModel notification) async {
    // Mark as read
    if (!notification.isRead) {
      context.read<NotificationBloc>().add(
            MarkNotificationAsRead(notificationId: notification.id),
          );
    }

    // Navigate via NotificationService
    await NotificationService.instance.handleNotificationTap(notification);
  }

  /// Mark notification as read
  void _markAsRead(NotificationModel notification) {
    context.read<NotificationBloc>().add(
          MarkNotificationAsRead(notificationId: notification.id),
        );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          Get.locale?.languageCode == 'fil'
              ? 'Minarkahan bilang nabasa'
              : 'Marked as read',
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: ColorConstant.reassuringGreen,
      ),
    );
  }

  /// Delete notification
  void _deleteNotification(NotificationModel notification) {
    context.read<NotificationBloc>().add(
          DeleteNotification(notificationId: notification.id),
        );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          Get.locale?.languageCode == 'fil'
              ? 'Tinanggal ang abiso'
              : 'Notification deleted',
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: ColorConstant.bluedark,
      ),
    );
  }

  /// Show clear all confirmation dialog
  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: ColorConstant.whiteBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          Get.locale?.languageCode == 'fil'
              ? 'Tanggalin ang lahat?'
              : 'Clear all notifications?',
          style: JHTextStyles.h5.copyWith(
            color: ColorConstant.bluedark,
          ),
        ),
        content: Text(
          Get.locale?.languageCode == 'fil'
              ? 'Tatanggalin ang lahat ng mga abiso. Hindi na ito maibabalik.'
              : 'This will delete all notifications. This cannot be undone.',
          style: JHTextStyles.bodySmall.copyWith(
            color: ColorConstant.bluedark.withValues(alpha: 0.7),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              Get.locale?.languageCode == 'fil' ? 'Kanselahin' : 'Cancel',
              style: JHTextStyles.button.copyWith(
                color: ColorConstant.bluedark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context
                  .read<NotificationBloc>()
                  .add(const ClearAllNotifications());
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    Get.locale?.languageCode == 'fil'
                        ? 'Tinanggal ang lahat ng mga abiso'
                        : 'All notifications cleared',
                  ),
                  backgroundColor: ColorConstant.bluedark,
                ),
              );
            },
            child: Text(
              Get.locale?.languageCode == 'fil'
                  ? 'Tanggalin Lahat'
                  : 'Clear All',
              style: JHTextStyles.button.copyWith(
                color: ColorConstant.emergencyBadge,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
