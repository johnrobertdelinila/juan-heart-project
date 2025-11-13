# Deployment Quick Reference

## Quick Deploy Commands

### Android

```bash
# Tag-based automatic deployment
git tag v1.0.0
git push origin v1.0.0

# Manual deployment to internal track
gh workflow run deploy-android.yml -f track=internal

# Production deployment with phased rollout
gh workflow run deploy-android.yml -f track=production -f rollout_percentage=20
```

### iOS (Once Account Active)

```bash
# Tag-based automatic deployment
git tag v1.0.0-ios
git push origin v1.0.0-ios

# Manual deployment to TestFlight internal
gh workflow run deploy-ios.yml -f deployment_target=testflight-internal

# Production deployment with phased release
gh workflow run deploy-ios.yml -f deployment_target=production -f enable_phased_release=true
```

---

## Deployment Tracks

### Android (Google Play)
- `internal` - 100 testers, instant deployment
- `alpha` - Closed testing, phased rollout
- `beta` - Open/closed testing
- `production` - Live release, phased rollout (20% → 50% → 100%)

### iOS (App Store)
- `testflight-internal` - 100 users, no review, instant
- `testflight-external` - 10,000 users, beta review required
- `production` - App Store, full review, 7-day phased rollout

---

## Emergency Rollback

### Android
```bash
# Halt rollout in Play Console
1. Go to Release Management
2. Click "Halt rollout"
3. Upload previous version AAB
4. Promote to production
```

### iOS
```bash
# TestFlight rollback
1. Disable problematic build
2. Re-enable previous build
3. Notify testers

# App Store emergency
1. Remove from sale (immediate)
2. Submit hotfix for expedited review
3. Contact Apple Developer Support
```

---

## Required GitHub Secrets

### Android (5 + 5 shared)
```
PLAY_STORE_SERVICE_ACCOUNT_JSON
ANDROID_KEYSTORE_BASE64
ANDROID_STORE_PASSWORD
ANDROID_KEY_PASSWORD
ANDROID_KEY_ALIAS
```

### iOS (6 + 5 shared)
```
IOS_CERTIFICATE_BASE64
IOS_CERTIFICATE_PASSWORD
IOS_PROVISION_PROFILE_BASE64
APP_STORE_CONNECT_API_KEY_BASE64
APP_STORE_CONNECT_ISSUER_ID
APP_STORE_CONNECT_KEY_ID
```

### Shared (both platforms)
```
TWILIO_ACCOUNT_SID
TWILIO_AUTH_TOKEN
TWILIO_NUMBER
GOOGLE_GEOCODING_API_KEY
EDUCATIONAL_CONTENT_API_URL
```

---

## Version Numbering

```yaml
# pubspec.yaml
version: 1.0.0+1
#         │ │ │  │
#         │ │ │  └─ Build number (auto-incremented from git commits)
#         │ │ └──── Patch (bug fixes)
#         │ └────── Minor (new features, backward compatible)
#         └──────── Major (breaking changes)
```

**Rules:**
- Build number must always increase
- Use semantic versioning
- Tag format: `v1.0.0` (Android) or `v1.0.0-ios` (iOS)

---

## Monitoring URLs

### Android
- [Play Console Dashboard](https://play.google.com/console/u/0/developers/com.uc.juanheart)
- [Crash Reports](https://play.google.com/console/u/0/developers/com.uc.juanheart/vitals/crashes)
- [User Reviews](https://play.google.com/console/u/0/developers/com.uc.juanheart/user-feedback)

### iOS
- [App Store Connect](https://appstoreconnect.apple.com)
- [TestFlight](https://appstoreconnect.apple.com/apps/testflight)
- [Crash Reports](https://appstoreconnect.apple.com/apps/crashes)

---

## Critical Metrics

**Stop Rollout If:**
- Crash rate > 2%
- ANR rate > 1%
- Star rating drops > 0.5
- Critical bugs reported

**Proceed If (24-48 hours):**
- Crash rate < 1%
- ANR rate < 0.5%
- No critical bugs
- Positive feedback

---

## Common Issues & Quick Fixes

### "Service account authentication failed"
```bash
# Re-encode service account JSON
cat service-account.json | base64 | pbcopy
# Update GitHub Secret: PLAY_STORE_SERVICE_ACCOUNT_JSON
```

### "Version code already exists"
```yaml
# Increment in pubspec.yaml
version: 1.0.1+2  # Changed from 1.0.0+1
```

### "AAB signature verification failed"
```bash
# Re-encode keystore
cat juan-heart-release.jks | base64 | pbcopy
# Update GitHub Secret: ANDROID_KEYSTORE_BASE64
```

### "Apple Developer account not configured"
```bash
# Complete iOS setup (see DEPLOYMENT_GUIDE.md)
# Enroll in Apple Developer Program ($99/year)
# Generate certificates and provisioning profiles
# Add all iOS secrets to GitHub
```

---

## Workflow Status

| Workflow | Status | Ready to Use |
|----------|--------|--------------|
| ci.yml | Active | Yes |
| build-android.yml | Active | Yes |
| build-ios.yml | Blocked | No (needs Apple account) |
| deploy-android.yml | Ready | Yes (needs secrets) |
| deploy-ios.yml | Ready | No (needs Apple account) |

---

## Support

- **Full Documentation**: `.github/DEPLOYMENT_GUIDE.md`
- **Troubleshooting**: See DEPLOYMENT_GUIDE.md § Troubleshooting
- **Issues**: Create GitHub issue
- **Emergency**: Contact project lead

---

**Last Updated**: November 9, 2025 (Phase 2D)
