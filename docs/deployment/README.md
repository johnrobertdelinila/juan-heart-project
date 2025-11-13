# Juan Heart Mobile - Deployment Documentation

## Overview

This directory contains comprehensive guides for deploying Juan Heart Mobile to beta testing and production environments.

**Current Status:** Android Ready, iOS Blocked

---

## Quick Links

| Platform | Status | Guide | Setup Time |
|----------|--------|-------|------------|
| **Android (Google Play)** | ✅ Ready | [google-play-console-setup.md](google-play-console-setup.md) | 4-6 hours |
| **iOS (TestFlight)** | 🚫 Blocked | [testflight-setup.md](testflight-setup.md) | 3-4 weeks |

---

## Document Index

### Platform Setup Guides

1. **[Google Play Console Setup](google-play-console-setup.md)**
   - Complete guide for Android beta testing
   - Internal and closed testing tracks
   - Service account configuration for CI/CD
   - Tester management and feedback collection
   - **Target:** 30+ beta testers
   - **Prerequisites:** Google Play Developer account ($25)

2. **[TestFlight Setup](testflight-setup.md)**
   - Complete guide for iOS beta testing
   - **Status:** BLOCKED - Awaiting Apple Developer account
   - Certificate and provisioning profile creation
   - App Store Connect configuration
   - **Prerequisites:** Apple Developer Program ($99/year), Mac computer

### Foundation Documents

3. **[Credential Management](00-credential-management.md)**
   - Secure handling of API keys and secrets
   - GitHub Secrets configuration
   - Environment variable management

4. **[Android Keystore Generation](android-keystore-generation.md)**
   - Production keystore creation
   - Signing configuration
   - Backup and security procedures
   - Already completed for Juan Heart Mobile

5. **[GitHub Secrets Setup](github-secrets-setup.md)**
   - CI/CD credential configuration
   - Secret encryption and storage
   - Access control best practices

---

## Platform Comparison

### Android (Google Play Console)

**Advantages:**
- ✅ Account already exists
- ✅ Lower cost ($25 one-time vs $99/year)
- ✅ No device registration required
- ✅ Faster review process (1-3 days)
- ✅ Can develop on Windows/Mac/Linux
- ✅ Internal testing doesn't require review

**Limitations:**
- Closed testing limited to 100 countries
- Less restrictive app review (could mean lower quality bar)

**Best for:**
- Rapid iteration
- Wide distribution in Philippines
- Healthcare workers with Android devices (majority market share)

### iOS (TestFlight)

**Advantages:**
- ✅ Premium brand perception
- ✅ Better privacy controls
- ✅ Higher user trust in medical apps
- ✅ Integrated crash reporting

**Limitations:**
- 🚫 Requires Apple Developer account ($99/year)
- 🚫 Requires Mac for development
- 🚫 Device registration for ad-hoc testing
- 🚫 Slower review process
- 🚫 More restrictive guidelines

**Best for:**
- Healthcare professionals with iPhones
- Pilot facilities with iOS devices
- Premium positioning

---

## Deployment Workflow

### Phase 1: Android Beta (CURRENT)

```
┌─────────────────────┐
│ Developer Commits   │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ GitHub Actions CI   │
│ - Run tests         │
│ - Build AAB         │
│ - Sign with keystore│
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ Upload to Play      │
│ Console (Internal)  │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ 10-20 PHC Core Team │
│ Test & Report Bugs  │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ Fix Issues          │
│ Iterate Rapidly     │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ Promote to Closed   │
│ Testing (30+ users) │
└─────────────────────┘
```

**Timeline:** 2-4 weeks beta testing

### Phase 2: iOS Beta (BLOCKED)

```
┌─────────────────────┐
│ BLOCKED:            │
│ Apple Developer     │
│ Account Enrollment  │
│ (3-4 weeks)         │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ Certificate Setup   │
│ (macOS required)    │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ Build & Archive     │
│ in Xcode            │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ Upload to           │
│ TestFlight          │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ Internal Testing    │
│ (10-20 testers)     │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ Beta Review (1-2d)  │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ External Testing    │
│ (30+ testers)       │
└─────────────────────┘
```

**Timeline:** 3-4 weeks enrollment + 2-4 weeks testing

### Phase 3: Production Release

Both platforms follow similar promotion path:

```
Beta Testing → Production Review → Staged Rollout → Full Release
   (2-4 weeks)      (1-7 days)        (1-2 weeks)     (Monitored)
```

---

## Beta Tester Target Groups

### Priority 1: Internal Team (10-20 testers)
- University of Cordilleras developers
- PHC clinical advisors
- QA team members
- Project stakeholders

**Distribution:**
- Android: Internal Testing track
- iOS: Internal Testing group

### Priority 2: Pilot Facilities (20-30 testers)
- 8 partner healthcare facilities
- Nurses and physicians
- Health unit administrators

**Distribution:**
- Android: Closed Testing track
- iOS: External Testing group

