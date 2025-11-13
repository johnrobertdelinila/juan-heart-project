# Product Requirements Document (PRD)
# Juan Heart Mobile Application
## National CVD Clinical Decision Tool and Referral Network System

---

**Version:** 2.0  
**Date:** October 2025  
**Status:** Living Document  
**Authors:** University of the Cordilleras DIT Team  
**Stakeholders:** Philippine Heart Center, Department of Health, UC DIT Program  

---

## 📋 Executive Summary

The Juan Heart Mobile Application is a groundbreaking digital health solution designed to democratize cardiovascular disease (CVD) prevention and early detection for Filipino communities. As the mobile component of the Philippine Heart Center's National CVD Clinical Decision Tool and Referral Network System, this application empowers ordinary Filipinos ("Juan") to assess their heart health risk, receive evidence-based recommendations, and connect with appropriate healthcare facilities.

### Key Value Propositions

1. **Accessible Risk Assessment** - Simple, localized CVD risk evaluation available offline
2. **Clinical-Grade Accuracy** - PHC-validated rule-based scoring aligned with international guidelines
3. **Seamless Care Navigation** - Intelligent referral system connecting users to appropriate facilities
4. **Cultural Relevance** - Designed specifically for Filipino users with Taglish support
5. **Health Equity** - Functions on low-end devices with limited connectivity

### Current State

The application has successfully completed **Phase 1** (Core Development) and **Phase 2** (Referral System), with over 7,000 lines of production-ready code. The team is now positioned for **Phase 3** (Enhancement and Scaling).

---

## 1. Product Vision and Objectives

### 1.1 Vision Statement

> "To become the Philippines' primary digital gateway for cardiovascular health awareness, empowering every Filipino with the knowledge and tools to prevent heart disease through accessible, culturally-relevant, and clinically-validated health technology."

### 1.2 Strategic Objectives

| Objective | Success Metric | Target | Timeline |
|-----------|---------------|--------|----------|
| **User Adoption** | Active monthly users | 50,000 | Year 1 |
| **Clinical Impact** | Early detection rate improvement | 25% | Year 2 |
| **Healthcare Access** | Successful referral completions | 10,000 | Year 1 |
| **User Satisfaction** | App Store rating | ≥4.5 stars | Q2 2025 |
| **Health Equity** | Rural user percentage | 40% | Year 1 |

### 1.3 Problem Statement

Cardiovascular disease remains the **leading cause of death** in the Philippines, with many cases preventable through early detection and intervention. Current barriers include:

- Limited access to cardiovascular screening in rural areas
- High cost of preventive care consultations
- Lack of health literacy regarding CVD symptoms
- Inefficient referral systems causing delays in care
- Language and cultural barriers in existing health tools

---

## 2. User Personas and Use Cases

### 2.1 Primary User Personas

#### **Persona 1: "Maria" - The Concerned Family Member**
- **Age:** 35-45 years old
- **Location:** Metro Manila
- **Tech Savvy:** Moderate (uses Facebook, messaging apps)
- **Context:** Worried about elderly parents with hypertension
- **Needs:** Easy health monitoring, clear guidance in Tagalog, emergency contacts
- **Device:** Mid-range Android phone

#### **Persona 2: "Juan" - The At-Risk Worker**
- **Age:** 45-55 years old
- **Location:** Provincial city
- **Tech Savvy:** Low to moderate
- **Context:** Manual laborer with undiagnosed chest pain
- **Needs:** Simple assessment, affordable care options, offline functionality
- **Device:** Low-end Android phone, intermittent data

#### **Persona 3: "Ana" - The Health-Conscious Professional**
- **Age:** 28-38 years old
- **Location:** Urban center
- **Tech Savvy:** High
- **Context:** Family history of heart disease, preventive focus
- **Needs:** Regular monitoring, data insights, integration with wearables
- **Device:** iPhone or high-end Android

### 2.2 Core Use Cases

| Use Case | Description | Priority |
|----------|-------------|----------|
| **UC-01: Emergency Assessment** | User experiencing chest pain needs immediate risk evaluation | Critical |
| **UC-02: Routine Screening** | Monthly cardiovascular risk check for monitoring | High |
| **UC-03: Facility Finding** | Locate appropriate healthcare facility based on risk level | High |
| **UC-04: Referral Generation** | Create PDF referral document for doctor visit | High |
| **UC-05: Health Education** | Learn about CVD symptoms and prevention | Medium |
| **UC-06: Data Tracking** | View historical assessments and trends | Medium |

