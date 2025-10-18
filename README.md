# Juan Heart Project

A digital health application that empowers ordinary Filipinos ("Juan") to assess, understand, and manage their cardiovascular health risks using both AI-driven and rule-based risk assessment models.

## 🎯 Project Overview

The Juan Heart Project aims to develop a comprehensive digital health solution that supports the Philippine Heart Center's National CVD Clinical Decision Tool and Referral Network System. The application helps reduce the incidence of preventable heart-related emergencies through early detection, patient education, and guided referrals.

## 🏥 Mission

To provide accessible, culturally localized cardiovascular health assessment tools that enable early detection and prevention of heart-related conditions among Filipino communities.

## 🚀 Current Development Status

### Phase 1: Core Application Development (In Progress)
- **Flutter-based mobile application** with cross-platform support (Android, iOS, Web)
- **Machine Learning Integration**: Two ML models for cardiovascular risk prediction
- **Rule-based Scoring System**: Likelihood scoring model for risk assessment
- **User Interface**: Complete app interface design and implementation
- **Risk Visualization**: Interactive risk heatmap display
- **Recommendation Engine**: Clear next-step guidance from self-care to emergency referral

### Technical Stack
- **Frontend**: Flutter/Dart
- **Machine Learning**: TensorFlow Lite models
- **Architecture**: BLoC pattern for state management
- **Localization**: Multi-language support for Filipino users
- **Platforms**: Android, iOS, Web, Desktop

## 📱 Features

### Current Features
- **User Authentication**: Secure login and registration system
- **Health Assessment**: Comprehensive cardiovascular risk evaluation
- **Risk Visualization**: Interactive charts and heatmaps
- **Personalized Recommendations**: AI-driven health guidance
- **Emergency SOS**: Quick access to emergency services
- **Health Corner**: Educational content and resources
- **Profile Management**: User health data and preferences
- **Multi-language Support**: Localized for Filipino users

### Planned Features
- **Telemedicine Integration**: Direct connection to healthcare providers
- **Health Data Export**: PDF reports for medical consultations
- **Community Features**: Health challenges and peer support
- **Wearable Integration**: Sync with fitness trackers and smartwatches
- **Advanced Analytics**: Long-term health trend analysis

## 🏗️ Project Structure

```
lib/
├── bloc/                    # State management (BLoC pattern)
│   ├── auth_bloc/          # Authentication state management
│   └── home/               # Home screen state management
├── core/                   # Core utilities and constants
├── models/                 # Data models and DTOs
├── presentation/           # UI components and pages
│   ├── pages/             # Application screens
│   └── widgets/           # Reusable UI components
├── repository/             # Data access layer
├── routes/                 # Navigation routing
├── service/                # API services
└── themes/                 # App styling and themes
```

## 🤖 Machine Learning Models

The application integrates multiple risk assessment approaches:

1. **AI-Driven Models**: Two TensorFlow Lite models for cardiovascular risk prediction
2. **Rule-Based Scoring**: Traditional likelihood scoring system
3. **Hybrid Approach**: Combines ML predictions with clinical guidelines

## 🎨 Design Philosophy

- **Culturally Sensitive**: Designed specifically for Filipino users
- **Accessibility First**: Easy-to-use interface for all age groups
- **Evidence-Based**: Grounded in medical research and clinical guidelines
- **Privacy-Focused**: Secure handling of personal health data

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (latest stable version)
- Dart SDK
- Android Studio / VS Code
- Git

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/[your-username]/juan-heart-project.git
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

## 📊 Development Progress

### Completed
- [x] Project structure and architecture setup
- [x] Authentication system implementation
- [x] Core UI components and themes
- [x] Basic navigation and routing
- [x] Machine learning model integration
- [x] Risk assessment interface
- [x] Multi-language support framework

### In Progress
- [ ] Complete risk visualization dashboard
- [ ] Advanced recommendation engine
- [ ] Emergency SOS functionality
- [ ] Health data persistence
- [ ] User profile management

### Planned
- [ ] Telemedicine integration
- [ ] Advanced analytics
- [ ] Community features
- [ ] Wearable device integration
- [ ] Clinical validation studies

## 🤝 Contributing

This project is developed under the Philippine Heart Center. For contribution guidelines and development standards, please contact the project maintainers.

## 📄 License

This project is developed for the Philippine Heart Center's National CVD Clinical Decision Tool and Referral Network System. All rights reserved.

## 🏥 Partnership

**Philippine Heart Center**
- National CVD Clinical Decision Tool and Referral Network System
- Cardiovascular health research and development
- Community health outreach programs

## 📞 Contact

For questions, suggestions, or collaboration opportunities, please contact the development team through the Philippine Heart Center.

---

*Empowering Filipino communities through accessible cardiovascular health technology.*