### Priority 3: Extended Network (30+ testers)
- DOH partner clinics
- University of Cordilleras faculty
- Healthcare worker volunteers

**Distribution:**
- Android: Open Testing (optional)
- iOS: Public link (optional)

---

## Support Infrastructure

### Beta Feedback Channels

**Primary Email:**
```
beta-feedback@juanheart.ph
```
- Monitored daily during beta period
- Auto-response with ticket number
- 24-hour response SLA

**Support Email:**
```
support@juanheart.ph
```
- Technical issues and troubleshooting
- Account/login problems

**Clinical Inquiries:**
```
clinical@juanheart.ph
```
- Medical accuracy questions
- Risk assessment validation
- PHC algorithm clarifications

### Feedback Collection Tools

1. **In-App Feedback:**
   - Settings → Send Beta Feedback
   - Links to email template

2. **Google Forms Survey:**
   - [Beta Testing Survey](https://forms.gle/XXXXXX)
   - Sent weekly to active testers

3. **Play Console Reviews:**
   - Monitored via Play Console dashboard
   - Responded within 48 hours

4. **TestFlight Feedback:**
   - Shake-to-report (iOS)
   - Reviewed in App Store Connect

5. **WhatsApp Support Group:**
   - Quick questions and community support
   - Moderated by QA team

---

## Metrics and Success Criteria

### Beta Testing Goals

**Enrollment Targets:**
- [ ] 30+ total beta testers across platforms
- [ ] 80%+ opt-in rate from invitations
- [ ] 90%+ install rate after opt-in
- [ ] 60%+ weekly active testers

**Quality Targets:**
- [ ] <1% crash rate
- [ ] <5% of sessions experience errors
- [ ] Average rating >4.0 stars
- [ ] 100+ assessments completed
- [ ] 50+ appointments booked
- [ ] 80%+ positive feedback sentiment

**Performance Targets:**
- [ ] App start time <3 seconds (cold start)
- [ ] Screen load time <500ms
- [ ] API response time <2 seconds
- [ ] Offline sync success rate >95%

**Coverage Targets:**
- [ ] Test on 5+ different device models
- [ ] Test on Android 8-14
- [ ] Test on iOS 12-17 (when available)
- [ ] Test on 2GB RAM devices
- [ ] Test on slow 3G connections

### Production Release Criteria

Only promote to production when:
- [ ] All critical bugs resolved
- [ ] Crash rate <0.5% for 1 week
- [ ] 90%+ tester satisfaction
- [ ] PHC clinical team approval
- [ ] Data privacy audit passed
- [ ] Security penetration testing completed
- [ ] Performance benchmarks met
- [ ] Offline functionality validated
- [ ] Regulatory compliance verified

---

## Timeline Summary

### Android Beta (Ready to Start)

| Week | Activity | Deliverable |
|------|----------|-------------|
| 1 | Internal testing setup | 10 testers, first build |
| 2 | Bug fixes, iteration | 3-5 releases |
| 3 | Closed testing launch | 30+ testers |
| 4 | Feedback collection | Survey results, bugs triaged |
| 5-6 | Production candidate | Final testing, review prep |

**Total:** 6 weeks to production-ready

### iOS Beta (Blocked)

| Week | Activity | Status |
|------|----------|--------|
| 1-2 | D-U-N-S Number request | 🚫 Not started |
| 3-4 | Apple Developer enrollment | 🚫 Blocked by D-U-N-S |
| 5 | Certificate setup | 🚫 Blocked by account |
| 6 | First build upload | 🚫 Blocked by account |
| 7-8 | Internal testing | 🚫 Blocked by account |
| 9-10 | External testing | 🚫 Blocked by account |

**Total:** 10 weeks to production-ready (after unblocking)

---

## Cost Summary

### One-Time Costs

| Item | Cost | Status |
|------|------|--------|
| Google Play Developer | $25 USD | ✅ Paid |
| Android Keystore Setup | Free | ✅ Complete |
| Play Console Configuration | Free | 🔄 In Progress |
| Apple Developer Program | $99 USD | 🚫 Not Paid |
| iOS Certificates | Included | 🚫 Blocked |
| Mac Computer (if needed) | $1,000+ USD | ❓ TBD |

### Recurring Costs

| Item | Cost | Frequency |
|------|------|-----------|
| Google Play (after first year) | Free | N/A |
| Apple Developer Program | $99 USD | Annual |
| CI/CD (GitHub Actions) | Free | N/A |
| CI/CD (Codemagic, optional) | $95+ USD | Monthly |

**Total Required Investment:**
- Android only: $25 (already paid)
- Android + iOS: $124/year (+ Mac if needed)

---

## Resource Requirements

### Development Team

**Android Deployment:**
- [ ] 1x Android developer (keystore, Play Console)
- [ ] 1x DevOps engineer (CI/CD, GitHub Actions)
- [ ] 1x QA tester (beta coordination)

**iOS Deployment:**
- [ ] 1x iOS developer (Xcode, certificates)
- [ ] 1x Mac computer (build and archive)
- [ ] 1x DevOps engineer (fastlane, automation)
- [ ] 1x QA tester (TestFlight coordination)

### Beta Testing Team

**Coordinators:**
- [ ] 1x PHC clinical lead (medical validation)
- [ ] 1x UC faculty advisor (research coordination)
- [ ] 1x Community health liaison (pilot facility engagement)

**Support Staff:**
- [ ] 1x Customer support (email, WhatsApp)
- [ ] 1x Technical support (troubleshooting)

### Equipment

**Android:**
- ✅ Any development machine (Windows/Mac/Linux)
- ✅ 5+ Android test devices (various models)

**iOS:**
- 🚫 Mac computer (macOS 12+)
- 🚫 5+ iOS test devices (iPhone 8+, iPad)

---

## Security Considerations

### Keystore/Certificate Security

**Android:**
- ✅ Keystore backed up in 3 locations
- ✅ Passwords in GitHub Secrets
- ✅ .gitignore excludes keystore files
- [ ] Annual security audit scheduled

**iOS:**
- 🚫 Distribution certificate not yet created
- 🚫 Private key security protocol TBD
- 🚫 Fastlane match configuration pending

### Data Protection

**Beta Testing:**
- [ ] Use anonymized test data (no real patient info)
- [ ] Inform testers of data collection in consent form
- [ ] GDPR/Data Privacy Act compliance verified
- [ ] Test data purged after beta period

**Production:**
- [ ] End-to-end encryption (AES-256)
- [ ] TLS 1.3 for all API calls
- [ ] No hardcoded credentials in app
- [ ] Firebase security rules validated

---

## Troubleshooting Quick Reference

### Android Issues

**Build fails:**
```bash
flutter clean && flutter pub get && flutter build appbundle --release
```

**Keystore error:**
- Check `android/key.properties` exists
- Verify passwords in GitHub Secrets
- Re-download keystore from backup

**Upload rejected:**
- Increment version code in `pubspec.yaml`
- Verify signing certificate matches

### iOS Issues (When Unblocked)

**Certificate error:**
- Re-download from developer.apple.com
- Check private key in Keychain
- Regenerate provisioning profile

**Archive fails:**
- Clean build: Cmd+Shift+K
- Delete derived data
- Re-run `pod install`

**Upload stuck:**
- Wait 24 hours
- Check Activity tab for errors
- Re-upload with new build number

---

## Next Steps

### Immediate Actions (This Week)

**Android Beta:**
1. [ ] Complete Play Console app listing
2. [ ] Upload first AAB to Internal Testing
3. [ ] Invite 10 core team testers
4. [ ] Send invitation emails with testing guide
5. [ ] Monitor first installs and feedback

**iOS Preparation:**
1. [ ] Check if UC has D-U-N-S Number
2. [ ] Request budget approval for $99 developer account
3. [ ] Identify Mac computer for builds
4. [ ] Draft authorization letter for Apple enrollment
5. [ ] Document iOS timeline and dependencies

### Short-Term (Next 2-4 Weeks)

**Android:**
- [ ] Iterate based on internal tester feedback
- [ ] Fix critical bugs from beta
- [ ] Expand to Closed Testing (30+ testers)
- [ ] Collect quantitative metrics (crash rate, engagement)
- [ ] Prepare production release candidate

**iOS:**
- [ ] Submit Apple Developer enrollment (if approved)
- [ ] Wait for verification call
- [ ] Set up development environment
- [ ] Configure certificates and profiles

### Long-Term (Next 1-3 Months)

**Both Platforms:**
- [ ] Complete beta testing period
- [ ] Achieve success criteria metrics
- [ ] Submit for production review
- [ ] Plan staged rollout strategy
- [ ] Prepare marketing materials
- [ ] Coordinate launch with PHC/UC

---

## Contact Information

**Project Lead:**
- Email: project-lead@juanheart.ph
- Phone: +63 2 8925 2401

**DevOps Team:**
- Email: devops@juanheart.ph
- GitHub: @uc-juanheart

**Clinical Advisory:**
- Email: clinical@pchrd.doh.gov.ph
- PHC Contact: Dr. [Name], Preventive Cardiology

**Beta Testing Support:**
- Email: beta-feedback@juanheart.ph
- WhatsApp: +63 917 XXX XXXX
- Support Hours: Mon-Fri 9am-5pm PHT

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | Jan 2025 | Initial deployment documentation | DevOps Team |
| 1.1 | TBD | iOS unblocked, first TestFlight release | TBD |
| 2.0 | TBD | Production release documentation | TBD |

---

**Last Updated:** January 2025
**Document Owner:** DevOps Lead
**Review Schedule:** Monthly during beta, quarterly after production
**Status:** Android Ready, iOS Blocked (Apple Developer Account)