---

## 3. Functional Requirements

### 3.1 Core Assessment Engine

#### 3.1.1 Risk Assessment Module

**Description:** Rule-based cardiovascular risk assessment using PHC-validated scoring matrix

**Requirements:**
- **FR-001:** System SHALL collect symptom data through guided questionnaire
- **FR-002:** System SHALL calculate Likelihood Score (1-5) based on:
  - Chest pain characteristics (type, duration, radiation)
  - Shortness of breath severity
  - Palpitations and heart rhythm
  - Syncope/fainting episodes
  - Neurological symptoms
  - Risk factors (age, comorbidities)
  
- **FR-003:** System SHALL calculate Impact Score (1-5) based on:
  - Blood pressure readings
  - Heart rate measurements
  - Oxygen saturation
  - Symptom duration and severity

- **FR-004:** System SHALL compute Final Risk Score = Likelihood × Impact (1-25)
- **FR-005:** System SHALL map risk scores to action categories:
  - 1-4 (Green): Self-care and monitoring
  - 5-9 (Yellow-Green): Schedule clinic visit within 1-2 weeks
  - 10-14 (Yellow-Orange): Book clinic/teleconsult within 24-48 hours
  - 15-19 (Orange-Red): Seek urgent care within 6-24 hours
  - 20-25 (Red): Go to emergency room immediately

#### 3.1.2 Vital Signs Input

**Requirements:**
- **FR-006:** System SHALL accept manual vital signs entry
- **FR-007:** System SHALL provide visual guides for self-measurement
- **FR-008:** System SHALL validate input ranges and flag abnormal values
- **FR-009:** System SHALL support both metric and imperial units

### 3.2 Referral and Care Navigation

#### 3.2.1 Facility Recommendation Engine

**Requirements:**
- **FR-010:** System SHALL recommend facilities based on:
  - Risk level severity
  - User location (GPS or manual)
  - Facility capabilities
  - Insurance acceptance (PhilHealth, HMO)
  - User preferences (public/private)

- **FR-011:** System SHALL display facility information:
  - Name, address, contact details
  - Distance and estimated travel time
  - Available services
  - Operating hours
  - Accepted payment methods

#### 3.2.2 Referral Document Generation

**Requirements:**
- **FR-012:** System SHALL generate PDF referral documents containing:
  - Patient demographics
  - Assessment results and risk scores
  - Vital signs and symptoms
  - Recommended urgency level
  - QR code for verification

- **FR-013:** System SHALL allow sharing via:
  - Email
  - Messaging apps (Viber, WhatsApp)
  - Direct print
  - Save to device

### 3.3 User Management

#### 3.3.1 Authentication and Profiles

**Requirements:**
- **FR-014:** System SHALL support multiple authentication methods:
  - Email/password
  - Social login (Facebook, Google)
  - Guest mode (limited features)
  
- **FR-015:** System SHALL maintain user profiles with:
  - Demographics
  - Medical history
  - Current medications
  - Emergency contacts
  - Insurance information

### 3.4 Data Management

#### 3.4.1 Offline Functionality

**Requirements:**
- **FR-016:** System SHALL function offline for:
  - Risk assessments
  - Viewing saved facilities
  - Accessing educational content
  - Reviewing assessment history

- **FR-017:** System SHALL sync data when connection restored

#### 3.4.2 Data Analytics

**Requirements:**
- **FR-018:** System SHALL track and display:
  - Assessment history with trends
  - Risk score progression
  - Vital signs over time
  - Medication adherence (future)

### 3.5 Educational Content

**Requirements:**
- **FR-019:** System SHALL provide educational modules on:
  - CVD symptoms recognition
  - Risk factor modification
  - Healthy lifestyle tips
  - Emergency response procedures

- **FR-020:** System SHALL support multimedia content:
  - Text articles
  - Infographics
  - Video tutorials (when online)
  - Interactive quizzes

---

## 4. Non-Functional Requirements

### 4.1 Performance Requirements

