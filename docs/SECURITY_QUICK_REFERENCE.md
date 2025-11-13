# Juan Heart Mobile - Security Quick Reference

**Status:** NOT VERIFIED AND TESTED
**Last Updated:** January 10, 2025

---

## Critical Security Alert

**EXPOSED CREDENTIALS DETECTED** (not committed to git, but present in local `.env` file)

### Immediate Actions Required

1. **Rotate Twilio Credentials** (HIGH PRIORITY)
   - Generate new Auth Token at https://console.twilio.com/
   - Update `.env` file with new values
   - Revoke old credentials
   - **Full Instructions:** `docs/CREDENTIAL_ROTATION_CHECKLIST.md` (Section 1)

2. **Rotate Google API Key** (MEDIUM PRIORITY)
   - Create new API key at https://console.cloud.google.com/
   - Apply restrictions (Geocoding API + bundle IDs only)
   - Update `.env` file
   - Delete old API key
   - **Full Instructions:** `docs/CREDENTIAL_ROTATION_CHECKLIST.md` (Section 2)

3. **Run Setup Script**
   ```bash
   bash scripts/setup_env.sh
   ```

---

## Daily Security Checklist

Before committing code:

- [ ] Run `git status` and verify `.env` is NOT staged
- [ ] Review `git diff` to ensure no secrets in code changes
- [ ] Never hardcode credentials (use environment variables)

Before pushing to GitHub:

- [ ] Run `git log --all -- .env` to verify no .env in history
- [ ] Confirm all team members have latest `.gitignore`
- [ ] Check CI/CD secrets are up to date

---

## Quick Commands

### Check if .env is tracked by git
```bash
git ls-files .env
# Should return: nothing (file not found)
```

### Remove .env from git tracking (if accidentally added)
```bash
git rm --cached .env
git commit -m "chore(security): remove .env from git tracking"
```

### Clean git history (if .env was committed)
```bash
# WARNING: Rewrites history, coordinate with team
brew install bfg
bfg --delete-files .env
git reflog expire --expire=now --all
git gc --prune=now --aggressive
git push origin --force --all
```

### Verify .gitignore works
```bash
git check-ignore -v .env
# Should return: .gitignore:137:.env  .env
```

---

## Emergency Contacts

**Security Incidents:** [security@juanheart.ph] (replace with real email)
**DevOps Team:** [devops@juanheart.ph] (replace with real email)

---

## Documentation Index

| Document | Purpose | Priority |
|----------|---------|----------|
| **CREDENTIAL_MANAGEMENT.md** | Complete credential security guide | READ FIRST |
| **CREDENTIAL_ROTATION_CHECKLIST.md** | Step-by-step rotation procedures | USE IMMEDIATELY |
| **SECURITY_AUDIT_REPORT.md** | Full audit findings and recommendations | REVIEW |
| **setup_env.sh** | Automated environment setup | RUN ON SETUP |

**All files located in:** `docs/` and `scripts/`

---

## Security Score

**Current:** 55/80 (69%) - NEEDS IMPROVEMENT
**Target:** 75/80 (94%) - EXCELLENT

**How to improve:**
1. Rotate credentials → +10 points
2. Install git-secrets → +5 points
3. Enable GitHub secret scanning → +5 points
4. Implement secret manager → +5 points

---

**Remember:** Security is everyone's responsibility. When in doubt, ask the security team.
