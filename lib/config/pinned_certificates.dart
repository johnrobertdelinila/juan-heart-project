/// SSL Certificate Pinning Configuration
///
/// SECURITY CRITICAL: This file contains SSL certificate pins for all critical endpoints.
/// Certificate pins prevent Man-in-the-Middle (MITM) attacks by validating server certificates
/// against known good values.
///
/// IMPORTANT:
/// - Update pins before certificates expire
/// - Always maintain backup pins
/// - Test thoroughly before production deployment
/// - Monitor pinning failures in production
///
/// Certificate Rotation Strategy:
/// 1. Add new certificate pin to backupPins 90 days before expiry
/// 2. Deploy app update with both old and new pins
/// 3. After 30 days, promote new pin to primary
/// 4. Remove old pin after 60 days (ensure user base updated)
///
/// Emergency Bypass:
/// - Use CERTIFICATE_PINNING_ENABLED environment variable
/// - Only disable in development/staging environments
/// - NEVER bypass in production builds

import 'package:flutter/foundation.dart';

class PinnedCertificates {
  /// Enable/disable certificate pinning globally
  /// Production builds MUST have this enabled
  static bool get isEnabled {
    // Always enabled in release mode
    if (kReleaseMode) return true;

    // In debug/profile mode, check environment variable
    const envEnabled = bool.fromEnvironment(
      'CERTIFICATE_PINNING_ENABLED',
      defaultValue: false, // Disabled by default for development
    );
    return envEnabled;
  }

  /// Juan Heart Backend API Pins
  /// Base URL: http://172.20.10.6:8000 (Development)
  /// Production URL: TBD
  ///
  /// TODO: Replace with actual production SSL certificate pins
  /// These are placeholder values for demonstration
  static const juanHeartBackendPins = JuanHeartBackendPins();

  /// Genkit AI Assessment Service Pins
  /// URL: https://us-central1-juan-heart-project.cloudfunctions.net
  /// This is a Google Cloud Function with Google-managed certificates
  static const genkitServicePins = GenkitServicePins();

  /// Educational Content API Pins
  /// URL: http://192.168.1.8:8000 (Development)
  /// Production URL: TBD
  static const educationalContentPins = EducationalContentPins();

  /// Google APIs Pins (Geocoding, etc.)
  /// URL: https://maps.googleapis.com
  static const googleApisPins = GoogleApisPins();

  /// Twilio API Pins (if direct API calls are made)
  /// URL: https://api.twilio.com
  static const twilioApisPins = TwilioApisPins();
}

/// Juan Heart Backend Certificate Pins
class JuanHeartBackendPins {
  const JuanHeartBackendPins();

  /// Hostname for certificate validation
  String get hostname => '172.20.10.6'; // Development
  // TODO: Update to production hostname when deployed
  // String get hostname => 'api.juanheart.ph';

  /// Primary certificate SHA-256 fingerprint
  ///
  /// To extract certificate fingerprint from production server:
  /// ```bash
  /// echo | openssl s_client -servername api.juanheart.ph -connect api.juanheart.ph:443 2>/dev/null | openssl x509 -pubkey -noout | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | openssl enc -base64
  /// ```
  String get primaryPin => 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=';

  /// Backup certificate pins for rotation
  /// Always maintain at least one backup pin
  List<String> get backupPins => [
    'BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=',
    'CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC=',
  ];

  /// All valid pins (primary + backups)
  List<String> get allPins => [primaryPin, ...backupPins];

  /// Certificate expiry date for monitoring
  /// Format: YYYY-MM-DD
  String get primaryExpiryDate => '2026-01-01';

  /// Days before expiry to trigger rotation warning
  int get rotationWarningDays => 90;
}

/// Genkit AI Assessment Service Certificate Pins
class GenkitServicePins {
  const GenkitServicePins();

  String get hostname => 'us-central1-juan-heart-project.cloudfunctions.net';

  /// Google Cloud Platform uses Google Trust Services certificates
  /// These rotate regularly, so we pin to the intermediate CA
  ///
  /// GTS CA 1C3 (Google Trust Services - valid until 2027)
  String get primaryPin => 'f0LhF+9bsRQC8UzS/Z2Aw4LQ9t+MNQ9+vZNhXwNXXXX=';