| Requirement | Specification | Measurement |
|-------------|--------------|-------------|
| **NFR-001: Response Time** | Assessment completion < 60 seconds | Average time from start to result |
| **NFR-002: App Launch** | Cold start < 3 seconds | Time to interactive state |
| **NFR-003: Offline Mode** | Full assessment without internet | Core features available offline |
| **NFR-004: Battery Usage** | < 2% drain per assessment | Battery consumption monitoring |
| **NFR-005: App Size** | APK < 50MB | Installation package size |

### 4.2 Compatibility Requirements

| Requirement | Specification |
|-------------|--------------|
| **NFR-006: Android Support** | Android 5.0 (API 21) and above |
| **NFR-007: iOS Support** | iOS 12.0 and above |
| **NFR-008: Device Range** | Functional on devices with 2GB RAM |
| **NFR-009: Screen Sizes** | Responsive from 4.7" to 10" screens |
| **NFR-010: Network** | 2G/3G/4G/5G and WiFi compatible |

### 4.3 Security Requirements

| Requirement | Specification |
|-------------|--------------|
| **NFR-011: Data Encryption** | AES-256 for data at rest |
| **NFR-012: Transmission Security** | TLS 1.3 for all API communications |
| **NFR-013: Authentication** | JWT tokens with 24-hour expiry |
| **NFR-014: Privacy Compliance** | Philippine Data Privacy Act adherent |
| **NFR-015: Health Data Standards** | HL7 FHIR compatible (future) |

### 4.4 Usability Requirements

| Requirement | Specification |
|-------------|--------------|
| **NFR-016: Language Support** | English, Filipino, Taglish toggle |
| **NFR-017: Accessibility** | WCAG 2.1 Level AA compliant |
| **NFR-018: Font Sizing** | Minimum 14pt, adjustable to 24pt |
| **NFR-019: Touch Targets** | Minimum 44x44 dp for buttons |
| **NFR-020: Error Recovery** | Clear error messages with recovery actions |

### 4.5 Reliability Requirements

| Requirement | Specification |
|-------------|--------------|
| **NFR-021: Availability** | 99.5% uptime for online services |
| **NFR-022: Data Integrity** | Zero data loss during sync |
| **NFR-023: Crash Rate** | < 1% of sessions |
| **NFR-024: Recovery Time** | < 5 seconds from crash |

---

## 5. Technical Architecture

### 5.1 Technology Stack

| Layer | Technology | Justification |
|-------|------------|---------------|
| **Frontend Framework** | Flutter 3.x | Cross-platform efficiency, single codebase |
| **Programming Language** | Dart | Flutter native language |
| **State Management** | BLoC Pattern | Scalable, testable architecture |
| **Local Database** | SQLite/Hive | Offline data persistence |
| **ML Integration** | TensorFlow Lite | On-device inference |
| **Backend API** | Laravel 11 | Robust PHP framework |
| **Cloud Services** | Firebase | Analytics, crash reporting, remote config |
| **Maps Integration** | Google Maps API | Facility location services |

### 5.2 System Architecture

```
┌─────────────────────────────────────────┐
│          Mobile Application              │
├─────────────────────────────────────────┤
│  Presentation Layer (Flutter Widgets)    │
├─────────────────────────────────────────┤
│  Business Logic Layer (BLoC)             │
├─────────────────────────────────────────┤
│  Service Layer                           │
│  ├── Assessment Service                  │
│  ├── Referral Service                    │
│  ├── Facility Service                    │
│  └── PDF Generation Service              │
├─────────────────────────────────────────┤
│  Data Layer                              │
│  ├── Local Storage (SQLite/Hive)         │
│  ├── Remote API (Laravel Backend)        │
│  └── ML Models (TensorFlow Lite)         │
└─────────────────────────────────────────┘
```

### 5.3 Data Models

#### Core Entities

1. **User Profile**
   - Demographics
   - Medical history
   - Preferences
   - Emergency contacts

2. **Assessment Record**
   - Timestamp
   - Symptoms data
   - Vital signs
   - Risk scores
   - Recommendations

3. **Healthcare Facility**
   - Facility details
   - Services offered
   - Location data
   - Contact information

4. **Referral Document**
   - Assessment reference
   - Facility reference
   - Generated PDF path
   - QR code data

---

## 6. Development Roadmap

### 6.1 Release Planning

#### **Version 1.0 - MVP Release** ✅ COMPLETED
- Core risk assessment engine
- Basic referral system
- Offline functionality
- English/Filipino support

#### **Version 1.1 - Enhanced Referral** ✅ COMPLETED
- PDF generation with QR codes
- Facility search and filtering
- Improved UI/UX
- Analytics dashboard

