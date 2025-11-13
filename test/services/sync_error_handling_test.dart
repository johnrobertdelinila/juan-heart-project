import 'package:flutter_test/flutter_test.dart';
import 'package:juan_heart/core/constants/sync_error_types.dart';

/// Test suite for sync error handling and classification
///
/// Tests:
/// - Error type classification from status codes
/// - Error type classification from exceptions
/// - Error type classification from error messages
/// - User-friendly message generation
/// - Validation error extraction
/// - Error-specific retry strategies
void main() {
  group('SyncErrorClassifier', () {
    group('fromStatusCode', () {
      test('classifies 401 as authentication error', () {
        final errorType = SyncErrorClassifier.fromStatusCode(401);
        expect(errorType, SyncErrorType.authentication);
      });

      test('classifies 403 as authentication error', () {
        final errorType = SyncErrorClassifier.fromStatusCode(403);
        expect(errorType, SyncErrorType.authentication);
      });

      test('classifies 422 as validation error', () {
        final errorType = SyncErrorClassifier.fromStatusCode(422);
        expect(errorType, SyncErrorType.validation);
      });

      test('classifies 500 as server error', () {
        final errorType = SyncErrorClassifier.fromStatusCode(500);
        expect(errorType, SyncErrorType.server);
      });

      test('classifies 503 as server error', () {
        final errorType = SyncErrorClassifier.fromStatusCode(503);
        expect(errorType, SyncErrorType.server);
      });

      test('classifies 408 as timeout error', () {
        final errorType = SyncErrorClassifier.fromStatusCode(408);
        expect(errorType, SyncErrorType.timeout);
      });

      test('classifies unknown status code as unknown error', () {
        final errorType = SyncErrorClassifier.fromStatusCode(418); // I'm a teapot
        expect(errorType, SyncErrorType.unknown);
      });
    });

    group('fromException', () {
      test('classifies timeout exception', () {
        final exception = Exception('Connection timeout');
        final errorType = SyncErrorClassifier.fromException(exception);
        expect(errorType, SyncErrorType.timeout);
      });

      test('classifies network exception', () {
        final exception = Exception('Network error: No connection');
        final errorType = SyncErrorClassifier.fromException(exception);
        expect(errorType, SyncErrorType.network);
      });

      test('classifies socket exception', () {
        final exception = Exception('Socket exception: Connection refused');
        final errorType = SyncErrorClassifier.fromException(exception);
        expect(errorType, SyncErrorType.network);
      });

      test('classifies authentication exception', () {
        final exception = Exception('Unauthorized: 401');
        final errorType = SyncErrorClassifier.fromException(exception);
        expect(errorType, SyncErrorType.authentication);
      });

      test('classifies validation exception', () {
        final exception = Exception('Validation failed: Invalid data');
        final errorType = SyncErrorClassifier.fromException(exception);
        expect(errorType, SyncErrorType.validation);
      });

      test('classifies server exception', () {
        final exception = Exception('Server error: 500 Internal Server Error');
        final errorType = SyncErrorClassifier.fromException(exception);
        expect(errorType, SyncErrorType.server);
      });

      test('classifies unknown exception', () {
        final exception = Exception('Something went wrong');
        final errorType = SyncErrorClassifier.fromException(exception);
        expect(errorType, SyncErrorType.unknown);
      });
    });

    group('fromErrorMessage', () {
      test('classifies network error message', () {
        final errorType = SyncErrorClassifier.fromErrorMessage(
          'Failed to connect to the network',
        );
        expect(errorType, SyncErrorType.network);
      });

      test('classifies timeout error message', () {
        final errorType = SyncErrorClassifier.fromErrorMessage(
          'Request timed out after 10 seconds',
        );
        expect(errorType, SyncErrorType.timeout);
      });

      test('classifies authentication error message', () {
        final errorType = SyncErrorClassifier.fromErrorMessage(
          'Authentication required: 401 Unauthorized',
        );
        expect(errorType, SyncErrorType.authentication);
      });

      test('classifies validation error message', () {
        final errorType = SyncErrorClassifier.fromErrorMessage(
          'Validation error: Invalid email format',
        );
        expect(errorType, SyncErrorType.validation);
      });

      test('classifies server error message', () {
        final errorType = SyncErrorClassifier.fromErrorMessage(
          'Server error: 503 Service Unavailable',
        );
        expect(errorType, SyncErrorType.server);
      });

      test('classifies offline error message', () {
        final errorType = SyncErrorClassifier.fromErrorMessage(
          'Device is offline, cannot sync',
        );
        expect(errorType, SyncErrorType.network);
      });
    });

    group('getUserFriendlyMessage', () {
      test('returns user-friendly message without technical details', () {
        final message = SyncErrorClassifier.getUserFriendlyMessage(
          type: SyncErrorType.network,
          technicalDetails: 'Socket connection refused on port 8000',
          statusCode: null,
        );

        // Should return base message without exposing technical details
        expect(message, SyncErrorType.network.message);
        expect(message, contains('check your internet'));
        expect(message, isNot(contains('Socket')));
        expect(message, isNot(contains('port 8000')));
      });

      test('returns authentication message', () {
        final message = SyncErrorClassifier.getUserFriendlyMessage(
          type: SyncErrorType.authentication,
          statusCode: 401,
        );

        expect(message, SyncErrorType.authentication.message);
        expect(message, contains('log in again'));
      });

      test('returns validation message', () {
        final message = SyncErrorClassifier.getUserFriendlyMessage(
          type: SyncErrorType.validation,
        );

        expect(message, SyncErrorType.validation.message);
        expect(message, contains('review your assessment'));
      });
    });

    group('extractValidationErrors', () {
      test('extracts validation errors from error response', () {
        final errorData = {
          'errors': {
            'email': ['Email is required', 'Email must be valid'],
            'age': ['Age must be greater than 0'],
          },
        };

        final validationErrors = SyncErrorClassifier.extractValidationErrors(errorData);

        expect(validationErrors, isNotNull);
        expect(validationErrors!['email'], hasLength(2));
        expect(validationErrors['email'], contains('Email is required'));
        expect(validationErrors['age'], hasLength(1));
        expect(validationErrors['age'], contains('Age must be greater than 0'));
      });

      test('handles string error values', () {
        final errorData = {
          'errors': {
            'name': 'Name is required',
          },
        };

        final validationErrors = SyncErrorClassifier.extractValidationErrors(errorData);

        expect(validationErrors, isNotNull);
        expect(validationErrors!['name'], hasLength(1));
        expect(validationErrors['name'], contains('Name is required'));
      });

      test('returns null when no errors field present', () {
        final errorData = {'message': 'Something went wrong'};

        final validationErrors = SyncErrorClassifier.extractValidationErrors(errorData);

        expect(validationErrors, isNull);
      });

      test('returns null when error data is null', () {
        final validationErrors = SyncErrorClassifier.extractValidationErrors(null);

        expect(validationErrors, isNull);
      });
    });
  });

  group('SyncErrorType Extensions', () {
    test('network error has correct properties', () {
      const errorType = SyncErrorType.network;

      expect(errorType.title, 'Connection Issue');
      expect(errorType.message, contains('check your internet'));
      expect(errorType.actionText, 'Retry');
      expect(errorType.iconName, 'wifi_off');
      expect(errorType.shouldAutoRetry, true);
      expect(errorType.backoffMultiplier, 1);
    });

    test('authentication error has correct properties', () {
      const errorType = SyncErrorType.authentication;

      expect(errorType.title, 'Authentication Required');
      expect(errorType.message, contains('log in again'));
      expect(errorType.actionText, 'Sign In');
      expect(errorType.iconName, 'lock');
      expect(errorType.shouldAutoRetry, false);
      expect(errorType.backoffMultiplier, 0); // No auto-retry
    });

    test('validation error has correct properties', () {
      const errorType = SyncErrorType.validation;

      expect(errorType.title, 'Data Validation Error');
      expect(errorType.message, contains('review your assessment'));
      expect(errorType.actionText, 'Review');
      expect(errorType.iconName, 'error_outline');
      expect(errorType.shouldAutoRetry, false);
      expect(errorType.backoffMultiplier, 0); // No auto-retry
    });

    test('server error has correct properties', () {
      const errorType = SyncErrorType.server;

      expect(errorType.title, 'Server Error');
      expect(errorType.message, contains('server is experiencing issues'));
      expect(errorType.actionText, 'Retry Later');
      expect(errorType.iconName, 'cloud_off');
      expect(errorType.shouldAutoRetry, true);
      expect(errorType.backoffMultiplier, 2); // Longer backoff
    });

    test('timeout error has correct properties', () {
      const errorType = SyncErrorType.timeout;

      expect(errorType.title, 'Connection Timeout');
      expect(errorType.message, contains('connection timed out'));
      expect(errorType.actionText, 'Retry');
      expect(errorType.iconName, 'schedule');
      expect(errorType.shouldAutoRetry, true);
      expect(errorType.backoffMultiplier, 1);
    });

    test('unknown error has correct properties', () {
      const errorType = SyncErrorType.unknown;

      expect(errorType.title, 'Sync Failed');
      expect(errorType.message, contains('unexpected error'));
      expect(errorType.actionText, 'Retry Later');
      expect(errorType.iconName, 'warning');
      expect(errorType.shouldAutoRetry, false);
      expect(errorType.backoffMultiplier, 0);
    });
  });

  group('Error-Aware Retry Strategy', () {
    test('network errors should auto-retry with standard backoff', () {
      const errorType = SyncErrorType.network;

      expect(errorType.shouldAutoRetry, true);
      expect(errorType.backoffMultiplier, 1);
    });

    test('server errors should auto-retry with longer backoff', () {
      const errorType = SyncErrorType.server;

      expect(errorType.shouldAutoRetry, true);
      expect(errorType.backoffMultiplier, 2);
    });

    test('authentication errors should not auto-retry', () {
      const errorType = SyncErrorType.authentication;

      expect(errorType.shouldAutoRetry, false);
      expect(errorType.backoffMultiplier, 0);
    });

    test('validation errors should not auto-retry', () {
      const errorType = SyncErrorType.validation;

      expect(errorType.shouldAutoRetry, false);
      expect(errorType.backoffMultiplier, 0);
    });
  });
}
