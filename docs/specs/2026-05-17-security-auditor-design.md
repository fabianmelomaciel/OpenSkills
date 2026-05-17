# Security Auditor — Superpowers Skill Design

## Overview

A security auditing agent for opencode superpowers that performs complete security assessment of vibecoding/AI-generated projects. Works as both an invocable skill and a recommended post-implementation gate.

## Architecture

```
skills/security-auditor/
├── SKILL.md                    ← Main skill + orchestration
├── scanners/
│   ├── secrets-scanner.ps1     ← API keys, tokens, passwords, .env leaks
│   ├── dep-audit.ps1           ← npm/pip/composer/go/composer audit
│   ├── sast-scanner.ps1        ← OWASP Top 10 patterns (SQLi, XSS, CSRF, IDOR, SSTI, etc.)
│   ├── infra-scanner.ps1       ← Dockerfiles, CORS, security headers, HTTPS, exposed ports
│   ├── db-scanner.ps1          ← SQL injection in queries, creds in code, exposed DB ports
│   └── cicd-scanner.ps1        ← GHA workflows, pipeline secrets, insecure actions
├── reports/                    ← Output directory per scan
```

## Orchestration Flow

1. **Detect project type** — language, framework, package manager, infra files
2. **Dispatch parallel subagents** — one per category (secrets, deps, SAST, infra, DB, CI/CD)
3. **Each subagent**: runs scanner script + manual code inspection for that category
4. **Merge results** into structured JSON report with severity levels
5. **Output**: executive summary + detailed findings + remediation steps

## Severity Matrix

| Level | Criteria | Action |
|-------|----------|--------|
| 🔴 Critical | Credentials exposed, RCE, SQLi, auth bypass | Block deployment, fix immediately |
| 🟡 High | Hardcoded secrets (low risk), misconfig, outdated deps with CVEs | Review & fix before merge |
| 🟠 Medium | Missing security headers, weak CSP, info disclosure | Schedule fix |
| 🟢 Low | Best practices, missing comments, verbose errors | Note for improvement |

## Audit Categories

### Secrets Scanner
- Regex patterns for API keys, tokens, private keys (AWS, GCP, GitHub, Stripe, etc.)
- .env files committed, .gitignore analysis
- Hardcoded passwords, connection strings
- npm/pip token leaks

### Dependency Audit
- `npm audit` / `yarn audit` for Node projects
- `pip audit` / `safety check` for Python
- `composer audit` for PHP
- `cargo audit` for Rust
- `go list -m` + vuln check for Go
- Check for outdated packages with known CVEs

### SAST (OWASP Top 10)
- SQL Injection patterns in all languages
- Cross-Site Scripting (XSS) in templates/renders
- CSRF protection absence
- Insecure Direct Object References (IDOR)
- Server-Side Template Injection (SSTI)
- Path traversal
- Insecure deserialization
- command injection via exec/shell
- Open redirects

### Infrastructure Scanner
- Dockerfile: root user, exposed ports, env vars, COPY instead of ADD
- CORS misconfiguration (wildcard origins)
- Security headers missing (HSTS, CSP, X-Frame-Options, etc.)
- HTTPS not enforced
- .env / secrets exposed in config files
- Exposed debug/ admin endpoints

### Database Scanner
- SQLi in raw queries and ORM usage
- Database credentials in source code
- Exposed database ports (3306, 5432, 27017)
- Missing input sanitization in DB calls
- Unsafe migrations (dropping tables, no rollback)

### CI/CD Scanner
- GitHub Actions: hardcoded secrets, untrusted actions, missing reviews
- Pipeline secrets exposed in logs
- Insecure deployment scripts
- Missing artifact signing
- Unpinned action versions

## Report Format

```json
{
  "project": "name",
  "scan_date": "2026-05-17",
  "summary": {
    "critical": 0,
    "high": 2,
    "medium": 5,
    "low": 3,
    "passed_categories": ["deps", "cicd"],
    "failed_categories": ["secrets", "sast"]
  },
  "findings": [
    {
      "id": "SEC-001",
      "severity": "high",
      "category": "secrets",
      "file": "src/config.js:15",
      "finding": "Hardcoded AWS access key",
      "remediation": "Move to environment variable or secrets manager",
      "code_snippet": "const AWS_KEY = 'AKIA...'"
    }
  ],
  "executive_summary": "2 critical and 5 high findings. Recommend fixing before deployment."
}
```

## CI/CD Integration

The skill recommends adding a post-implementation step:
- Run `security-auditor` skill before marking any project as complete
- Block deployment if critical findings exist
- Generate report artifact for review

## Verification Gate (Skill Behavior)

When invoked, the agent MUST:
1. Run ALL 6 categories (no skipping)
2. Report findings with severity and remediation
3. Block completion if critical findings exist
4. Provide actionable fix steps per finding

## Non-Goals
- NOT a runtime DAST scanner (dynamic analysis)
- NOT a network penetration testing tool
- NOT a compliance certification (SOC2, HIPAA, etc.)
- Focus on static + configuration + dependency analysis

## Future Scalability
- Add more language-specific rules
- Add OWASP dependency-check integration
- Add template for CI/CD yml generation