  /// Backup pins for Google's certificate rotation
  List<String> get backupPins => [
    // GTS Root R1
    'hxqRlPTu1bMS/0DITB1SSu0vd4u/8l8TjPgfaAp63Gc=',
    // GlobalSign Root CA - R2 (backup CA)
    'iie1VXtL7HzAMF+/PVPR9xzT80kQxdZeJ+zduCB3uj0=',
  ];

  List<String> get allPins => [primaryPin, ...backupPins];
  String get primaryExpiryDate => '2027-12-31';
  int get rotationWarningDays => 180;
}

/// Educational Content API Certificate Pins
class EducationalContentPins {
  const EducationalContentPins();

  String get hostname => '192.168.1.8'; // Development
  // TODO: Update to production hostname
  // String get hostname => 'content.juanheart.ph';

  String get primaryPin => 'DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD=';

  List<String> get backupPins => [
    'EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE=',
  ];

  List<String> get allPins => [primaryPin, ...backupPins];
  String get primaryExpiryDate => '2026-01-01';
  int get rotationWarningDays => 90;
}

/// Google APIs Certificate Pins
class GoogleApisPins {
  const GoogleApisPins();

  String get hostname => 'maps.googleapis.com';

  /// Google APIs use Google Trust Services certificates
  String get primaryPin => 'f0LhF+9bsRQC8UzS/Z2Aw4LQ9t+MNQ9+vZNhXwNXXXX=';

  List<String> get backupPins => [
    'hxqRlPTu1bMS/0DITB1SSu0vd4u/8l8TjPgfaAp63Gc=',
    'iie1VXtL7HzAMF+/PVPR9xzT80kQxdZeJ+zduCB3uj0=',
  ];

  List<String> get allPins => [primaryPin, ...backupPins];
  String get primaryExpiryDate => '2027-12-31';
  int get rotationWarningDays => 180;
}

/// Twilio API Certificate Pins
class TwilioApisPins {
  const TwilioApisPins();

  String get hostname => 'api.twilio.com';

  /// Twilio uses DigiCert certificates
  /// DigiCert Global Root G2 (valid until 2038)
  String get primaryPin => 'i7WTqTvh0OioIruIfFR4kMPnBqrS2rdiVPl/s2uC/CY=';

  List<String> get backupPins => [
    // DigiCert Global Root CA
    'r/mIkG3eEpVdm+u/ko/cwxzOMo1bk4TyHIlByibiA5E=',
    // Baltimore CyberTrust Root (legacy backup)
    'Y9mvm0exBk1JoQ57f9Vm28jKo5lFm/woKcVxrYxu80o=',
  ];

  List<String> get allPins => [primaryPin, ...backupPins];
  String get primaryExpiryDate => '2038-01-01';
  int get rotationWarningDays => 365;
}

/// Certificate Pinning Error Types
class CertificatePinningException implements Exception {
  final String message;
  final String hostname;
  final String? receivedPin;
  final List<String> expectedPins;

  const CertificatePinningException({
    required this.message,
    required this.hostname,
    this.receivedPin,
    required this.expectedPins,
  });

  @override
  String toString() {
    return 'CertificatePinningException: $message\n'
        'Hostname: $hostname\n'
        'Received Pin: ${receivedPin ?? "unknown"}\n'
        'Expected Pins: ${expectedPins.join(", ")}';
  }
}

/// Certificate Rotation Status
class CertificateRotationStatus {
  final String hostname;
  final String expiryDate;
  final int daysUntilExpiry;
  final bool needsRotation;
  final String primaryPin;

  const CertificateRotationStatus({
    required this.hostname,
    required this.expiryDate,
    required this.daysUntilExpiry,
    required this.needsRotation,
    required this.primaryPin,
  });

  bool get isExpired => daysUntilExpiry <= 0;
  bool get isExpiringSoon => daysUntilExpiry <= 90;

  Map<String, dynamic> toJson() {
    return {
      'hostname': hostname,
      'expiryDate': expiryDate,
      'daysUntilExpiry': daysUntilExpiry,
      'needsRotation': needsRotation,
      'isExpired': isExpired,
      'isExpiringSoon': isExpiringSoon,
      'primaryPin': primaryPin,
    };
  }
}
