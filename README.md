# Juan Heart Project

A digital health application that empowers ordinary Filipinos ("Juan") to assess, understand, and manage their cardiovascular health risks using both AI-driven and rule-based risk assessment models.

## Project Overview

The Juan Heart Project aims to develop a comprehensive digital health solution that supports the Philippine Heart Center's National CVD Clinical Decision Tool and Referral Network System. The application helps reduce the incidence of preventable heart-related emergencies through early detection, patient education, and guided referrals.

## Mission

To provide accessible, culturally localized cardiovascular health assessment tools that enable early detection and prevention of heart-related conditions among Filipino communities.

## Academic Development

This project is developed and designed by students of the **Doctor of Information Technology (DIT)** program at the **University of the Cordilleras** in collaboration with the Philippine Heart Center. The project serves as a capstone research initiative that combines advanced information technology concepts with practical healthcare applications to address real-world cardiovascular health challenges in the Philippines.

## Current Development Status

### Phase 1: Core Application Development - COMPLETED
- **Flutter-based mobile application** with cross-platform support (Android, iOS, Web, Desktop)
- **Machine Learning Integration**: Two ML models for cardiovascular risk prediction
- **Rule-based Scoring System**: Likelihood scoring model for risk assessment
- **Complete User Interface**: Full app interface design and implementation
- **Risk Visualization**: Interactive risk assessment with real-time feedback
- **Advanced Recommendation Engine**: Comprehensive care guidance from self-care to emergency referral

### Phase 2: Referral & Care Navigation System - COMPLETED
- **Complete Referral Workflow**: End-to-end referral system from assessment to facility selection
- **Healthcare Facility Integration**: Smart facility recommendations based on risk level and location
- **PDF Report Generation**: Professional referral documents for medical consultations
- **QR Code Integration**: Easy facility navigation and sharing
- **Enhanced UI/UX**: Emotionally intelligent, culturally sensitive design

### Technical Stack
- **Frontend**: Flutter/Dart
- **Machine Learning**: TensorFlow Lite models
- **Architecture**: BLoC pattern for state management
- **Localization**: Multi-language support for Filipino users
- **Platforms**: Android, iOS, Web, Desktop

## Features

### Completed Features

#### **Core Health Assessment**
- **Advanced Heart Risk Assessment**: Comprehensive cardiovascular risk evaluation with real-time scoring
- **Medical Triage Assessment**: Multi-step assessment following PHC guidelines
- **Interactive Risk Visualization**: Dynamic charts and progress indicators
- **AI-Driven Recommendations**: Machine learning-powered health guidance
- **Risk-Based Care Pathways**: Personalized care recommendations based on assessment results

#### **Referral & Care Navigation System**
- **Complete Referral Workflow**: End-to-end process from assessment to facility selection
- **Smart Facility Recommendations**: Location-based healthcare facility suggestions
- **Facility Search & Filtering**: Advanced search with distance, type, and service filters
- **PDF Report Generation**: Professional referral documents with assessment results
- **QR Code Integration**: Easy facility navigation and document sharing
- **Appointment Preparation**: Guided next steps and preparation tips

#### **User Experience & Interface**
- **User Authentication**: Secure login and registration system
- **Profile Management**: Comprehensive user health data and preferences
- **Multi-language Support**: Full English/Filipino (Taglish) localization
- **Accessibility Features**: Large buttons, clear typography, and intuitive navigation
- **Emotional Design**: Warm, reassuring interface with cultural sensitivity
- **Emergency SOS**: Quick access to emergency services and contacts

#### **Technical Features**
- **Cross-Platform Support**: Android, iOS, Web, and Desktop applications
- **Offline Capability**: Core features work without internet connection
- **Data Security**: Secure handling of personal health information
- **Real-time Updates**: Live assessment progress and recommendations
- **Analytics & History**: Comprehensive health data tracking and insights
- **Modern UI/UX**: Redesigned interface with enhanced user experience
- **Performance Optimization**: Smooth, responsive app performance

### Planned Features
- **Telemedicine Integration**: Direct connection to healthcare providers
- **Community Features**: Health challenges and peer support groups
- **Wearable Integration** (Experimental): Sync with fitness trackers and smartwatches
- **Advanced Analytics**: Long-term health trend analysis and insights
- **Family Sharing**: Share health data with family members
- **Medication Reminders**: Smart medication tracking and alerts

## Project Structure

```
lib/
├── bloc/                    # State management (BLoC pattern)
│   ├── auth_bloc/          # Authentication state management
│   └── home/               # Home screen state management
├── core/                   # Core utilities and constants
├── models/                 # Data models and DTOs
│   ├── referral_data.dart  # Referral system data models
│   └── user_model.dart     # User profile and health data
├── presentation/           # UI components and pages
│   ├── pages/             # Application screens
│   │   ├── auth/          # Authentication screens
│   │   ├── home/          # Main app screens
│   │   └── referral/      # Referral system screens
│   └── widgets/           # Reusable UI components
│       ├── assessment_widgets.dart  # Heart assessment components
│       └── referral_widgets.dart    # Referral system components
├── repository/             # Data access layer
├── routes/                 # Navigation routing
├── service/                # API services
│   ├── facility_service.dart        # Healthcare facility management
│   ├── referral_service.dart        # Referral logic and recommendations
│   ├── referral_pdf_service.dart    # PDF generation for referrals
│   └── medical_triage_assessment_service.dart  # Assessment logic
└── themes/                 # App styling and themes
```

