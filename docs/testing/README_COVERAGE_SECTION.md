# Test Coverage Section for README.md

Add this section to the main README.md file to showcase test coverage infrastructure.

---

## Test Coverage

[![Coverage](https://img.shields.io/badge/coverage-TBD-blue?style=flat-square&logo=flutter)](./coverage/html/index.html)
[![Tests](https://img.shields.io/badge/tests-40%2B-brightgreen?style=flat-square&logo=flutter)](./test)
[![CI](https://github.com/YOUR_ORG/juan-heart-mobile/workflows/Coverage%20Report/badge.svg)](https://github.com/YOUR_ORG/juan-heart-mobile/actions)

Juan Heart Mobile maintains comprehensive test coverage with automated reporting and quality gates.

### Quick Start

```bash
# Generate coverage report
./scripts/generate_coverage.sh --html --open

# Check coverage thresholds
./scripts/coverage_check.sh

# Generate coverage badge
./scripts/coverage_badge.sh
```

### Coverage Thresholds

| Category | Minimum | Target | Status |
|----------|---------|--------|--------|
| Overall | 70% | 80% | 🔄 |
| Critical Paths | 80% | 90% | 🔄 |
| Services | 75% | 85% | 🔄 |
| UI Widgets | 60% | 70% | 🔄 |

### Documentation

- [Coverage Guide](./docs/testing/coverage_guide.md) - Complete usage instructions
- [Coverage Report](./docs/testing/coverage_report.md) - Current state and analysis
- [Testing Standards](./.claude/docs/testing-standards.md) - Testing best practices

### CI/CD Integration

Coverage is automatically generated and validated on:
- Pull requests to main branches
- Pushes to `main`, `master`, `develop`

Coverage reports are:
- Posted as PR comments
- Uploaded to Codecov
- Available as GitHub Actions artifacts

### View Coverage

- **Local:** `./scripts/generate_coverage.sh --html --open`
- **CI/CD:** [GitHub Actions Artifacts](https://github.com/YOUR_ORG/juan-heart-mobile/actions)
- **Codecov:** [Coverage Dashboard](https://codecov.io/gh/YOUR_ORG/juan-heart-mobile)

---

**Instructions:**
1. Replace `YOUR_ORG` with your GitHub organization name
2. Update the coverage badge URL after first coverage run
3. Add this section to README.md under ## Testing or ## Quality Assurance
