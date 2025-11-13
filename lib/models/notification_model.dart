import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';
import 'package:juan_heart/models/notification_category.dart';

part 'notification_model.g.dart';

/// Model representing a notification in Juan Heart Mobile.
/// Supports offline-first architecture with Hive storage.
@HiveType(typeId: 0)
class NotificationModel extends Equatable {
  /// Unique identifier for the notification
  @HiveField(0)
  final String id;

  /// Notification title
  @HiveField(1)
  final String title;

  /// Notification body text
  @HiveField(2)
  final String body;

  /// Category for filtering and styling
  @HiveField(3)
  final NotificationCategory category;

  /// When the notification was created
  @HiveField(4)
  final DateTime timestamp;

  /// Whether the notification has been read
  @HiveField(5)
  final bool isRead;

  /// Additional data payload (e.g., appointment ID, assessment ID)
  @HiveField(6)
  final Map<String, dynamic>? payload;

  /// Optional image URL
  @HiveField(7)
  final String? imageUrl;

  /// Optional action URL or deep link
  @HiveField(8)
  final String? actionUrl;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.timestamp,
    this.isRead = false,
    this.payload,
    this.imageUrl,
    this.actionUrl,
  });

  /// Create a copy with modified fields
  NotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    NotificationCategory? category,
    DateTime? timestamp,
    bool? isRead,
    Map<String, dynamic>? payload,
    String? imageUrl,
    String? actionUrl,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      category: category ?? this.category,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      payload: payload ?? this.payload,
      imageUrl: imageUrl ?? this.imageUrl,
      actionUrl: actionUrl ?? this.actionUrl,
    );
  }

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'category': category.value,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isRead': isRead,
      'payload': payload,
      'imageUrl': imageUrl,
      'actionUrl': actionUrl,
    };
  }

  /// Create from JSON
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      category: NotificationCategoryExtension.fromString(
        json['category'] as String? ?? 'system'
      ),
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        json['timestamp'] as int
      ),
      isRead: json['isRead'] as bool? ?? false,
      payload: json['payload'] as Map<String, dynamic>?,
      imageUrl: json['imageUrl'] as String?,
      actionUrl: json['actionUrl'] as String?,
    );
  }

  /// Validate notification data
  bool isValid() {
    return id.isNotEmpty && title.isNotEmpty && body.isNotEmpty;
  }

  /// Check if notification is recent (within last 7 days)
  bool get isRecent {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    return difference.inDays <= 7;
  }

  /// Check if notification is today
  bool get isToday {
    final now = DateTime.now();
    return timestamp.year == now.year &&
           timestamp.month == now.month &&
           timestamp.day == now.day;
  }

  /// Factory: Create assessment notification
  factory NotificationModel.assessment({
    required String id,
    required String title,
    required String body,
    Map<String, dynamic>? payload,
    String? actionUrl,
  }) {
    return NotificationModel(
      id: id,
      title: title,
      body: body,
      category: NotificationCategory.assessment,
      timestamp: DateTime.now(),
      payload: payload,
      actionUrl: actionUrl,
    );
  }

  /// Factory: Create appointment notification
  factory NotificationModel.appointment({
    required String id,
    required String title,
    required String body,
    Map<String, dynamic>? payload,
    String? actionUrl,
  }) {
    return NotificationModel(
      id: id,
      title: title,
      body: body,
      category: NotificationCategory.appointment,
      timestamp: DateTime.now(),
      payload: payload,
      actionUrl: actionUrl,
    );
  }

  /// Factory: Create health alert notification
  factory NotificationModel.healthAlert({
    required String id,
    required String title,
    required String body,
    Map<String, dynamic>? payload,
    String? imageUrl,
  }) {
    return NotificationModel(
      id: id,
      title: title,
      body: body,
      category: NotificationCategory.healthAlert,
      timestamp: DateTime.now(),
      payload: payload,
      imageUrl: imageUrl,
    );
  }

  /// Factory: Create follow-up notification
  factory NotificationModel.followUp({
    required String id,
    required String title,
    required String body,
    Map<String, dynamic>? payload,
    String? actionUrl,
  }) {
    return NotificationModel(
      id: id,
      title: title,
      body: body,
      category: NotificationCategory.followUp,
      timestamp: DateTime.now(),
      payload: payload,
      actionUrl: actionUrl,
    );
  }

  /// Factory: Create system notification
  factory NotificationModel.system({
    required String id,
    required String title,
    required String body,
    Map<String, dynamic>? payload,
    String? actionUrl,
  }) {
    return NotificationModel(
      id: id,
      title: title,
      body: body,
      category: NotificationCategory.system,
      timestamp: DateTime.now(),
      payload: payload,
      actionUrl: actionUrl,
    );
  }

  /// Factory: Create from Firebase message data
  factory NotificationModel.fromFCMData({
    required String id,
    required Map<String, dynamic> data,
  }) {
    final category = NotificationCategoryExtension.fromString(
      data['type'] as String? ?? 'system'
    );

    return NotificationModel(
      id: id,
      title: data['title'] as String? ?? 'Juan Heart',
      body: data['body'] as String? ?? '',
      category: category,
      timestamp: DateTime.now(),
      payload: data,
      imageUrl: data['imageUrl'] as String?,
      actionUrl: data['actionUrl'] as String?,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    body,
    category,
    timestamp,
    isRead,
    payload,
    imageUrl,
    actionUrl,
  ];

  @override
  String toString() {
    return 'NotificationModel(id: $id, title: $title, category: $category, '
        'isRead: $isRead, timestamp: $timestamp)';
  }
}
