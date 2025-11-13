# PLANNING.md
# Juan Heart Mobile Application
## Technical Planning & Architecture Document

---

**Version:** 2.0
**Last Updated:** January 2025
**Status:** Active Development  
**Team Size:** 3 Developers  
**Platform:** Mobile (Android/iOS) with Web/Desktop support  

---

## 📌 Table of Contents

1. [Project Vision](#1-project-vision)
2. [System Architecture](#2-system-architecture)
3. [Technology Stack](#3-technology-stack)
4. [Required Development Tools](#4-required-development-tools)
5. [Project Structure](#5-project-structure)
6. [Development Workflow](#6-development-workflow)
7. [Infrastructure Requirements](#7-infrastructure-requirements)
8. [Security Architecture](#8-security-architecture)
9. [Data Architecture](#9-data-architecture)
10. [Integration Architecture](#10-integration-architecture)
11. [Deployment Strategy](#11-deployment-strategy)
12. [Monitoring & Observability](#12-monitoring--observability)

---

## 1. 🎯 Project Vision

### 1.1 Mission Statement

> **"To democratize cardiovascular health assessment for every Filipino through accessible, offline-capable, and clinically-validated mobile technology that bridges the gap between communities and healthcare facilities."**

### 1.2 Core Values

| Value | Description | Implementation |
|-------|-------------|----------------|
| **Accessibility** | Works on low-end devices with minimal connectivity | Offline-first architecture, <50MB APK |
| **Clinical Accuracy** | PHC-validated assessments aligned with international guidelines | Rule-based scoring system, ML validation |
| **Cultural Relevance** | Designed for Filipino users | Taglish support, local context |
| **Privacy-First** | Secure handling of health data | End-to-end encryption, local-first data |
| **Equity** | Available to all socioeconomic levels | Free core features, works on 2G/3G |

### 1.3 Strategic Goals

#### **Completed (Q1 2025)**
- ✅ Complete core assessment engine (M1, M2, M3)
- ✅ Implement referral system (M3)
- ✅ Optimize for low-end devices (M1 - 14.49MB APK, <3s launch)
- ✅ Telemedicine foundation (M5, M5.1 - Appointment booking)

#### **Mid-term (Q2-Q3 2025)**
- Telemedicine integration
- Wearable device support
- Advanced analytics dashboard
- 100,000+ active users

#### **Long-term (2026+)**
- National health system integration
- AI-enhanced predictions
- ASEAN market expansion
- 1M+ active users

### 1.4 Success Metrics

```yaml
user_metrics:
  daily_active_users: 10,000
  monthly_active_users: 50,000
  retention_30_day: 40%
  app_store_rating: 4.5+

clinical_metrics:
  assessment_completion_rate: 85%
  referral_completion_rate: 30%
  early_detection_improvement: 25%
  false_positive_rate: <20%

technical_metrics:
  crash_free_rate: 99%
  offline_usage: 30%
  api_response_time: <2s
  app_launch_time: <3s
```

---

## 2. 🏗️ System Architecture

### 2.1 High-Level Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    CLIENT LAYER                          │
├─────────────────────────────────────────────────────────┤
│  Mobile App (Flutter)  │  Web App  │  Desktop App       │
├─────────────────────────────────────────────────────────┤
│                 PRESENTATION LAYER                       │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Widgets  │  Screens  │  Components  │  Themes   │  │
│  └──────────────────────────────────────────────────┘  │
├─────────────────────────────────────────────────────────┤
│                 BUSINESS LOGIC LAYER                     │
│  ┌──────────────────────────────────────────────────┐  │
│  │   BLoCs   │  Services  │  Use Cases  │  Models   │  │
│  └──────────────────────────────────────────────────┘  │
├─────────────────────────────────────────────────────────┤
│                    DATA LAYER                            │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Local DB  │  Remote API  │  Cache  │  File I/O  │  │
│  └──────────────────────────────────────────────────┘  │
├─────────────────────────────────────────────────────────┤
│                  INFRASTRUCTURE LAYER                    │
│  ┌──────────────────────────────────────────────────┐  │
│  │   Network   │  Storage  │  Security  │  Platform  │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────┐
│                    BACKEND SERVICES                      │
├─────────────────────────────────────────────────────────┤
│  Laravel API  │  MySQL DB  │  Redis Cache  │  S3 Storage│
├─────────────────────────────────────────────────────────┤
│                 EXTERNAL INTEGRATIONS                    │
│  Maps API  │  SMS Gateway  │  Payment  │  Telemedicine  │
└─────────────────────────────────────────────────────────┘
```

### 2.2 Component Architecture

```yaml
components:
  presentation:
    - auth_screens:
        - login_screen.dart
        - register_screen.dart
        - forgot_password_screen.dart
    - assessment_screens:
        - symptom_checker_screen.dart
        - vital_signs_screen.dart
        - risk_result_screen.dart
    - referral_screens:
        - facility_list_screen.dart
        - facility_details_screen.dart
        - referral_pdf_screen.dart
    
  business_logic:
    - assessment_bloc:
        - assessment_event.dart
        - assessment_state.dart
        - assessment_bloc.dart
    - referral_bloc:
        - referral_event.dart
        - referral_state.dart
        - referral_bloc.dart
    
  services:
    - assessment_service.dart      # Core risk calculation
    - referral_service.dart        # Facility recommendations
    - sync_service.dart           # Offline sync queue
    - ml_service.dart             # TensorFlow Lite integration
    - pdf_service.dart            # PDF generation
    
  repositories:
    - user_repository.dart         # User data management
    - assessment_repository.dart   # Assessment CRUD
    - facility_repository.dart     # Healthcare facilities
```

### 2.3 Offline-First Architecture

```dart
// Offline-First Data Flow
class OfflineFirstArchitecture {
  // 1. Check local cache first
  Future<Data> getData() async {
    final localData = await localCache.get();
    if (localData != null && !localData.isStale) {
      return localData;
    }
    
    // 2. Try to fetch from remote
    if (await connectivity.isOnline) {
      try {
        final remoteData = await remoteAPI.fetch();
        await localCache.save(remoteData);
        return remoteData;
      } catch (e) {
        // 3. Fall back to stale local data
        return localData ?? DefaultData();
      }
    }
    
    // 4. Return local data when offline
    return localData ?? DefaultData();
  }
  
  // 5. Queue operations when offline
  Future<void> saveData(Data data) async {
    await localCache.save(data);
    
    if (await connectivity.isOnline) {
      await remoteAPI.save(data);
    } else {
      await syncQueue.add(SyncOperation.save(data));
    }
  }
}
```

### 2.4 Microservices Architecture (Backend)

```yaml
backend_services:
  api_gateway:
    - route: /api/v1/*
    - rate_limiting: 100/min
    - authentication: JWT
    
  core_services:
    assessment_service:
      - endpoint: /assessment
      - database: MySQL
      - cache: Redis
      
    referral_service:
      - endpoint: /referral
      - database: MySQL
      - integrations: Maps API
      
    user_service:
      - endpoint: /user
      - database: MySQL
      - auth: Laravel Passport
      
  supporting_services:
    notification_service:
      - push: Firebase FCM
      - sms: Semaphore API
      - email: SendGrid
      
    analytics_service:
      - events: Firebase Analytics
      - custom: Internal DB
      - reporting: Metabase
```

---

## 3. 💻 Technology Stack

### 3.1 Frontend Technologies

| Category | Technology | Version | Purpose |
|----------|-----------|---------|---------|
| **Framework** | Flutter | 3.16+ | Cross-platform development |
| **Language** | Dart | 3.2+ | Primary programming language |
| **State Management** | flutter_bloc | 8.1.3 | BLoC pattern implementation |
| **Navigation** | go_router | 12.1.1 | Declarative routing |
| **Local Database** | Drift | 2.13.0 | SQLite wrapper |
| **Key-Value Store** | Hive | 2.2.3 | Fast local storage |
| **HTTP Client** | Dio | 5.3.4 | Network requests |
| **Dependency Injection** | get_it | 7.6.4 | Service locator |
| **ML Framework** | tflite_flutter | 0.10.3 | On-device ML inference |

### 3.2 Backend Technologies

| Category | Technology | Version | Purpose |
|----------|-----------|---------|---------|
| **Framework** | Laravel | 11.x | API development |
| **Language** | PHP | 8.3+ | Backend programming |
| **Database** | MySQL | 8.0+ | Primary data storage |
| **Cache** | Redis | 7.0+ | Session & cache storage |
| **Queue** | Laravel Horizon | Latest | Job queue management |
| **API Docs** | Laravel Swagger | Latest | API documentation |
| **Authentication** | Laravel Passport | Latest | OAuth2 implementation |
| **File Storage** | AWS S3 | - | Cloud storage |

### 3.3 DevOps & Infrastructure

| Category | Technology | Purpose |
|----------|-----------|---------|
| **Container** | Docker | Containerization |
| **Orchestration** | Kubernetes | Container orchestration |
| **CI/CD** | GitHub Actions | Automated pipelines |
| **Mobile CI/CD** | Fastlane | Mobile deployment |
| **Monitoring** | Prometheus + Grafana | System monitoring |
| **APM** | Firebase Performance | App performance |
| **Error Tracking** | Sentry | Error monitoring |
| **Analytics** | Firebase Analytics | User analytics |

### 3.4 Third-Party Services

```yaml
essential_services:
  maps_and_location:
    provider: Google Maps
    features:
      - Geocoding API
      - Places API
      - Distance Matrix API
    cost: $200/month (estimated)
  
  push_notifications:
    provider: Firebase Cloud Messaging
    features:
      - iOS/Android push
      - Topic messaging
      - Scheduled notifications
    cost: Free tier sufficient
  
  sms_gateway:
    provider: Semaphore (Philippines)
    features:
      - OTP verification
      - Appointment reminders
      - Emergency alerts
    cost: ₱1/SMS
  
  cloud_storage:
    provider: AWS S3
    features:
      - PDF storage
      - Image storage
      - Backup storage
    cost: $50/month (estimated)

optional_services:
  payment_gateway:
    provider: PayMongo
    features:
      - Credit/debit cards
      - GCash/PayMaya
      - Bank transfers
    
  telemedicine:
    provider: Agora.io
    features:
      - Video calling
      - Screen sharing
      - Recording
    
  email_service:
    provider: SendGrid
    features:
      - Transactional emails
      - Templates
      - Analytics
```

---

## 4. 🛠️ Required Development Tools

### 4.1 Development Environment

```bash
# Core Development Tools
├── IDE & Editors
│   ├── Visual Studio Code         # Primary IDE
│   │   ├── Flutter extension
│   │   ├── Dart extension
│   │   ├── Bloc extension
│   │   └── GitLens
│   ├── Android Studio             # Android development
│   └── Xcode                      # iOS development
│
├── Version Control
│   ├── Git                        # Version control
│   ├── GitHub Desktop             # GUI for Git
│   └── GitKraken                  # Advanced Git GUI
│
├── API Testing
│   ├── Postman                    # API testing
│   ├── Insomnia                   # Alternative API client
│   └── Thunder Client (VSCode)    # VSCode extension
│
└── Database Tools
    ├── TablePlus                  # Database GUI
    ├── phpMyAdmin                 # Web-based MySQL
    └── Redis Desktop Manager      # Redis GUI
```

### 4.2 Flutter Development Dependencies

```yaml
# pubspec.yaml
name: juan_heart
description: National CVD Clinical Decision Tool

environment:
  sdk: ">=3.0.0 <4.0.0"
  flutter: ">=3.16.0"

dependencies:
  flutter:
    sdk: flutter
  
  # Core Architecture
  flutter_bloc: ^8.1.3          # State management
  get_it: ^7.6.4                # Dependency injection
  injectable: ^2.3.2            # Code generation for DI
  equatable: ^2.0.5             # Value equality
  
  # Navigation & Routing
  go_router: ^12.1.1            # Declarative routing
  
  # Local Storage
  drift: ^2.13.0                # SQLite ORM
  drift_flutter: ^0.1.0         # Flutter integration
  hive_flutter: ^1.1.0          # Key-value storage
  shared_preferences: ^2.2.2    # Simple preferences
  flutter_secure_storage: ^9.0.0 # Secure storage
  
  # Networking
  dio: ^5.3.4                   # HTTP client
  connectivity_plus: ^5.0.2     # Network connectivity
  pretty_dio_logger: ^1.3.1     # Network logging
  
  # UI Components
  flutter_screenutil: ^5.9.0    # Responsive design
  cached_network_image: ^3.3.0  # Image caching
  shimmer: ^3.0.0              # Loading skeletons
  lottie: ^2.7.0               # Animations
  flutter_svg: ^2.0.9          # SVG support
  
  # Forms & Validation
  flutter_form_builder: ^9.1.1  # Form builder
  form_builder_validators: ^9.1.0 # Validators
  
  # PDF Generation
  pdf: ^3.10.7                  # PDF creation
  printing: ^5.11.1            # PDF printing
  
  # QR Code
  qr_flutter: ^4.1.0           # QR generation
  qr_code_scanner: ^1.0.1      # QR scanning
  
  # Maps & Location
  google_maps_flutter: ^2.5.0  # Google Maps
  geolocator: ^10.1.0          # Location services
  geocoding: ^2.1.1            # Geocoding
  
  # Machine Learning
  tflite_flutter: ^0.10.3      # TensorFlow Lite
  
  # Firebase Services
  firebase_core: ^2.24.2       # Firebase core
  firebase_analytics: ^10.7.4  # Analytics
  firebase_performance: ^0.9.3+7 # Performance
  firebase_crashlytics: ^3.4.8 # Crash reporting
  firebase_messaging: ^14.7.9  # Push notifications
  firebase_remote_config: ^4.3.8 # Remote config
  
  # Authentication
  local_auth: ^2.1.7           # Biometric auth
  
  # Localization
  easy_localization: ^3.0.3    # i18n support
  
  # Utilities
  intl: ^0.18.1               # Internationalization
  url_launcher: ^6.2.2        # Launch URLs
  share_plus: ^7.2.1          # Share functionality
  path_provider: ^2.1.1       # File paths
  permission_handler: ^11.1.0 # Permissions
  image_picker: ^1.0.5        # Image selection
  flutter_image_compress: ^2.1.0 # Image compression
  
  # Monitoring & Analytics
  sentry_flutter: ^7.14.0     # Error tracking
  mixpanel_flutter: ^2.1.1    # Advanced analytics

dev_dependencies:
  flutter_test:
    sdk: flutter
  
  # Code Generation
  build_runner: ^2.4.7
  drift_dev: ^2.13.1
  injectable_generator: ^2.4.1
  json_serializable: ^6.7.1
  freezed: ^2.4.6
  
  # Linting & Analysis
  flutter_lints: ^3.0.1
  dart_code_metrics: ^5.7.6
  
  # Testing
  bloc_test: ^9.1.5
  mocktail: ^1.0.1
  faker: ^2.1.0
  
  # Development Tools
  flutter_launcher_icons: ^0.13.1
  flutter_native_splash: ^2.3.8
```

### 4.3 Backend Development Tools

```bash
# Laravel Development Setup
composer require --dev \
  phpunit/phpunit \
  mockery/mockery \
  fakerphp/faker \
  laravel/telescope \
  barryvdh/laravel-debugbar \
  laravel/sail

# API Documentation
composer require darkaonline/l5-swagger

# Code Quality Tools
composer require --dev \
  phpstan/phpstan \
  laravel/pint \
  rector/rector
```

### 4.4 Testing Tools

```yaml
testing_suite:
  unit_testing:
    - Flutter Test Framework
    - Mocktail for mocking
    - Bloc Test for BLoC testing
    
  integration_testing:
    - Flutter Integration Test
    - Patrol for E2E testing
    
  performance_testing:
    - Flutter DevTools
    - Firebase Performance Monitoring
    
  manual_testing:
    - BrowserStack (device farm)
    - TestFlight (iOS beta)
    - Play Console (Android beta)
```

### 4.5 Development Machine Requirements

```yaml
minimum_requirements:
  os:
    - macOS 12+ (for iOS development)
    - Windows 10/11 with WSL2
    - Ubuntu 20.04+
  
  hardware:
    cpu: Intel i5 or Apple M1
    ram: 8GB minimum, 16GB recommended
    storage: 256GB SSD minimum
    
  software:
    flutter: 3.16+
    dart: 3.2+
    android_studio: Latest stable
    xcode: 15+ (macOS only)
    node: 20 LTS
    php: 8.3+
    mysql: 8.0+
    docker: 24+
```

---

## 5. 📁 Project Structure

### 5.1 Flutter Project Structure

```
juan_heart_mobile/
├── lib/
│   ├── core/
│   │   ├── constants/
│   │   │   ├── colors.dart
│   │   │   ├── strings.dart
│   │   │   └── dimensions.dart
│   │   ├── errors/
│   │   │   ├── exceptions.dart
│   │   │   └── failures.dart
│   │   ├── network/
│   │   │   ├── api_client.dart
│   │   │   └── network_info.dart
│   │   └── utils/
│   │       ├── validators.dart
│   │       └── formatters.dart
│   │
│   ├── features/
│   │   ├── assessment/
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   ├── models/
│   │   │   │   └── repositories/
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   ├── repositories/
│   │   │   │   └── usecases/
│   │   │   └── presentation/
│   │   │       ├── bloc/
│   │   │       ├── screens/
│   │   │       └── widgets/
│   │   │
│   │   ├── referral/
│   │   │   └── [similar structure]
│   │   │
│   │   └── auth/
│   │       └── [similar structure]
│   │
│   ├── shared/
│   │   ├── widgets/
│   │   ├── themes/
│   │   └── routes/
│   │
│   └── main.dart
│
├── assets/
│   ├── images/
│   ├── icons/
│   ├── fonts/
│   ├── models/         # ML models
│   └── translations/   # i18n files
│
├── test/
│   ├── unit/
│   ├── widget/
│   └── fixtures/
│
├── integration_test/
│
└── pubspec.yaml
```

### 5.2 Code Organization Principles

```dart
// Clean Architecture Layers

// 1. Domain Layer (Business Logic)
abstract class AssessmentRepository {
  Future<Either<Failure, Assessment>> submitAssessment(AssessmentParams params);
}

// 2. Data Layer (Implementation)
class AssessmentRepositoryImpl implements AssessmentRepository {
  final RemoteDataSource remoteDataSource;
  final LocalDataSource localDataSource;
  final NetworkInfo networkInfo;
  
  @override
  Future<Either<Failure, Assessment>> submitAssessment(params) async {
    if (await networkInfo.isConnected) {
      // Online logic
    } else {
      // Offline logic
    }
  }
}

// 3. Presentation Layer (UI)
class AssessmentBloc extends Bloc<AssessmentEvent, AssessmentState> {
  final SubmitAssessment submitAssessment;
  
  AssessmentBloc({required this.submitAssessment}) : super(AssessmentInitial());
}
```

---

## 6. 🔄 Development Workflow

### 6.1 Git Workflow

```bash
# Branch naming convention
feature/JUAN-123-assessment-flow
bugfix/JUAN-456-crash-on-submit
hotfix/JUAN-789-critical-security
release/v2.0.0

# Commit message format
<type>(<scope>): <subject>

# Examples:
feat(assessment): add vital signs input screen
fix(referral): resolve PDF generation crash
docs(readme): update installation instructions
refactor(bloc): optimize state management
test(assessment): add unit tests for scoring
```

### 6.2 Sprint Planning (2-Week Sprints)

```yaml
sprint_structure:
  week_1:
    day_1-2: Sprint planning & design review
    day_3-5: Development
    
  week_2:
    day_1-3: Development continuation
    day_4: Code review & testing
    day_5: Sprint review & retrospective
    
team_ceremonies:
  daily_standup: 15 minutes @ 9:00 AM
  sprint_planning: 2 hours @ Sprint start
  sprint_review: 1 hour @ Sprint end
  retrospective: 1 hour @ Sprint end
  
velocity_tracking:
  story_points_per_sprint: 30-40
  bug_fix_allocation: 20%
  technical_debt: 10%
```

### 6.3 Code Review Process

```yaml
code_review_checklist:
  functionality:
    - [ ] Feature works as specified
    - [ ] Edge cases handled
    - [ ] Error handling implemented
    
  code_quality:
    - [ ] Follows Dart style guide
    - [ ] No code duplication
    - [ ] Clear naming conventions
    
  testing:
    - [ ] Unit tests added
    - [ ] Integration tests updated
    - [ ] Manual testing completed
    
  documentation:
    - [ ] Code comments added
    - [ ] README updated if needed
    - [ ] API docs updated
```

---

## 7. 🏢 Infrastructure Requirements

### 7.1 Cloud Infrastructure

```yaml
aws_infrastructure:
  compute:
    ec2_instances:
      - type: t3.medium
      - count: 2 (load balanced)
      - purpose: API servers
    
  storage:
    s3_buckets:
      - juan-heart-pdfs
      - juan-heart-images
      - juan-heart-backups
    
  database:
    rds_mysql:
      - instance: db.t3.medium
      - storage: 100GB
      - multi_az: true
    
    elasticache_redis:
      - node_type: cache.t3.micro
      - nodes: 2
  
  networking:
    cloudfront: CDN distribution
    route53: DNS management
    elastic_load_balancer: Application load balancer
    
  monitoring:
    cloudwatch: Metrics and logs
    x-ray: Distributed tracing
```

### 7.2 Firebase Services

```yaml
firebase_services:
  core:
    - Authentication
    - Cloud Firestore (backup)
    - Cloud Storage
    
  engagement:
    - Cloud Messaging (FCM)
    - In-App Messaging
    - Remote Config
    
  analytics:
    - Google Analytics
    - Crashlytics
    - Performance Monitoring
    
  testing:
    - Test Lab
    - App Distribution
```

### 7.3 Scaling Strategy

```yaml
scaling_metrics:
  horizontal_scaling:
    trigger: CPU > 70%
    min_instances: 2
    max_instances: 10
    
  database_scaling:
    read_replicas: 2
    connection_pooling: 100
    
  cache_strategy:
    redis_ttl: 1 hour
    cdn_ttl: 24 hours
    
  rate_limiting:
    api_calls: 100/minute/user
    assessments: 10/hour/user
```

---

## 8. 🔒 Security Architecture

### 8.1 Security Layers

```yaml
security_implementation:
  application_security:
    - Input validation
    - SQL injection prevention
    - XSS protection
    - CSRF tokens
    
  data_security:
    encryption_at_rest: AES-256
    encryption_in_transit: TLS 1.3
    key_management: AWS KMS
    
  authentication:
    method: JWT with refresh tokens
    token_expiry: 24 hours
    refresh_token_expiry: 30 days
    biometric: TouchID/FaceID
    
  authorization:
    role_based_access: User, Admin, Doctor
    resource_based: Own data only
    
  compliance:
    - Philippine Data Privacy Act
    - HIPAA guidelines
    - ISO 27001 principles
```

### 8.2 Security Implementation

```dart
// Secure Storage Implementation
class SecureStorageService {
  static const _storage = FlutterSecureStorage();
  
  static const _aesKey = 'AES_ENCRYPTION_KEY';
  
  static Future<void> saveSecure(String key, String value) async {
    final encrypted = await _encrypt(value);
    await _storage.write(key: key, value: encrypted);
  }
  
  static Future<String?> getSecure(String key) async {
    final encrypted = await _storage.read(key: key);
    if (encrypted == null) return null;
    return await _decrypt(encrypted);
  }
  
  static Future<String> _encrypt(String plainText) async {
    final key = Key.fromBase64(_aesKey);
    final iv = IV.fromSecureRandom(16);
    final encrypter = Encrypter(AES(key));
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    return '${iv.base64}:${encrypted.base64}';
  }
  
  static Future<String> _decrypt(String encrypted) async {
    final parts = encrypted.split(':');
    final iv = IV.fromBase64(parts[0]);
    final key = Key.fromBase64(_aesKey);
    final encrypter = Encrypter(AES(key));
    return encrypter.decrypt64(parts[1], iv: iv);
  }
}
```

---

## 9. 📊 Data Architecture

### 9.1 Data Models

```yaml
core_entities:
  User:
    - id: UUID
    - email: String
    - profile: UserProfile
    - created_at: DateTime
    
  UserProfile:
    - name: String
    - date_of_birth: Date
    - gender: Enum
    - medical_history: MedicalHistory
    - emergency_contacts: List<Contact>
    
  Assessment:
    - id: UUID
    - user_id: UUID
    - symptoms: Symptoms
    - vital_signs: VitalSigns
    - risk_scores: RiskScores
    - recommendations: List<Recommendation>
    - created_at: DateTime
    
  HealthcareFacility:
    - id: UUID
    - name: String
    - type: Enum
    - location: GeoPoint
    - services: List<Service>
    - contact_info: ContactInfo
    
  Referral:
    - id: UUID
    - assessment_id: UUID
    - facility_id: UUID
    - status: Enum
    - pdf_url: String
    - qr_code: String
    - created_at: DateTime
```

### 9.2 Database Schema

```sql
-- Core Tables
CREATE TABLE users (
    id VARCHAR(36) PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE assessments (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36),
    likelihood_score INT,
    impact_score INT,
    final_risk_score INT,
    risk_category VARCHAR(50),
    symptoms_data JSON,
    vital_signs_data JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE healthcare_facilities (
    id VARCHAR(36) PRIMARY KEY,
    name VARCHAR(255),
    type ENUM('hospital', 'clinic', 'health_center'),
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    services JSON,
    contact_info JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE referrals (
    id VARCHAR(36) PRIMARY KEY,
    assessment_id VARCHAR(36),
    facility_id VARCHAR(36),
    status ENUM('pending', 'completed', 'cancelled'),
    pdf_url VARCHAR(500),
    qr_code TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (assessment_id) REFERENCES assessments(id),
    FOREIGN KEY (facility_id) REFERENCES healthcare_facilities(id)
);

-- Indexes for performance
CREATE INDEX idx_assessments_user ON assessments(user_id);
CREATE INDEX idx_assessments_date ON assessments(created_at);
CREATE INDEX idx_facilities_location ON healthcare_facilities(latitude, longitude);
CREATE INDEX idx_referrals_status ON referrals(status);
```

### 9.3 Caching Strategy

```yaml
caching_layers:
  local_cache:
    provider: Hive
    strategy:
      - User profile: Persistent
      - Facilities: 7 days TTL
      - Assessments: Persistent
      
  memory_cache:
    provider: In-memory Map
    strategy:
      - Active assessment: Session
      - UI state: Session
      
  remote_cache:
    provider: Redis
    strategy:
      - Session data: 24 hours TTL
      - API responses: 1 hour TTL
      - Facility search: 6 hours TTL
```

---

## 10. 🔌 Integration Architecture

### 10.1 API Integration

```yaml
api_endpoints:
  base_url: https://api.juanheart.ph/v1
  
  authentication:
    login: POST /auth/login
    register: POST /auth/register
    refresh: POST /auth/refresh
    logout: POST /auth/logout
    
  assessment:
    submit: POST /assessments
    history: GET /assessments
    details: GET /assessments/{id}
    
  referral:
    create: POST /referrals
    list: GET /referrals
    pdf: GET /referrals/{id}/pdf
    
  facilities:
    search: GET /facilities/search
    nearby: GET /facilities/nearby
    details: GET /facilities/{id}
```

### 10.2 Third-Party Integrations

```dart
// Maps Integration Service
class MapsIntegrationService {
  final String _apiKey = Env.GOOGLE_MAPS_API_KEY;
  
  Future<List<Facility>> searchNearbyFacilities(
    double latitude,
    double longitude,
    int radiusMeters,
  ) async {
    final url = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
        '?location=$latitude,$longitude'
        '&radius=$radiusMeters'
        '&type=hospital|health'
        '&key=$_apiKey';
    
    final response = await dio.get(url);
    return _parseFacilities(response.data);
  }
  
  Future<Duration> getEstimatedTravelTime(
    LatLng origin,
    LatLng destination,
  ) async {
    final url = 'https://maps.googleapis.com/maps/api/distancematrix/json'
        '?origins=${origin.latitude},${origin.longitude}'
        '&destinations=${destination.latitude},${destination.longitude}'
        '&key=$_apiKey';
    
    final response = await dio.get(url);
    return _parseDuration(response.data);
  }
}
```

### 10.3 Future Integrations

```yaml
planned_integrations:
  telemedicine:
    provider: Agora.io
    features:
      - Video consultation
      - Screen sharing
      - Chat messaging
    timeline: Q2 2025
    
  wearables:
    devices:
      - Apple Watch (HealthKit)
      - Fitbit
      - Samsung Galaxy Watch
    data_points:
      - Heart rate
      - Blood pressure
      - Activity level
    timeline: Q2-Q3 2025
    
  national_health_system:
    integration: PhilHealth API
    features:
      - Member verification
      - Claims submission
      - Benefit inquiry
    timeline: Q4 2025
```

---

## 11. 🚀 Deployment Strategy

### 11.1 Release Pipeline

```yaml
deployment_pipeline:
  development:
    branch: develop
    environment: staging
    url: https://staging.juanheart.ph
    
  staging:
    branch: release/*
    environment: staging
    url: https://staging.juanheart.ph
    testing: Beta users (100)
    
  production:
    branch: main
    environment: production
    url: https://api.juanheart.ph
    rollout: Phased (20% → 50% → 100%)
```

### 11.2 Mobile Deployment

```bash
# Android Deployment (Fastlane)
fastlane android beta    # Deploy to Play Store Beta
fastlane android prod    # Deploy to Play Store Production

# iOS Deployment (Fastlane)
fastlane ios beta        # Deploy to TestFlight
fastlane ios prod        # Deploy to App Store

# Flutter Build Commands
flutter build apk --release --obfuscate --split-per-abi
flutter build appbundle --release --obfuscate
flutter build ipa --release --obfuscate
```

### 11.3 CI/CD Configuration

```yaml
# .github/workflows/deploy.yml
name: Deploy Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test --coverage
      - uses: codecov/codecov-action@v3

  build:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter build apk --release --split-per-abi
      - uses: actions/upload-artifact@v3
        with:
          name: release-apks
          path: build/app/outputs/flutter-apk/

  deploy:
    needs: build
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/download-artifact@v3
      - run: fastlane android deploy
```

---

## 12. 📈 Monitoring & Observability

### 12.1 Monitoring Stack

```yaml
monitoring_tools:
  application_monitoring:
    firebase_performance:
      - App startup time
      - Screen rendering
      - Network requests
      - Custom traces
      
    sentry:
      - Error tracking
      - Performance monitoring
      - Release tracking
      
  infrastructure_monitoring:
    prometheus:
      - System metrics
      - Custom metrics
      - Alert rules
      
    grafana:
      - Dashboards
      - Visualizations
      - Alert management
      
  logging:
    cloudwatch:
      - Application logs
      - System logs
      - Log aggregation
      
    elk_stack:
      - Elasticsearch
      - Logstash
      - Kibana
```

### 12.2 Key Metrics to Track

```yaml
technical_metrics:
  performance:
    - App launch time < 3s
    - API response time < 2s
    - Crash-free rate > 99%
    - Memory usage < 150MB
    
  reliability:
    - Uptime > 99.5%
    - Error rate < 1%
    - Offline mode success > 95%
    
business_metrics:
  user_engagement:
    - Daily active users
    - Session duration
    - Assessment completion rate
    - Referral completion rate
    
  clinical_impact:
    - Risk detection accuracy
    - Time to care metrics
    - User satisfaction score
```

### 12.3 Alerting Configuration

```yaml
alert_rules:
  critical:
    - API down > 1 minute
    - Database connection failed
    - Error rate > 5%
    - Response time > 5s
    
  warning:
    - CPU usage > 80%
    - Memory usage > 90%
    - Disk space < 10%
    - Error rate > 2%
    
  notification_channels:
    - Slack: #juan-heart-alerts
    - Email: devops@juanheart.ph
    - SMS: On-call engineer
```

---

## 📋 Quick Reference

### Environment Setup Commands

```bash
# Flutter setup
flutter doctor
flutter pub get
flutter run

# Backend setup
composer install
php artisan serve
php artisan migrate

# Docker setup
docker-compose up -d
docker-compose logs -f

# Git setup
git flow init
git config core.hooksPath .githooks
```

### Useful Scripts

```bash
# Development
./scripts/setup.sh          # Initial setup
./scripts/run-tests.sh      # Run all tests
./scripts/build-dev.sh      # Build for development
./scripts/build-prod.sh     # Build for production

# Deployment
./scripts/deploy-staging.sh  # Deploy to staging
./scripts/deploy-prod.sh     # Deploy to production
./scripts/rollback.sh       # Rollback deployment
```

### Team Contacts

```yaml
technical_lead: tech.lead@juanheart.ph
backend_dev: backend@juanheart.ph
mobile_dev: mobile@juanheart.ph
devops: devops@juanheart.ph
support: support@juanheart.ph
```

---

## 📅 Timeline & Milestones

### Q1 2025 (Completed)
- [x] Performance optimization (M1 - Jan 31, 2025)
- [x] Offline sync implementation (M2 - Feb 28, 2025)
- [x] Advanced analytics (M3 - Mar 28, 2025)
- [x] Telemedicine foundation (M5 - May 30, 2025)
- [x] Assessment-driven booking (M5.1 - Feb 3, 2025)

**See COMPLETED_MILESTONES.md for detailed completion reports**

### Q2-Q4 2025 (Active Planning)

### Q2 2025
- [ ] Telemedicine integration planning
- [ ] Wearable device support (experimental)
- [ ] Enhanced ML models
- [ ] Regional expansion preparation

### Q3 2025
- [ ] Full telemedicine launch
- [ ] AI-enhanced predictions
- [ ] Community features
- [ ] National health system integration

### Q4 2025 and Beyond
- [ ] ASEAN market research
- [ ] Platform scaling
- [ ] Advanced analytics dashboard
- [ ] Research partnerships

---

## ✅ Definition of Done

A feature is considered "Done" when:

1. **Code Complete**
   - [ ] Feature implemented according to specifications
   - [ ] Code reviewed and approved by at least 1 team member
   - [ ] No critical or high-priority bugs

2. **Testing Complete**
   - [ ] Unit tests written and passing (>80% coverage)
   - [ ] Integration tests passing
   - [ ] Manual testing completed on target devices
   - [ ] Accessibility testing passed

3. **Documentation Complete**
   - [ ] Code comments added
   - [ ] API documentation updated
   - [ ] User documentation updated if needed
   - [ ] Release notes prepared

4. **Deployment Ready**
   - [ ] Feature flagged if needed
   - [ ] Performance benchmarks met
   - [ ] Security review passed
   - [ ] Merged to main branch

---

*This planning document is a living guide that evolves with the project. Last updated: October 2025*

**For questions or clarifications, contact the Juan Heart development team.**