#### **Version 2.0 - Q1 2025** (Current Phase)
**Sprint 1-2: Platform Optimization (Weeks 1-4)**
- [ ] Performance optimization for low-end devices
- [ ] Reduce APK size to under 40MB
- [ ] Implement progressive data loading
- [ ] Add image compression for reports

**Sprint 3-4: Enhanced Offline Capabilities (Weeks 5-8)**
- [ ] Offline facility database with 500+ entries
- [ ] Background sync queue system
- [ ] Conflict resolution for data sync
- [ ] Offline educational content caching

**Sprint 5-6: Advanced Analytics (Weeks 9-12)**
- [ ] Longitudinal risk trending charts
- [ ] Predictive risk alerts
- [ ] Medication adherence tracking
- [ ] Export health reports (PDF/CSV)

#### **Version 2.1 - Q2 2025**
**Sprint 7-8: Telemedicine Preparation**
- [ ] Video consultation scheduling UI
- [ ] Appointment reminders
- [ ] Pre-consultation questionnaires
- [ ] Integration with teleconsult providers

**Sprint 9-10: Wearable Integration (Experimental)**
- [ ] Bluetooth connectivity framework
- [ ] Basic heart rate monitor support
- [ ] Blood pressure device integration
- [ ] Apple HealthKit / Google Fit sync

#### **Version 3.0 - Q3 2025**
- Full telemedicine integration
- AI-enhanced risk predictions
- Community features and challenges
- Family account linking

### 6.2 Sprint Structure (3-Person Team)

| Week | Developer 1 | Developer 2 | Developer 3 |
|------|------------|------------|-------------|
| **Week 1-2** | Offline database architecture | Performance profiling | APK size optimization |
| **Week 3-4** | Sync queue implementation | UI performance fixes | Image compression |
| **Week 5-6** | Analytics charts | Data export features | Testing & bug fixes |
| **Week 7-8** | Integration testing | Documentation | Release preparation |

---

## 7. Quality Assurance

### 7.1 Testing Strategy

| Test Type | Coverage Target | Tools | Frequency |
|-----------|----------------|-------|-----------|
| **Unit Tests** | 80% | Flutter Test | Per commit |
| **Widget Tests** | 70% | Flutter Test | Per feature |
| **Integration Tests** | Core flows | Flutter Driver | Per sprint |
| **Manual Testing** | All features | Test devices | Pre-release |
| **Beta Testing** | 100 users | TestFlight/Play Console | Per release |

### 7.2 Test Devices Matrix

| Category | Devices | OS Versions |
|----------|---------|-------------|
| **Low-end Android** | Samsung J2, Oppo A3s | Android 5.0-7.0 |
| **Mid-range Android** | Samsung A52, Xiaomi Redmi | Android 8.0-12.0 |
| **High-end Android** | Samsung S21, Pixel 6 | Android 13-14 |
| **iOS Devices** | iPhone 8, 11, 13 | iOS 12-17 |

### 7.3 Acceptance Criteria

Each feature must meet:
1. Functional requirements verified
2. Performance benchmarks achieved
3. Accessibility standards met
4. Offline functionality confirmed
5. Localization complete
6. Security review passed

---

## 8. Success Metrics and KPIs

### 8.1 User Engagement Metrics

| Metric | Target | Measurement Method |
|--------|--------|-------------------|
| **Daily Active Users** | 10,000 by Month 6 | Firebase Analytics |
| **Assessment Completion Rate** | > 85% | In-app tracking |
| **Average Session Duration** | > 3 minutes | Analytics |
| **User Retention (30-day)** | > 40% | Cohort analysis |
| **Referral Completion Rate** | > 30% | Backend tracking |

### 8.2 Clinical Impact Metrics

| Metric | Target | Measurement Method |
|--------|--------|-------------------|
| **High-Risk Detection Rate** | Track baseline | Assessment data analysis |
| **Time to Care** | < 48 hours for urgent | Referral tracking |
| **False Positive Rate** | < 20% | Clinical validation study |
| **User Reported Outcomes** | 70% positive | In-app surveys |

### 8.3 Technical Performance Metrics

