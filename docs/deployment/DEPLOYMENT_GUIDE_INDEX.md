# Juan Heart Mobile - Deployment Documentation Index

**Last Updated:** January 2025
**Document Owner:** JH-Git-Guardian

---

## Overview

This directory contains comprehensive operational guides for deploying Juan Heart Mobile to production app stores. These documents are designed to be actionable during high-pressure deployment situations.

---

## Quick Navigation

### Core Deployment Guides (Phase 4 - NEW)

| Document | Purpose | When to Use | Time Required |
|----------|---------|-------------|---------------|
| [01-google-play-release.md](./01-google-play-release.md) | Step-by-step Google Play production release | Regular Android deployments | 3-4 hours (first), 1-2 hours (subsequent) |
| [02-app-store-release.md](./02-app-store-release.md) | Step-by-step App Store production release | Regular iOS deployments | 4-6 hours (first), 2-3 hours (subsequent) |
| [03-hotfix-deployment.md](./03-hotfix-deployment.md) | Emergency hotfix procedures | Critical production bugs | 2-4 hours |
| [04-rollback-procedures.md](./04-rollback-procedures.md) | Production rollback guide | When deployment goes wrong | 30 min - 2 hours |
| [troubleshooting.md](./troubleshooting.md) | Common deployment errors and solutions | Troubleshooting build/deployment issues | 5-30 minutes per issue |

### Setup Guides (Phase 3)

| Document | Purpose | Status |
|----------|---------|--------|
| [00-credential-management.md](./00-credential-management.md) | Secure credential management | Complete |
| [android-keystore-generation.md](./android-keystore-generation.md) | Android code signing setup | Complete |
| [google-play-console-setup.md](./google-play-console-setup.md) | Google Play Console configuration | Complete |
| [testflight-setup.md](./testflight-setup.md) | iOS TestFlight beta testing | BLOCKED (Apple Developer account required) |
| [github-secrets-setup.md](./github-secrets-setup.md) | CI/CD secrets configuration | Complete |
| [README.md](./README.md) | Deployment overview | Complete |

---

## Deployment Decision Tree

```
┌─────────────────────────────────┐
│ What do you need to do?         │
└──────────────┬──────────────────┘
               │
        ┌──────┴──────┐
        │             │
    ANDROID         iOS
        │             │
        ▼             ▼
  ┌─────────┐   ┌─────────┐
  │ Regular │   │ Regular │
  │ Release?│   │ Release?│
  └────┬────┘   └────┬────┘
      YES           YES
       │             │
       │             │
       ▼             ▼
  01-google-play  02-app-store
  -release.md     -release.md
                  (BLOCKED)
       │
       │
  ┌────┴────┐
  │         │
 URGENT   BUILD
  BUG     ERROR?
  │         │
  ▼         ▼
03-hotfix  troubleshooting
.md        .md
  │
  │
  ▼
Deployed
but issue?
  │
  ▼
04-rollback
.md
```

---

## Usage Scenarios

### Scenario 1: Regular Production Release (Android)

**Goal:** Deploy version 1.5.0 to Google Play Store

**Steps:**
1. Read [01-google-play-release.md](./01-google-play-release.md)
2. Complete pre-deployment checklist (code quality, testing)
3. Bump version number (1.4.0 → 1.5.0)
4. Build release AAB
5. Upload to Play Console
6. Configure staged rollout (5% → 20% → 50% → 100%)
7. Monitor metrics at each stage
8. Proceed or halt based on success criteria

**Estimated Time:** 3-4 hours (first release), 1-2 hours (subsequent)

---

### Scenario 2: Emergency Hotfix

**Goal:** Fix critical bug in production app

**Steps:**
1. Read [03-hotfix-deployment.md](./03-hotfix-deployment.md)
2. Assess severity (use decision matrix)
3. Create hotfix branch (git flow)
4. Implement minimal fix
5. Fast-track testing (2-4 hours)
6. Deploy with 100% rollout (skip staging for critical fixes)
7. Monitor metrics intensively
8. Communicate with users

**Estimated Time:** 2-4 hours (development + testing + deployment)

**Decision Point:** Should you hotfix vs. wait for regular release?
- Use hotfix decision matrix in guide
- Consider: severity, users affected, workaround availability

---

