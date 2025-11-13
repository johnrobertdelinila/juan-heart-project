/// Error types for sync operations with user-friendly messages
///
/// Maps technical errors to actionable user messages
/// Used for error handling and user notification generation
enum SyncErrorType {
  network,
  authentication,
  validation,
  server,
  timeout,
  unknown,
}

/// Extensions for SyncErrorType
extension SyncErrorTypeExtension on SyncErrorType {
  /// Get user-friendly title for the error type
  String get title {
    switch (this) {
      case SyncErrorType.network:
        return 'Connection Issue';
      case SyncErrorType.authentication:
        return 'Authentication Required';
      case SyncErrorType.validation:
        return 'Data Validation Error';
      case SyncErrorType.server:
        return 'Server Error';
      case SyncErrorType.timeout:
        return 'Connection Timeout';
      case SyncErrorType.unknown:
        return 'Sync Failed';
    }
  }

  /// Get user-friendly message for the error type
  String get message {
    switch (this) {
      case SyncErrorType.network:
        return 'Unable to connect to the server. Please check your internet connection and try again.';
      case SyncErrorType.authentication:
        return 'Your session has expired. Please log in again to continue.';
      case SyncErrorType.validation:
        return 'Some data could not be validated. Please review your assessment and try again.';
      case SyncErrorType.server:
        return 'The server is experiencing issues. Please try again later.';
      case SyncErrorType.timeout:
        return 'The connection timed out. Please check your internet and try again.';
      case SyncErrorType.unknown:
        return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Get action text for user notification
  String get actionText {
    switch (this) {
      case SyncErrorType.network:
      case SyncErrorType.timeout:
        return 'Retry';
      case SyncErrorType.authentication:
        return 'Sign In';
      case SyncErrorType.validation:
        return 'Review';
      case SyncErrorType.server:
      case SyncErrorType.unknown:
        return 'Retry Later';
    }
  }

  /// Get icon name for Material Design icons
  String get iconName {
    switch (this) {
      case SyncErrorType.network:
        return 'wifi_off';
      case SyncErrorType.authentication:
        return 'lock';
      case SyncErrorType.validation:
        return 'error_outline';
      case SyncErrorType.server:
        return 'cloud_off';
      case SyncErrorType.timeout:
        return 'schedule';
      case SyncErrorType.unknown:
        return 'warning';
    }
  }

  /// Get retry strategy for this error type
  ///
  /// Returns true if automatic retry is recommended
  bool get shouldAutoRetry {
    switch (this) {
      case SyncErrorType.network:
      case SyncErrorType.timeout:
      case SyncErrorType.server:
        return true;
      case SyncErrorType.authentication:
      case SyncErrorType.validation:
      case SyncErrorType.unknown:
        return false;
    }
  }

  /// Get backoff multiplier for retry delay
  ///
  /// Higher multiplier = longer backoff between retries
  int get backoffMultiplier {
    switch (this) {
      case SyncErrorType.network:
      case SyncErrorType.timeout:
        return 1; // Standard exponential backoff
      case SyncErrorType.server:
        return 2; // Longer backoff for server errors
      case SyncErrorType.authentication:
      case SyncErrorType.validation:
      case SyncErrorType.unknown:
        return 0; // No auto-retry
    }
  }
}

/// Sync error classifier - maps HTTP status codes and exceptions to error types
class SyncErrorClassifier {
  /// Classify error from HTTP status code
  static SyncErrorType fromStatusCode(int statusCode) {
    if (statusCode == 401 || statusCode == 403) {
      return SyncErrorType.authentication;
    } else if (statusCode == 422) {
      return SyncErrorType.validation;
    } else if (statusCode >= 500 && statusCode < 600) {
      return SyncErrorType.server;
    } else if (statusCode == 408) {
      return SyncErrorType.timeout;
    } else {
      return SyncErrorType.unknown;
    }
  }

  /// Classify error from exception message
  static SyncErrorType fromException(Exception exception) {
    final message = exception.toString().toLowerCase();

    if (message.contains('timeout') || message.contains('timed out')) {
      return SyncErrorType.timeout;
    } else if (message.contains('network') ||
        message.contains('connection') ||
        message.contains('socket')) {
      return SyncErrorType.network;
    } else if (message.contains('unauthorized') || message.contains('401')) {
      return SyncErrorType.authentication;
    } else if (message.contains('validation') || message.contains('422')) {
      return SyncErrorType.validation;
    } else if (message.contains('server') ||
        message.contains('500') ||
        message.contains('503')) {
      return SyncErrorType.server;
    } else {
      return SyncErrorType.unknown;
    }
  }

  /// Classify error from error message string
  static SyncErrorType fromErrorMessage(String errorMessage) {
    final message = errorMessage.toLowerCase();

    if (message.contains('timeout') || message.contains('timed out')) {
      return SyncErrorType.timeout;
    } else if (message.contains('network') ||
        message.contains('connection') ||
        message.contains('offline') ||
        message.contains('no internet')) {
      return SyncErrorType.network;
    } else if (message.contains('unauthorized') ||
        message.contains('authentication') ||
        message.contains('401') ||
        message.contains('403')) {
      return SyncErrorType.authentication;
    } else if (message.contains('validation') ||
        message.contains('invalid') ||
        message.contains('422')) {
      return SyncErrorType.validation;
    } else if (message.contains('server') ||
        message.contains('500') ||
        message.contains('502') ||
        message.contains('503') ||
        message.contains('504')) {
      return SyncErrorType.server;
    } else {
      return SyncErrorType.unknown;
    }
  }

  /// Get user-friendly error message with technical details
  static String getUserFriendlyMessage({
    required SyncErrorType type,
    String? technicalDetails,
    int? statusCode,
  }) {
    final baseMessage = type.message;

    // Don't expose technical details to users, only log them
    return baseMessage;
  }

  /// Extract validation errors from error response
  static Map<String, List<String>>? extractValidationErrors(
    Map<String, dynamic>? errorData,
  ) {
    if (errorData == null || !errorData.containsKey('errors')) {
      return null;
    }

    try {
      final errors = errorData['errors'] as Map<String, dynamic>;
      final result = <String, List<String>>{};

      errors.forEach((key, value) {
        if (value is List) {
          result[key] = value.map((e) => e.toString()).toList();
        } else if (value is String) {
          result[key] = [value];
        } else {
          result[key] = [value.toString()];
        }
      });

      return result;
    } catch (e) {
      return null;
    }
  }
}