| Metric | Target | Measurement Method |
|--------|--------|-------------------|
| **Crash-Free Rate** | > 99% | Crashlytics |
| **API Response Time** | < 2 seconds | Backend monitoring |
| **Offline Usage** | > 30% of assessments | Analytics |
| **App Store Rating** | ≥ 4.5 stars | Store reviews |

---

## 9. Risk Management

### 9.1 Technical Risks

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| **Poor network connectivity** | High | High | Robust offline mode, efficient sync |
| **Low-end device compatibility** | High | Medium | Performance optimization, lite version |
| **Data sync conflicts** | Medium | Medium | Conflict resolution algorithm |
| **API scaling issues** | High | Low | Cloud infrastructure, caching |

### 9.2 Clinical Risks

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| **Misinterpretation of results** | High | Medium | Clear messaging, disclaimers |
| **Over-reliance on app** | Medium | Medium | Education on limitations |
| **Delayed emergency care** | High | Low | Prominent emergency buttons |

### 9.3 Adoption Risks

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| **Low digital literacy** | High | High | Simplified UI, tutorials |
| **Language barriers** | Medium | Medium | Complete localization |
| **Trust in digital health** | High | Medium | PHC endorsement, testimonials |

---

## 10. Implementation Guidelines

### 10.1 Development Best Practices

1. **Code Quality**
   - Follow Flutter/Dart style guides
   - Maintain 80% test coverage
   - Conduct code reviews for all PRs
   - Use static analysis tools (dart analyze)

2. **Version Control**
   - Git flow branching strategy
   - Semantic versioning
   - Detailed commit messages
   - Protected main branch

3. **Documentation**
   - Inline code documentation
   - API documentation
   - User guides
   - Technical architecture docs

### 10.2 Deployment Strategy

1. **Release Cycle**
   - 2-week sprints
   - Monthly releases to production
   - Hotfixes as needed

2. **Release Process**
   - Feature freeze 3 days before release
   - QA testing on staging
   - Beta release to 100 users
   - Phased production rollout (20% → 50% → 100%)

3. **Monitoring**
   - Real-time crash reporting
   - Performance monitoring
   - User analytics tracking
   - Backend API monitoring

### 10.3 Team Collaboration

**For a 3-Person Development Team:**

1. **Role Distribution**
   - Developer 1: Frontend features and UI
   - Developer 2: Backend integration and services
   - Developer 3: Testing, optimization, and deployment

2. **Communication**
   - Daily 15-minute stand-ups
   - Weekly sprint planning (2 hours)
   - Bi-weekly retrospectives

3. **Tools**
   - GitHub for version control
   - Slack/Discord for communication
   - Jira/Trello for task management
   - Figma for design collaboration

---

## 11. Stakeholder Communication

### 11.1 Reporting Structure

| Stakeholder | Frequency | Format | Content |
|------------|-----------|--------|---------|
| **PHC Leadership** | Monthly | Presentation | Progress, metrics, risks |
| **Clinical Advisory** | Bi-monthly | Report | Clinical accuracy, feedback |
| **UC DIT Faculty** | Weekly | Meeting | Technical progress, challenges |
| **Beta Users** | Per release | Survey | Feature feedback, bugs |

### 11.2 Feedback Channels

- In-app feedback form
- Play Store/App Store reviews
- Email support (support@juanheart.ph)
- Social media monitoring
- Focus group discussions

---

## 12. Budget Considerations

### 12.1 Resource Allocation (3-Person Team)

| Category | Monthly Cost (PHP) | Notes |
|----------|-------------------|--------|
| **Development Team** | ₱150,000 | 3 developers |
| **Cloud Infrastructure** | ₱15,000 | AWS/Firebase |
| **Third-party Services** | ₱10,000 | Maps API, SMS |
| **Testing Devices** | ₱5,000 | Amortized |
| **Marketing/Promotion** | ₱20,000 | Digital campaigns |
| **Total** | ₱200,000 | Per month |

### 12.2 Cost Optimization Strategies

1. Use Firebase free tier initially
2. Implement efficient caching
3. Compress images and assets
4. Use CDN for static content
5. Optimize API calls

---

## 13. Future Vision and Scaling

### 13.1 Long-term Product Evolution

**Year 1:** Foundation
- Establish user base
- Validate clinical accuracy
- Build facility network

**Year 2:** Expansion
- Telemedicine integration
- Wearable device support
- Regional customization

**Year 3:** Innovation
- AI-enhanced predictions
- Predictive analytics
- Integration with national health systems