## Key Achievements & Innovations

### Major Accomplishments
- **Complete End-to-End Solution**: From risk assessment to facility referral in one seamless workflow
- **Cultural Localization**: First-of-its-kind Filipino-focused cardiovascular health app
- **Academic-Industry Collaboration**: Successful partnership between University of the Cordilleras and Philippine Heart Center
- **Professional-Grade UI/UX**: Emotionally intelligent design that builds trust and reduces anxiety
- **Comprehensive Documentation**: Over 7,000 lines of well-documented, production-ready code

### Technical Innovations
- **Hybrid Risk Assessment**: Combines AI/ML models with clinical guidelines for accurate predictions
- **Smart Referral System**: Location-aware facility recommendations based on risk severity
- **PDF Generation**: Professional medical referral documents with QR codes
- **Multi-Platform Architecture**: Single codebase supporting 4 platforms (Android, iOS, Web, Desktop)
- **Accessibility-First Design**: Large touch targets, clear typography, and intuitive navigation

## Machine Learning Models

The application integrates multiple risk assessment approaches:

1. **AI-Driven Models**: Two TensorFlow Lite models for cardiovascular risk prediction
2. **Rule-Based Scoring**: Traditional likelihood scoring system following PHC guidelines
3. **Hybrid Approach**: Combines ML predictions with clinical guidelines for optimal accuracy
4. **Risk-Based Care Pathways**: Dynamic recommendations from self-care to emergency referral

## Design Philosophy

- **Culturally Sensitive**: Designed specifically for Filipino users
- **Accessibility First**: Easy-to-use interface for all age groups
- **Evidence-Based**: Grounded in medical research and clinical guidelines
- **Privacy-Focused**: Secure handling of personal health data

## Getting Started

### Prerequisites
- Flutter SDK (latest stable version)
- Dart SDK
- Android Studio / VS Code
- Git

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/johnrobertdelinila/juan-heart-project.git
   cd juan-heart-project
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the application**
   ```bash
   flutter run
   ```

### Building for Production

- **Android APK**: `flutter build apk --release`
- **iOS**: `flutter build ios --release`
- **Web**: `flutter build web --release`

## Development Progress

### Phase 1: Core Application (COMPLETED)
- [x] Project structure and architecture setup
- [x] Authentication system implementation
- [x] Core UI components and themes
- [x] Complete navigation and routing system
- [x] Machine learning model integration
- [x] Advanced heart risk assessment interface
- [x] Medical triage assessment system
- [x] Multi-language support framework (English/Filipino)
- [x] User profile management
- [x] Emergency SOS functionality
- [x] Health data persistence

### Phase 2: Referral & Care Navigation (COMPLETED)
- [x] Complete referral workflow implementation
- [x] Healthcare facility integration and search
- [x] Smart facility recommendations based on risk level
- [x] PDF report generation for referrals
- [x] QR code integration for facility navigation
- [x] Enhanced UI/UX with emotional design
- [x] Appointment preparation and guidance
- [x] Referral summary and sharing features
- [x] Advanced assessment widgets and components
- [x] Cultural sensitivity and accessibility improvements

### Phase 2.5: Analytics & User Experience (COMPLETED)
- [x] Analytics service for health data tracking and insights
- [x] Assessment history model and data persistence
- [x] Redesigned analytics screen with enhanced UI/UX
- [x] Major home screen redesign with modern interface
- [x] Enhanced navigation and routing system
- [x] Improved user experience and visual appeal
- [x] Better integration between all app features
- [x] Optimized performance and responsiveness

### Phase 3: Advanced Features (PLANNED)
- [ ] Telemedicine integration
- [ ] Advanced analytics and health insights
- [ ] Community features and health challenges
- [ ] Wearable device integration (Experimental)
- [ ] Family sharing and collaboration
- [ ] Medication tracking and reminders
- [ ] Clinical validation studies
- [ ] Real-time health monitoring

## Contributing

This project is developed under the Philippine Heart Center. For contribution guidelines and development standards, please contact the project maintainers.

## License

This project is developed for the Philippine Heart Center's National CVD Clinical Decision Tool and Referral Network System. All rights reserved.

## Partnership

**Philippine Heart Center**
- National CVD Clinical Decision Tool and Referral Network System
- Cardiovascular health research and development
- Community health outreach programs

**University of the Cordilleras - Doctor of Information Technology Program**
- Advanced information technology research and development
- Healthcare technology innovation
- Academic-industry collaboration initiatives

## Contact

For questions, suggestions, or collaboration opportunities, please contact the development team through the Philippine Heart Center.

---

*Empowering Filipino communities through accessible cardiovascular health technology.*