### Scenario 3: Rollback After Bad Deployment

**Goal:** Revert to previous stable version

**Steps:**
1. Read [04-rollback-procedures.md](./04-rollback-procedures.md)
2. Assess: Rollback vs. forward-fix (use decision tree)
3. If rollback decided:
   - Android: Halt rollout, upload old version with new build number
   - iOS: Submit old code with new version number, request expedited review
4. Handle database migrations (if applicable)
5. Communicate with users (templates provided)
6. Test rolled-back version
7. Complete post-rollback incident report

**Estimated Time:**
- Google Play: 30 min - 2 hours
- App Store: 2-3 days (includes review time)

**Critical Decision:** When to rollback?
- New version WORSE than old version
- No quick forward-fix available
- >25% of users affected
- Data integrity at risk

---

### Scenario 4: Build Fails During Deployment

**Goal:** Diagnose and fix build errors

**Steps:**
1. Read [troubleshooting.md](./troubleshooting.md)
2. Run diagnostic checklist (scripts/diagnostic_check.sh)
3. Find error message in "Common Error Messages Decoder" table
4. Follow solution for specific error
5. If not listed, check similar errors in 24+ troubleshooting scenarios
6. If still stuck after 2 hours, escalate to team lead

**Estimated Time:** 5-30 minutes per issue

**Common Issues Covered:**
- Build errors (Gradle sync, Pods, Java version)
- Code signing failures (keystore, provisioning profiles)
- CI/CD workflow errors (GitHub Actions, fastlane)
- Deployment API errors (version conflicts, timeouts)
- Store rejections (security, privacy, crashes)
- ProGuard issues (obfuscation, mapping files)

---

## Document Structure

All deployment guides follow this consistent structure:

1. **Table of Contents** - Quick navigation
2. **Prerequisites** - What you need before starting
3. **Step-by-Step Procedures** - Detailed instructions with commands
4. **Decision Matrices** - Help choose between options
5. **Templates** - Communication, checklists, scripts
6. **Troubleshooting** - Common issues and fixes
7. **Quick Reference** - Command summaries
8. **Related Documentation** - Links to other guides

---

## Key Features

### Actionable Content
- Real command examples (copy-paste ready)
- Screenshot descriptions (where commands go)
- Time estimates for each procedure
- Success criteria clearly defined

### Decision Support
- Decision trees for complex scenarios
- When to X vs. Y matrices
- Risk assessment checklists
- Escalation guidelines

### Templates Included
- Slack announcements (team communication)
- Email templates (user communication)
- In-app messages (user notifications)
- Incident reports (post-mortem)
- Code snippets (consent dialogs, etc.)

### Best Practices
- Staged rollout strategies
- Monitoring metrics and thresholds
- Testing checklists (fast-track and standard)
- Security considerations
- Compliance guidelines (HIPAA, PDPA, App Store rules)

---

## Document Ownership

| Document | Primary Owner | Review Cycle |
|----------|--------------|--------------|
| 01-google-play-release.md | JH-Git-Guardian | Before each major release |
| 02-app-store-release.md | JH-Git-Guardian | After Apple Developer account setup |
| 03-hotfix-deployment.md | JH-Git-Guardian | After each hotfix (continuous improvement) |
| 04-rollback-procedures.md | JH-Git-Guardian | After each rollback incident |
| troubleshooting.md | JH-Git-Guardian | Update after each unique deployment issue |

---

## Deployment Metrics to Track

### Pre-Deployment
- [ ] All tests pass (coverage ≥80%)
- [ ] Flutter analyze clean (0 issues)
- [ ] APK/AAB size <40MB
- [ ] Cold start time <3 seconds

### During Deployment
- [ ] Crash-free users ≥99.5%
- [ ] ANR rate ≤0.1%
- [ ] Sync success rate ≥95%
- [ ] API error rate ≤1%

### Post-Deployment (7 days)
- [ ] Average rating ≥4.5 stars
- [ ] User complaints <5% of active users
- [ ] No critical bugs reported
- [ ] No emergency hotfixes needed

---

## Emergency Contacts