### 13.2 Scaling Considerations

1. **Technical Scaling**
   - Microservices architecture
   - Horizontal scaling capability
   - Multi-region deployment

2. **Team Scaling**
   - Add dedicated QA engineer
   - UX/UI designer
   - Data scientist for ML models

3. **Geographic Scaling**
   - Start with NCR and Luzon
   - Expand to Visayas and Mindanao
   - Consider ASEAN expansion

---

## 14. Appendices

### Appendix A: Risk Scoring Algorithm Details

```dart
// Likelihood Scoring Logic
int calculateLikelihoodScore(Symptoms symptoms, RiskFactors factors) {
  int score = 0;
  
  // Chest pain assessment
  if (symptoms.chestPain.isTypical) score += 2;
  
  // Shortness of breath
  if (symptoms.shortnessOfBreath.atRest) score += 2;
  else if (symptoms.shortnessOfBreath.onExertion) score += 1;
  
  // Palpitations
  if (symptoms.palpitations.present && 
      (symptoms.heartRate > 120 || symptoms.irregular)) score += 1;
  
  // Syncope
  if (symptoms.syncope.present) score += 2;
  
  // Neurological signs
  if (symptoms.neurologicalSigns.present) score += 2;
  
  // Risk factors
  if (factors.majorRiskFactors >= 2) score += 1;
  
  // Age factor
  if ((factors.gender == 'M' && factors.age >= 55) ||
      (factors.gender == 'F' && factors.age >= 65)) score += 1;
  
  // Map to likelihood band (1-5)
  if (score <= 1) return 1;  // Improbable
  if (score <= 3) return 2;  // Remote
  if (score <= 5) return 3;  // Possible
  if (score <= 7) return 4;  // Probable
  return 5;  // Very Probable
}

// Impact Scoring Logic
int calculateImpactScore(VitalSigns vitals, Symptoms symptoms) {
  // Critical overrides
  if (vitals.systolicBP < 90 || vitals.systolicBP > 180) return 5;
  if (vitals.heartRate < 40 || vitals.heartRate > 130) return 5;
  
  int score = 0;
  
  // Oxygen saturation
  if (vitals.oxygenSat < 92) score += 2;
  else if (vitals.oxygenSat <= 94) score += 1;
  
  // Persistent chest pain
  if (symptoms.chestPain.duration >= 20) score += 2;
  
  // Dyspnea severity
  if (symptoms.dyspnea.severe) score += 2;
  else if (symptoms.dyspnea.moderate) score += 1;
  
  // Map to impact band (1-5)
  if (score <= 1) return 1;  // Negligible
  if (score == 2) return 2;  // Low
  if (score <= 4) return 3;  // Moderate
  if (score <= 6) return 4;  // Significant
  return 5;  // Catastrophic
}
```

### Appendix B: API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/v1/assessment/submit` | POST | Submit assessment data |
| `/api/v1/facilities/search` | GET | Search healthcare facilities |
| `/api/v1/referral/generate` | POST | Generate referral PDF |
| `/api/v1/user/profile` | GET/PUT | Manage user profile |
| `/api/v1/analytics/history` | GET | Retrieve assessment history |

### Appendix C: Localization Strings

```json
{
  "en": {
    "assessment.title": "Heart Risk Assessment",
    "assessment.chest_pain": "Are you experiencing chest pain?",
    "risk.high": "High Risk - Seek immediate medical attention"
  },
  "fil": {
    "assessment.title": "Pagsusuri ng Panganib sa Puso",
    "assessment.chest_pain": "Mayroon ka bang nararamdamang sakit sa dibdib?",
    "risk.high": "Mataas na Panganib - Kumuha ng agarang medikal na atensiyon"
  }
}
```

---

## 📝 Document Control

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | Aug 2024 | UC DIT Team | Initial PRD |
| 1.1 | Sep 2024 | UC DIT Team | Added referral system |
| 2.0 | Oct 2025 | UC DIT Team | Comprehensive update with completed features |

---

## ✅ Approval

This PRD has been reviewed and approved by:

- **Philippine Heart Center Representative:** _________________
- **UC DIT Program Director:** _________________
- **Technical Lead:** _________________
- **Date of Approval:** _________________

---

*This document represents a living agreement between all stakeholders and will be updated as the product evolves. For questions or clarifications, please contact the Juan Heart development team.*
