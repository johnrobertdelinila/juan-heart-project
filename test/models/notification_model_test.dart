import 'package:flutter_test/flutter_test.dart';
import 'package:juan_heart/models/notification_model.dart';
import 'package:juan_heart/models/notification_category.dart';

/// Comprehensive tests for NotificationModel
/// Tests serialization, validation, factory methods, and equality
void main() {
  group('NotificationModel', () {
    late DateTime testTimestamp;

    setUp(() {
      testTimestamp = DateTime(2025, 11, 1, 12, 0, 0);
    });

    group('Constructor and Basic Properties', () {
      test('should create notification with all required fields', () {
        final notification = NotificationModel(
          id: 'test-id-1',
          title: 'Test Notification',
          body: 'Test body',
          category: NotificationCategory.appointment,
          timestamp: testTimestamp,
        );

        expect(notification.id, equals('test-id-1'));
        expect(notification.title, equals('Test Notification'));
        expect(notification.body, equals('Test body'));
        expect(notification.category, equals(NotificationCategory.appointment));
        expect(notification.timestamp, equals(testTimestamp));
        expect(notification.isRead, equals(false)); // Default
        expect(notification.payload, isNull);
        expect(notification.imageUrl, isNull);
        expect(notification.actionUrl, isNull);
      });

      test('should create notification with optional fields', () {
        final payload = {'key': 'value', 'number': 123};
        final notification = NotificationModel(
          id: 'test-id-2',
          title: 'Test Notification',
          body: 'Test body',
          category: NotificationCategory.healthAlert,
          timestamp: testTimestamp,
          isRead: true,
          payload: payload,
          imageUrl: 'https://example.com/image.png',
          actionUrl: 'juanheart://assessment',
        );

        expect(notification.isRead, equals(true));
        expect(notification.payload, equals(payload));
        expect(notification.imageUrl, equals('https://example.com/image.png'));
        expect(notification.actionUrl, equals('juanheart://assessment'));
      });
    });

    group('JSON Serialization', () {
      test('should convert to JSON correctly', () {
        final notification = NotificationModel(
          id: 'json-test-1',
          title: 'JSON Test',
          body: 'Testing JSON serialization',
          category: NotificationCategory.assessment,
          timestamp: testTimestamp,
          isRead: false,
          payload: const {'appointmentId': 'app-123'},
          imageUrl: 'https://example.com/test.jpg',
          actionUrl: 'juanheart://home',
        );

        final json = notification.toJson();

        expect(json['id'], equals('json-test-1'));
        expect(json['title'], equals('JSON Test'));
        expect(json['body'], equals('Testing JSON serialization'));
        expect(json['category'], equals('assessment'));
        expect(json['timestamp'], equals(testTimestamp.millisecondsSinceEpoch));
        expect(json['isRead'], equals(false));
        expect(json['payload'], equals({'appointmentId': 'app-123'}));
        expect(json['imageUrl'], equals('https://example.com/test.jpg'));
        expect(json['actionUrl'], equals('juanheart://home'));
      });

      test('should convert from JSON correctly', () {
        final json = {
          'id': 'from-json-1',
          'title': 'From JSON',
          'body': 'Testing fromJson method',
          'category': 'appointment',
          'timestamp': testTimestamp.millisecondsSinceEpoch,
          'isRead': true,
          'payload': {'facilityId': 'facility-456'},
          'imageUrl': 'https://example.com/from-json.png',
          'actionUrl': 'juanheart://appointments',
        };

        final notification = NotificationModel.fromJson(json);

        expect(notification.id, equals('from-json-1'));
        expect(notification.title, equals('From JSON'));
        expect(notification.body, equals('Testing fromJson method'));
        expect(notification.category, equals(NotificationCategory.appointment));
        expect(notification.timestamp, equals(testTimestamp));
        expect(notification.isRead, equals(true));
        expect(notification.payload, equals({'facilityId': 'facility-456'}));
        expect(notification.imageUrl, equals('https://example.com/from-json.png'));
        expect(notification.actionUrl, equals('juanheart://appointments'));
      });

      test('should handle fromJson with missing optional fields', () {
        final json = {
          'id': 'minimal-json',
          'title': 'Minimal',
          'body': 'Minimal JSON',
          'category': 'system',
          'timestamp': testTimestamp.millisecondsSinceEpoch,
        };

        final notification = NotificationModel.fromJson(json);

        expect(notification.id, equals('minimal-json'));
        expect(notification.title, equals('Minimal'));
        expect(notification.body, equals('Minimal JSON'));
        expect(notification.category, equals(NotificationCategory.system));
        expect(notification.isRead, equals(false)); // Default
        expect(notification.payload, isNull);
        expect(notification.imageUrl, isNull);
        expect(notification.actionUrl, isNull);
      });

      test('should handle fromJson with invalid category', () {
        final json = {
          'id': 'invalid-category',
          'title': 'Invalid',
          'body': 'Invalid category test',
          'category': 'invalid_category_name',
          'timestamp': testTimestamp.millisecondsSinceEpoch,
        };

        final notification = NotificationModel.fromJson(json);

        // Should default to system category
        expect(notification.category, equals(NotificationCategory.system));
      });

      test('should roundtrip (toJson -> fromJson) correctly', () {
        final original = NotificationModel(
          id: 'roundtrip-test',
          title: 'Roundtrip Test',
          body: 'Testing roundtrip conversion',
          category: NotificationCategory.followUp,
          timestamp: testTimestamp,
          isRead: true,
          payload: const {'test': 'data', 'nested': {'key': 'value'}},
          imageUrl: 'https://example.com/roundtrip.jpg',
          actionUrl: 'juanheart://follow-up',
        );

        final json = original.toJson();
        final reconstructed = NotificationModel.fromJson(json);

        expect(reconstructed.id, equals(original.id));
        expect(reconstructed.title, equals(original.title));
        expect(reconstructed.body, equals(original.body));
        expect(reconstructed.category, equals(original.category));
        expect(reconstructed.timestamp, equals(original.timestamp));
        expect(reconstructed.isRead, equals(original.isRead));
        expect(reconstructed.payload, equals(original.payload));
        expect(reconstructed.imageUrl, equals(original.imageUrl));
        expect(reconstructed.actionUrl, equals(original.actionUrl));
      });
    });

    group('Factory Methods', () {
      test('should create assessment notification using factory', () {
        final notification = NotificationModel.assessment(
          id: 'assessment-1',
          title: 'Assessment Complete',
          body: 'Your risk assessment is complete',
          payload: const {'assessmentId': 'assess-123', 'score': 15},
        );

        expect(notification.id, equals('assessment-1'));
        expect(notification.title, equals('Assessment Complete'));
        expect(notification.body, equals('Your risk assessment is complete'));
        expect(notification.category, equals(NotificationCategory.assessment));
        expect(notification.payload, equals({'assessmentId': 'assess-123', 'score': 15}));
        expect(notification.isRead, equals(false));
      });

      test('should create appointment notification using factory', () {
        final notification = NotificationModel.appointment(
          id: 'appointment-1',
          title: 'Appointment Tomorrow',
          body: 'You have an appointment at City Hospital',
          payload: const {'appointmentId': 'app-456'},
        );

        expect(notification.id, equals('appointment-1'));
        expect(notification.title, equals('Appointment Tomorrow'));
        expect(notification.category, equals(NotificationCategory.appointment));
        expect(notification.payload, equals({'appointmentId': 'app-456'}));
      });

      test('should create health alert notification using factory', () {
        final notification = NotificationModel.healthAlert(
          id: 'alert-1',
          title: 'Critical Health Alert',
          body: 'Please seek immediate medical attention',
          payload: const {'severity': 'critical'},
          imageUrl: 'https://example.com/alert.png',
        );

        expect(notification.id, equals('alert-1'));
        expect(notification.title, equals('Critical Health Alert'));
        expect(notification.category, equals(NotificationCategory.healthAlert));
        expect(notification.imageUrl, equals('https://example.com/alert.png'));
        expect(notification.payload, equals({'severity': 'critical'}));
      });

      test('should create follow-up notification using factory', () {
        final notification = NotificationModel.followUp(
          id: 'followup-1',
          title: 'Follow-up: How are you feeling?',
          body: 'Take a reassessment to track your progress',
          payload: const {'appointmentId': 'app-789'},
        );

        expect(notification.id, equals('followup-1'));
        expect(notification.title, equals('Follow-up: How are you feeling?'));
        expect(notification.category, equals(NotificationCategory.followUp));
        expect(notification.payload, equals({'appointmentId': 'app-789'}));
      });

      test('should create system notification using factory', () {
        final notification = NotificationModel.system(
          id: 'system-1',
          title: 'System Update',
          body: 'Juan Heart has been updated to version 2.0',
        );

        expect(notification.id, equals('system-1'));
        expect(notification.title, equals('System Update'));
        expect(notification.category, equals(NotificationCategory.system));
      });

      test('should create from FCM data', () {
        final fcmData = {
          'type': 'appointment',
          'title': 'FCM Notification',
          'body': 'From Firebase',
          'imageUrl': 'https://example.com/fcm.png',
          'actionUrl': 'juanheart://appointments',
          'appointmentId': 'fcm-app-123',
        };

        final notification = NotificationModel.fromFCMData(
          id: 'fcm-1',
          data: fcmData,
        );

        expect(notification.id, equals('fcm-1'));
        expect(notification.title, equals('FCM Notification'));
        expect(notification.body, equals('From Firebase'));
        expect(notification.category, equals(NotificationCategory.appointment));
        expect(notification.imageUrl, equals('https://example.com/fcm.png'));
        expect(notification.actionUrl, equals('juanheart://appointments'));
        expect(notification.payload, equals(fcmData));
      });

      test('should handle FCM data with defaults', () {
        final fcmData = <String, dynamic>{};

        final notification = NotificationModel.fromFCMData(
          id: 'fcm-default',
          data: fcmData,
        );

        expect(notification.id, equals('fcm-default'));
        expect(notification.title, equals('Juan Heart')); // Default title
        expect(notification.body, equals('')); // Default body
        expect(notification.category, equals(NotificationCategory.system)); // Default
      });
    });

    group('CopyWith', () {
      test('should copy with modified fields', () {
        final original = NotificationModel(
          id: 'original-id',
          title: 'Original Title',
          body: 'Original Body',
          category: NotificationCategory.appointment,
          timestamp: testTimestamp,
          isRead: false,
        );

        final copied = original.copyWith(
          title: 'Updated Title',
          isRead: true,
        );

        expect(copied.id, equals('original-id')); // Unchanged
        expect(copied.title, equals('Updated Title')); // Changed
        expect(copied.body, equals('Original Body')); // Unchanged
        expect(copied.isRead, equals(true)); // Changed
        expect(copied.category, equals(NotificationCategory.appointment)); // Unchanged
      });

      test('should copy with all fields modified', () {
        final original = NotificationModel(
          id: 'id-1',
          title: 'Title 1',
          body: 'Body 1',
          category: NotificationCategory.system,
          timestamp: testTimestamp,
        );

        final newTimestamp = testTimestamp.add(const Duration(days: 1));
        final copied = original.copyWith(
          id: 'id-2',
          title: 'Title 2',
          body: 'Body 2',
          category: NotificationCategory.healthAlert,
          timestamp: newTimestamp,
          isRead: true,
          payload: {'key': 'value'},
          imageUrl: 'https://example.com/new.png',
          actionUrl: 'juanheart://new',
        );

        expect(copied.id, equals('id-2'));
        expect(copied.title, equals('Title 2'));
        expect(copied.body, equals('Body 2'));
        expect(copied.category, equals(NotificationCategory.healthAlert));
        expect(copied.timestamp, equals(newTimestamp));
        expect(copied.isRead, equals(true));
        expect(copied.payload, equals({'key': 'value'}));
        expect(copied.imageUrl, equals('https://example.com/new.png'));
        expect(copied.actionUrl, equals('juanheart://new'));
      });
    });

    group('Validation', () {
      test('should validate correct notification', () {
        final notification = NotificationModel(
          id: 'valid-id',
          title: 'Valid Title',
          body: 'Valid Body',
          category: NotificationCategory.appointment,
          timestamp: testTimestamp,
        );

        expect(notification.isValid(), equals(true));
      });

      test('should invalidate notification with empty id', () {
        final notification = NotificationModel(
          id: '',
          title: 'Valid Title',
          body: 'Valid Body',
          category: NotificationCategory.appointment,
          timestamp: testTimestamp,
        );

        expect(notification.isValid(), equals(false));
      });

      test('should invalidate notification with empty title', () {
        final notification = NotificationModel(
          id: 'valid-id',
          title: '',
          body: 'Valid Body',
          category: NotificationCategory.appointment,
          timestamp: testTimestamp,
        );

        expect(notification.isValid(), equals(false));
      });

      test('should invalidate notification with empty body', () {
        final notification = NotificationModel(
          id: 'valid-id',
          title: 'Valid Title',
          body: '',
          category: NotificationCategory.appointment,
          timestamp: testTimestamp,
        );

        expect(notification.isValid(), equals(false));
      });
    });

    group('Date Helpers', () {
      test('should identify recent notification (within 7 days)', () {
        final recentNotification = NotificationModel(
          id: 'recent',
          title: 'Recent',
          body: 'Recent notification',
          category: NotificationCategory.system,
          timestamp: DateTime.now().subtract(const Duration(days: 3)),
        );

        expect(recentNotification.isRecent, equals(true));
      });

      test('should identify old notification (older than 7 days)', () {
        final oldNotification = NotificationModel(
          id: 'old',
          title: 'Old',
          body: 'Old notification',
          category: NotificationCategory.system,
          timestamp: DateTime.now().subtract(const Duration(days: 10)),
        );

        expect(oldNotification.isRecent, equals(false));
      });

      test('should identify notification from today', () {
        final todayNotification = NotificationModel(
          id: 'today',
          title: 'Today',
          body: 'Today notification',
          category: NotificationCategory.system,
          timestamp: DateTime.now(),
        );

        expect(todayNotification.isToday, equals(true));
      });

      test('should identify notification not from today', () {
        final yesterdayNotification = NotificationModel(
          id: 'yesterday',
          title: 'Yesterday',
          body: 'Yesterday notification',
          category: NotificationCategory.system,
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
        );

        expect(yesterdayNotification.isToday, equals(false));
      });
    });

    group('Equatable', () {
      test('should be equal when all properties match', () {
        final notification1 = NotificationModel(
          id: 'eq-1',
          title: 'Equality Test',
          body: 'Testing equality',
          category: NotificationCategory.appointment,
          timestamp: testTimestamp,
          isRead: false,
          payload: const {'key': 'value'},
        );

        final notification2 = NotificationModel(
          id: 'eq-1',
          title: 'Equality Test',
          body: 'Testing equality',
          category: NotificationCategory.appointment,
          timestamp: testTimestamp,
          isRead: false,
          payload: const {'key': 'value'},
        );

        expect(notification1, equals(notification2));
      });

      test('should not be equal when id differs', () {
        final notification1 = NotificationModel(
          id: 'eq-1',
          title: 'Test',
          body: 'Test',
          category: NotificationCategory.appointment,
          timestamp: testTimestamp,
        );

        final notification2 = NotificationModel(
          id: 'eq-2',
          title: 'Test',
          body: 'Test',
          category: NotificationCategory.appointment,
          timestamp: testTimestamp,
        );

        expect(notification1, isNot(equals(notification2)));
      });

      test('should not be equal when isRead differs', () {
        final notification1 = NotificationModel(
          id: 'eq-1',
          title: 'Test',
          body: 'Test',
          category: NotificationCategory.appointment,
          timestamp: testTimestamp,
          isRead: false,
        );

        final notification2 = NotificationModel(
          id: 'eq-1',
          title: 'Test',
          body: 'Test',
          category: NotificationCategory.appointment,
          timestamp: testTimestamp,
          isRead: true,
        );

        expect(notification1, isNot(equals(notification2)));
      });
    });

    group('toString', () {
      test('should provide readable string representation', () {
        final notification = NotificationModel(
          id: 'string-test',
          title: 'String Test',
          body: 'Testing toString',
          category: NotificationCategory.appointment,
          timestamp: testTimestamp,
          isRead: true,
        );

        final stringRep = notification.toString();

        expect(stringRep, contains('string-test'));
        expect(stringRep, contains('String Test'));
        expect(stringRep, contains('appointment'));
        expect(stringRep, contains('true')); // isRead
        expect(stringRep, contains(testTimestamp.toString()));
      });
    });
  });
}