**For Deployment Issues:**
1. **Team Slack** (#dev-team): Common issues, quick questions
2. **Tech Lead** (@tech-lead): Complex deployment problems
3. **DevOps Team** (@devops): CI/CD infrastructure issues

**For Store Issues:**
4. **Google Play Support**: https://support.google.com/googleplay/android-developer/contact/
   - Response time: 24-48 hours (2-4 hours for emergencies)
5. **Apple Developer Support**: https://developer.apple.com/contact/
   - Response time: 1-3 days (24-48 hours for expedited reviews)

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | Jan 2025 | Initial deployment documentation (Phase 4 complete) | JH-Git-Guardian |
| | | - 01-google-play-release.md created | |
| | | - 02-app-store-release.md created (BLOCKED) | |
| | | - 03-hotfix-deployment.md created | |
| | | - 04-rollback-procedures.md created | |
| | | - troubleshooting.md created (24+ scenarios) | |

---

## Next Steps

### Immediate (Phase 4 - Complete)
- ✅ Google Play deployment guide
- ✅ App Store deployment guide (BLOCKED pending Apple account)
- ✅ Hotfix procedures
- ✅ Rollback procedures
- ✅ Troubleshooting guide

### Short-Term (After Apple Developer Account)
- [ ] Unblock App Store deployment guide
- [ ] Update testflight-setup.md with actual credentials
- [ ] Test iOS deployment end-to-end
- [ ] Update 02-app-store-release.md with real examples

### Long-Term (Continuous Improvement)
- [ ] Update troubleshooting.md with new issues encountered
- [ ] Add real incident reports to rollback guide
- [ ] Create video walkthroughs for complex procedures
- [ ] Automate more deployment steps (fastlane, CI/CD)

---

## Related Documentation

**Architecture & Development:**
- [.claude/docs/flutter-architecture.md](../../.claude/docs/flutter-architecture.md) - App architecture
- [PLANNING.md](../../PLANNING.md) - Project roadmap
- [TASKS.md](../../TASKS.md) - Current sprint tasks

**CI/CD:**
- [.github/workflows/](../../.github/workflows/) - CI/CD pipelines
- [docs/deployment/github-secrets-setup.md](./github-secrets-setup.md) - Secrets configuration

**Testing:**
- [.claude/docs/testing-standards.md](../../.claude/docs/testing-standards.md) - Test patterns
- [test/](../../test/) - Test suite

---

## Feedback & Improvements

**Have suggestions for improving these guides?**

1. **Found an error:** Create GitHub issue with label `documentation`
2. **Encountered new issue:** Add to troubleshooting.md and submit PR
3. **Process improvement:** Discuss in #dev-team Slack channel
4. **Unclear instructions:** Comment directly in guide and tag @jh-git-guardian

**Continuous Improvement Philosophy:**
These guides are living documents. Every deployment teaches us something new. Update the guides immediately after resolving unique issues to help the next developer.

---

**Document Maintained By:** JH-Git-Guardian
**Last Review:** January 2025
**Next Review:** After first production deployment

---

## Quick Start Checklist

**First-Time Deployment Setup:**
- [ ] Read [README.md](./README.md) for overview
- [ ] Complete [00-credential-management.md](./00-credential-management.md) (security)
- [ ] Generate Android keystore: [android-keystore-generation.md](./android-keystore-generation.md)
- [ ] Configure Play Console: [google-play-console-setup.md](./google-play-console-setup.md)
- [ ] Set up GitHub secrets: [github-secrets-setup.md](./github-secrets-setup.md)
- [ ] (iOS) Enroll in Apple Developer Program (currently BLOCKED)
- [ ] (iOS) Complete [testflight-setup.md](./testflight-setup.md)

**Before Each Deployment:**
- [ ] Review [01-google-play-release.md](./01-google-play-release.md) or [02-app-store-release.md](./02-app-store-release.md)
- [ ] Complete pre-deployment checklist in guide
- [ ] Run diagnostic check: `./scripts/diagnostic_check.sh`
- [ ] Notify team in Slack #dev-team
- [ ] Monitor metrics during rollout

**In Case of Emergency:**
- [ ] Critical bug: [03-hotfix-deployment.md](./03-hotfix-deployment.md)
- [ ] Deployment issue: [04-rollback-procedures.md](./04-rollback-procedures.md)
- [ ] Build error: [troubleshooting.md](./troubleshooting.md)

---

**Stay calm. Follow the guides. Deploy with confidence.**
