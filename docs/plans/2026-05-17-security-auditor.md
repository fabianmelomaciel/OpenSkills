# Security Auditor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create a security-auditor skill for opencode superpowers that performs complete security assessment of any project.

**Architecture:** Single SKILL.md with orchestration logic that dispatches subagents per security category, each using scanner scripts plus manual inspection. Scanner scripts in PowerShell for Windows-native operation.

**Tech Stack:** PowerShell 5.1 (scanners), YAML frontmatter + Markdown (SKILL.md), JSON (report format)

**Skill location:** `$env:USERPROFILE\.config\opencode\skills\security-auditor\`

---

### Task 1: Create directory structure and secrets scanner

**Files:**
- Create: `$env:USERPROFILE\.config\opencode\skills\security-auditor\scanners\secrets-scanner.ps1`
- Create: `$env:USERPROFILE\.config\opencode\skills\security-auditor\scanners\` (directory)

- [ ] **Step 1: Create directory structure**

Run:
```powershell
New-Item -ItemType Directory -Path "$env:USERPROFILE\.config\opencode\skills\security-auditor\scanners" -Force
New-Item -ItemType Directory -Path "$env:USERPROFILE\.config\opencode\skills\security-auditor\reports" -Force
```
Expected: Directories created.

- [ ] **Step 2: Write the secrets scanner script**

```powershell
param(
    [Parameter(Mandatory=$true)]
    [string]$ProjectPath
)

$findings = @()

# Patterns to detect
$patterns = @(
    @{ pattern = 'AKIA[0-9A-Z]{16}'; severity = 'critical'; name = 'AWS Access Key' }
    @{ pattern = '-----BEGIN (RSA |EC )?PRIVATE KEY-----'; severity = 'critical'; name = 'Private Key' }
    @{ pattern = 'sk_live_[0-9a-zA-Z]{24,}'; severity = 'critical'; name = 'Stripe Live Key' }
    @{ pattern = 'sk_test_[0-9a-zA-Z]{24,}'; severity = 'high'; name = 'Stripe Test Key' }
    @{ pattern = 'ghp_[0-9a-zA-Z]{36}'; severity = 'critical'; name = 'GitHub PAT' }
    @{ pattern = 'gho_[0-9a-zA-Z]{36}'; severity = 'critical'; name = 'GitHub OAuth' }
    @{ pattern = 'xox[bpsa]-[0-9a-zA-Z\-]{10,}'; severity = 'high'; name = 'Slack Token' }
    @{ pattern = 'SG\.[0-9a-zA-Z\-_]{22}\.[0-9a-zA-Z\-_]{43}'; severity = 'critical'; name = 'SendGrid Key' }
    @{ pattern = 'password\s*[:=]\s*["'']{1}[^"'']+["'']{1}'; severity = 'high'; name = 'Hardcoded Password' }
    @{ pattern = 'secret\s*[:=]\s*["'']{1}[^"'']+["'']{1}'; severity = 'high'; name = 'Hardcoded Secret' }
    @{ pattern = 'connection[_ ]?string\s*[:=]\s*["'']{1}[^"'']+["'']{1}'; severity = 'high'; name = 'Connection String' }
)

$excludeDirs = @('node_modules', 'vendor', '.git', 'venv', '__pycache__', 'bin', 'obj', '.next', 'build', 'dist', '.nuget')

Get-ChildItem -Path $ProjectPath -File -Recurse | Where-Object {
    $excludeDir = $_.DirectoryName
    $skip = $false
    foreach ($ex in $excludeDirs) {
        if ($excludeDir -match [regex]::Escape($ex)) { $skip = $true; break }
    }
    -not $skip
} | ForEach-Object {
    $content = Get-Content -LiteralPath $_.FullName -Raw -ErrorAction SilentlyContinue
    if (-not $content) { return }
    foreach ($p in $patterns) {
        $matches = [regex]::Matches($content, $p.pattern)
        foreach ($m in $matches) {
            $line = ($content.Substring(0, $m.Index) -split "`n").Count
            $contextStart = [Math]::Max(0, $m.Index - 40)
            $contextLen = [Math]::Min(80, $content.Length - $contextStart)
            $snippet = $content.Substring($contextStart, $contextLen) -replace "`n", " "
            $findings += @{
                id = "SEC-$(($findings.Count + 1).ToString('D3'))"
                severity = $p.severity
                category = "secrets"
                file = "$($_.FullName):$line"
                finding = "$($p.name) detected"
                remediation = "Move to environment variable or secrets manager (e.g. .env file, GitHub Secrets, AWS Secrets Manager)"
                code_snippet = $snippet.Trim()
            }
        }
    }
}

# Check for .env files committed
$envFiles = Get-ChildItem -Path $ProjectPath -Filter ".env*" -File -ErrorAction SilentlyContinue
foreach ($f in $envFiles) {
    $findings += @{
        id = "SEC-$(($findings.Count + 1).ToString('D3'))"
        severity = "high"
        category = "secrets"
        file = $f.FullName
        finding = ".env file found in repository"
        remediation = "Add .env* to .gitignore and use .env.example for documentation"
        code_snippet = ""
    }
}

# Check .gitignore for missing .env entries
$gitignore = Get-ChildItem -Path $ProjectPath -Filter ".gitignore" -File -ErrorAction SilentlyContinue | Select-Object -First 1
if ($gitignore) {
    $gitcontent = Get-Content -LiteralPath $gitignore.FullName -Raw -ErrorAction SilentlyContinue
    if ($gitcontent -notmatch '\.env') {
        $findings += @{
            id = "SEC-$(($findings.Count + 1).ToString('D3'))"
            severity = "medium"
            category = "secrets"
            file = $gitignore.FullName
            finding = ".gitignore does not contain .env entries"
            remediation = "Add `.env*` and `.env.local` to .gitignore"
            code_snippet = ""
        }
    }
}

return $findings | ConvertTo-Json -Depth 3
```

- [ ] **Step 3: Verify the script runs**

Run:
```powershell
& "$env:USERPROFILE\.config\opencode\skills\security-auditor\scanners\secrets-scanner.ps1" -ProjectPath "C:\laragon\www"
```
Expected: JSON array output (may be empty if no secrets found).

- [ ] **Step 4: Commit**

```bash
git -C "$env:USERPROFILE\.config\opencode" add "skills/security-auditor/scanners/secrets-scanner.ps1"
git -C "$env:USERPROFILE\.config\opencode" commit -m "feat: add secrets scanner for security auditor"
```

---

### Task 2: Create dependency auditor

**Files:**
- Create: `$env:USERPROFILE\.config\opencode\skills\security-auditor\scanners\dep-audit.ps1`

- [ ] **Step 1: Write the dependency auditor script**

```powershell
param(
    [Parameter(Mandatory=$true)]
    [string]$ProjectPath
)

$findings = @()
$hasAnyManager = $false

# npm audit
$packageJson = Get-ChildItem -Path $ProjectPath -Filter "package.json" -File -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.DirectoryName -notmatch 'node_modules' }
if ($packageJson) {
    $hasAnyManager = $true
    $packageLock = Get-ChildItem -Path $ProjectPath -Filter "package-lock.json" -File -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $packageLock) {
        $findings += @{
            id = "DEP-001"; severity = "medium"; category = "dependencies"
            file = "$(($packageJson | Select-Object -First 1).FullName)"
            finding = "No package-lock.json found"
            remediation = "Run `npm install` to generate package-lock.json for reproducible builds"
            code_snippet = ""
        }
    }
    # Try npm audit
    $auditResult = & npm audit --json 2>&1 | Out-String
    try {
        $audit = $auditResult | ConvertFrom-Json
        if ($audit.metadata.vulnerabilities) {
            $vulns = $audit.metadata.vulnerabilities
            if ($vulns.critical -gt 0) {
                $findings += @{
                    id = "DEP-002"; severity = "critical"; category = "dependencies"
                    file = "package.json"
                    finding = "$($vulns.critical) critical vulnerabilities in npm dependencies"
                    remediation = "Run `npm audit fix` or update affected packages manually"
                    code_snippet = "Critical: $($vulns.critical), High: $($vulns.high)"
                }
            }
            if ($vulns.high -gt 0) {
                $findings += @{
                    id = "DEP-003"; severity = "high"; category = "dependencies"
                    file = "package.json"
                    finding = "$($vulns.high) high vulnerabilities in npm dependencies"
                    remediation = "Run `npm audit fix` or update affected packages"
                    code_snippet = "High: $($vulns.high)"
                }
            }
        }
    } catch {}
}

# composer audit
$composerJson = Get-ChildItem -Path $ProjectPath -Filter "composer.json" -File -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.DirectoryName -notmatch 'vendor' }
if ($composerJson) {
    $hasAnyManager = $true
    $auditResult = & composer audit --format=json 2>&1 | Out-String
    try {
        $audit = $auditResult | ConvertFrom-Json
        if ($audit.actions) {
            $issues = $audit.actions | Where-Object { $_.type -eq 'advisory' } | Measure-Object | Select-Object -ExpandProperty Count
            if ($issues -gt 0) {
                $findings += @{
                    id = "DEP-004"; severity = "high"; category = "dependencies"
                    file = "composer.json"
                    finding = "$issues security advisories for PHP dependencies"
                    remediation = "Run `composer update` for affected packages"
                    code_snippet = ""
                }
            }
        }
    } catch {}
}

# pip audit (check requirements*.txt)
$reqFiles = Get-ChildItem -Path $ProjectPath -Filter "requirements*.txt" -File -ErrorAction SilentlyContinue
if ($reqFiles) {
    $hasAnyManager = $true
    $pipAuditAvailable = Get-Command "pip-audit" -ErrorAction SilentlyContinue
    if (-not $pipAuditAvailable) {
        $findings += @{
            id = "DEP-005"; severity = "low"; category = "dependencies"
            file = "requirements.txt"
            finding = "pip-audit not installed — cannot audit Python dependencies"
            remediation = "Run `pip install pip-audit && pip-audit`"
            code_snippet = ""
        }
    }
}

# Check for outdated packages in requirements.txt
foreach ($req in $reqFiles) {
    $content = Get-Content -LiteralPath $req.FullName -Raw -ErrorAction SilentlyContinue
    if ($content -match '==') {
        $pinned = ($content -split "`n" | Where-Object { $_ -match '==' }).Count
        $findings += @{
            id = "DEP-006"; severity = "low"; category = "dependencies"
            file = $req.FullName
            finding = "$pinned packages pinned to exact versions in $($req.Name)"
            remediation = "Consider using >= to allow patch updates"
            code_snippet = ""
        }
    }
}

if (-not $hasAnyManager) {
    $findings += @{
        id = "DEP-007"; severity = "low"; category = "dependencies"
        file = $ProjectPath
        finding = "No package manager detected (no package.json, composer.json, or requirements*.txt)"
        remediation = "Consider using a package manager for dependency management"
        code_snippet = ""
    }
}

return $findings | ConvertTo-Json -Depth 3
```

- [ ] **Step 2: Verify the script runs**

Run:
```powershell
& "$env:USERPROFILE\.config\opencode\skills\security-auditor\scanners\dep-audit.ps1" -ProjectPath "C:\laragon\www"
```
Expected: JSON array output.

- [ ] **Step 3: Commit**

```bash
git -C "$env:USERPROFILE\.config\opencode" add "skills/security-auditor/scanners/dep-audit.ps1"
git -C "$env:USERPROFILE\.config\opencode" commit -m "feat: add dependency auditor for security auditor"
```

---

### Task 3: Create SAST scanner (OWASP Top 10)

**Files:**
- Create: `$env:USERPROFILE\.config\opencode\skills\security-auditor\scanners\sast-scanner.ps1`

- [ ] **Step 1: Write the SAST scanner script**

```powershell
param(
    [Parameter(Mandatory=$true)]
    [string]$ProjectPath
)

$findings = @()
$excludeDirs = @('node_modules', 'vendor', '.git', 'venv', '__pycache__', 'bin', 'obj', '.next', 'build', 'dist')

# Map of pattern groups by vulnerability type
$checks = @(
    # SQL Injection
    @{ name = "SQL Injection - raw queries"; severity = "critical"
       patterns = @('execute\s*\(\s*["'']SELECT', 'query\s*\(\s*["'']SELECT', 'raw\s*\(\s*["'']SELECT', '\$this->db->query\("')
       extensions = @('.php', '.py', '.js', '.ts', '.java', '.go', '.rb') }
    @{ name = "SQL Injection - string interpolation"; severity = "critical"
       patterns = @('SELECT.*\+.*\$', 'SELECT.*\{.*\}.*FROM', "SELECT.*[''']\s*\+\s*")
       extensions = @('.php', '.py', '.js', '.ts', '.java', '.rb') }
    @{ name = "SQL Injection - exec with params"; severity = "high"
       patterns = @('exec\s*\(.*\$', 'mysql_query\s*\(.*\$')
       extensions = @('.php', '.py') }

    # XSS
    @{ name = "XSS - innerHTML assignment"; severity = "high"
       patterns = @('\.innerHTML\s*=', '\.outerHTML\s*=')
       extensions = @('.js', '.ts', '.jsx', '.tsx', '.vue', '.html') }
    @{ name = "XSS - dangerouslySetInnerHTML"; severity = "high"
       patterns = @('dangerouslySetInnerHTML')
       extensions = @('.jsx', '.tsx') }
    @{ name = "XSS - v-html"; severity = "high"
       patterns = @('v-html\s*=')
       extensions = @('.vue', '.html') }
    @{ name = "XSS - document.write"; severity = "high"
       patterns = @('document\.write\s*\(')
       extensions = @('.js', '.ts', '.html') }

    # Command Injection
    @{ name = "Command Injection - exec/shell"; severity = "critical"
       patterns = @('exec\s*\(', 'shell_exec\s*\(', 'system\s*\(', 'popen\s*\(', 'child_process\.exec\s*\(')
       extensions = @('.php', '.py', '.js', '.ts') }
    @{ name = "Command Injection - eval"; severity = "critical"
       patterns = @('\beval\s*\(', 'assert\s*\(')
       extensions = @('.php', '.py', '.js') }

    # Path Traversal
    @{ name = "Path Traversal - file inclusion"; severity = "high"
       patterns = @('include\s*\(.*\$', 'include_once\s*\(.*\$', 'require\s*\(.*\$', 'require_once\s*\(.*\$')
       extensions = @('.php') }
    @{ name = "Path Traversal - file read"; severity = "high"
       patterns = @('file_get_contents\s*\(.*\$', 'readfile\s*\(.*\$', 'fopen\s*\(.*\$')
       extensions = @('.php') }

    # CSRF
    @{ name = "Missing CSRF Protection"; severity = "high"
       patterns = @('@csrf_protection\s*=\s*False', '@csrf_exempt', 'csrf_exempt')
       extensions = @('.py') }
    @{ name = "Missing CSRF token check"; severity = "high"
       patterns = @('VerifyToken\s*\(\)')
       extensions = @('.cs', '.vb') }

    # Insecure Deserialization
    @{ name = "Insecure Deserialization - pickle"; severity = "critical"
       patterns = @('pickle\.loads\s*\(', 'pickle\.load\s*\(')
       extensions = @('.py') }
    @{ name = "Insecure Deserialization - unserialize"; severity = "critical"
       patterns = @('unserialize\s*\(')
       extensions = @('.php') }
    @{ name = "Insecure Deserialization - JSON.parse (unsafe)"; severity = "medium"
       patterns = @('JSON\.parse\s*\(')
       extensions = @('.js', '.ts') }
)

function MatchExtension($ext, $allowed) {
    foreach ($a in $allowed) {
        if ($ext -eq $a) { return $true }
    }
    return $false
}

Get-ChildItem -Path $ProjectPath -File -Recurse -ErrorAction SilentlyContinue | Where-Object {
    $excludeDir = $_.DirectoryName
    $skip = $false
    foreach ($ex in $excludeDirs) {
        if ($excludeDir -match [regex]::Escape($ex)) { $skip = $true; break }
    }
    -not $skip
} | ForEach-Object {
    $file = $_
    $ext = $_.Extension.ToLower()
    $content = Get-Content -LiteralPath $_.FullName -Raw -ErrorAction SilentlyContinue
    if (-not $content) { return }
    if ($ext -eq '.html' -or $ext -eq '.htm') {
        if ($content -match '<script[^>]*>') {
            $findings += @{
                id = "SAST-$(($findings.Count + 1).ToString('D3'))"
                severity = "medium"; category = "sast"
                file = $file.FullName
                finding = "Inline script tag in HTML (potential XSS vector)"
                remediation = "Move scripts to external files and implement CSP"
                code_snippet = ""
            }
        }
    }
    foreach ($check in $checks) {
        if (-not (MatchExtension $ext $check.extensions)) { continue }
        foreach ($p in $check.patterns) {
            $matches = [regex]::Matches($content, $p)
            foreach ($m in $matches) {
                $line = ($content.Substring(0, $m.Index) -split "`n").Count
                $contextStart = [Math]::Max(0, $m.Index - 30)
                $contextLen = [Math]::Min(60, $content.Length - $contextStart)
                $snippet = ($content.Substring($contextStart, $contextLen) -replace "`n", " ").Trim()
                $findings += @{
                    id = "SAST-$(($findings.Count + 1).ToString('D3'))"
                    severity = $check.severity; category = "sast"
                    file = "$($file.FullName):$line"
                    finding = $check.name
                    remediation = switch -Wildcard ($check.name) {
                        "SQL Injection*" { "Use parameterized queries / prepared statements" }
                        "XSS*" { "Sanitize output, use DOMPurify or escape HTML entities" }
                        "Command Injection*" { "Avoid exec/shell/system calls with user input. Use parameterized APIs" }
                        "Path Traversal*" { "Validate and sanitize file paths, use allowlists" }
                        default { "Review code for security implications" }
                    }
                    code_snippet = $snippet
                }
            }
        }
    }
}

return $findings | ConvertTo-Json -Depth 3
```

- [ ] **Step 2: Verify the script runs**

Run:
```powershell
& "$env:USERPROFILE\.config\opencode\skills\security-auditor\scanners\sast-scanner.ps1" -ProjectPath "C:\laragon\www"
```
Expected: JSON array output.

- [ ] **Step 3: Commit**

```bash
git -C "$env:USERPROFILE\.config\opencode" add "skills/security-auditor/scanners/sast-scanner.ps1"
git -C "$env:USERPROFILE\.config\opencode" commit -m "feat: add SAST scanner (OWASP Top 10) for security auditor"
```

---

### Task 4: Create infrastructure scanner

**Files:**
- Create: `$env:USERPROFILE\.config\opencode\skills\security-auditor\scanners\infra-scanner.ps1`

- [ ] **Step 1: Write the infra scanner script**

```powershell
param(
    [Parameter(Mandatory=$true)]
    [string]$ProjectPath
)

$findings = @()

# Check Dockerfile
$dockerfiles = Get-ChildItem -Path $ProjectPath -Filter "Dockerfile*" -File -Recurse -ErrorAction SilentlyContinue
foreach ($df in $dockerfiles) {
    $content = Get-Content -LiteralPath $df.FullName -Raw -ErrorAction SilentlyContinue
    if (-not $content) { continue }

    if ($content -match 'FROM\s+\S+:latest') {
        $findings += @{
            id = "INF-001"; severity = "high"; category = "infrastructure"
            file = $df.FullName
            finding = "Dockerfile uses `:latest` tag (unpredictable builds)"
            remediation = "Pin to specific version tags like `:18.04` or digest SHA"
            code_snippet = ""
        }
    }
    if ($content -match 'USER\s+root') {
        $findings += @{
            id = "INF-002"; severity = "medium"; category = "infrastructure"
            file = $df.FullName
            finding = "Docker container runs as root"
            remediation = "Add `USER nobody` or create a non-root user"
            code_snippet = ""
        }
    }
    if ($content -match 'EXPOSE\s+22\b') {
        $findings += @{
            id = "INF-003"; severity = "high"; category = "infrastructure"
            file = $df.FullName
            finding = "SSH port (22) exposed in Dockerfile"
            remediation = "Remove SSH exposure unless absolutely necessary"
            code_snippet = ""
        }
    }
}

# Check CORS in config files
$corsFiles = Get-ChildItem -Path $ProjectPath -Include "*.php", "*.py", "*.js", "*.ts", "*.json", "*.yaml", "*.yml" -File -Recurse -ErrorAction SilentlyContinue |
    Where-Object { $_.DirectoryName -notmatch 'node_modules|vendor|venv' }

foreach ($cf in $corsFiles) {
    $content = Get-Content -LiteralPath $cf.FullName -Raw -ErrorAction SilentlyContinue
    if (-not $content) { continue }
    if ($content -match 'Access-Control-Allow-Origin\s*[:=]\s*["'']\*["'']') {
        $findings += @{
            id = "INF-004"; severity = "high"; category = "infrastructure"
            file = $cf.FullName
            finding = "Wildcard CORS origin (`*`) detected"
            remediation = "Restrict Access-Control-Allow-Origin to specific origins"
            code_snippet = ""
        }
        break
    }
}

# Check .env files
$envFiles = Get-ChildItem -Path $ProjectPath -Filter ".env" -File -Recurse -ErrorAction SilentlyContinue |
    Where-Object { $_.DirectoryName -notmatch 'node_modules|vendor|venv' }
foreach ($ef in $envFiles) {
    $content = Get-Content -LiteralPath $ef.FullName -Raw -ErrorAction SilentlyContinue
    if ($content -match 'APP_DEBUG\s*=\s*true') {
        $findings += @{
            id = "INF-005"; severity = "high"; category = "infrastructure"
            file = $ef.FullName
            finding = "Debug mode enabled (APP_DEBUG=true)"
            remediation = "Set APP_DEBUG=false in production"
            code_snippet = ""
        }
    }
    if ($content -match 'APP_ENV\s*=\s*development') {
        $findings += @{
            id = "INF-006"; severity = "medium"; category = "infrastructure"
            file = $ef.FullName
            finding = "APP_ENV set to development (may expose sensitive info)"
            remediation = "Set APP_ENV=production in production environment"
            code_snippet = ""
        }
    }
}

# Check for debug endpoints
$debugPatterns = @('/debug', '/_debug', '/phpinfo', '/info\.php', 'laravel-debugbar', 'whoops\.')
$filesWithDebug = Get-ChildItem -Path $ProjectPath -Include "*.php", "*.py", "*.js", "*.ts", "*.conf" -File -Recurse -ErrorAction SilentlyContinue |
    Where-Object { $_.DirectoryName -notmatch 'node_modules|vendor|venv' }
foreach ($fd in $filesWithDebug) {
    $content = Get-Content -LiteralPath $fd.FullName -Raw -ErrorAction SilentlyContinue
    if (-not $content) { continue }
    foreach ($dp in $debugPatterns) {
        if ($content -match $dp) {
            $findings += @{
                id = "INF-007"; severity = "medium"; category = "infrastructure"
                file = $fd.FullName
                finding = "Debug endpoint or tool detected (`$dp`)"
                remediation = "Remove debug routes and tools before production deployment"
                code_snippet = ""
            }
            break
        }
    }
}

# Check for security headers config
$nginxConf = Get-ChildItem -Path $ProjectPath -Filter "nginx*.conf" -File -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
$htaccess = Get-ChildItem -Path $ProjectPath -Filter ".htaccess" -File -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
$middleware = Get-ChildItem -Path $ProjectPath -Include "*.php", "*.py", "*.js", "*.ts" -File -Recurse -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -match 'middleware|security' -and $_.DirectoryName -notmatch 'node_modules|vendor|venv' } | Select-Object -First 1

if (-not $nginxConf -and -not $htaccess -and -not $middleware) {
    $findings += @{
        id = "INF-008"; severity = "low"; category = "infrastructure"
        file = $ProjectPath
        finding = "No security headers configuration found (HSTS, CSP, X-Frame-Options)"
        remediation = "Configure security headers via nginx, .htaccess, or middleware"
        code_snippet = ""
    }
}

return $findings | ConvertTo-Json -Depth 3
```

- [ ] **Step 2: Verify the script runs**

Run:
```powershell
& "$env:USERPROFILE\.config\opencode\skills\security-auditor\scanners\infra-scanner.ps1" -ProjectPath "C:\laragon\www"
```
Expected: JSON array output.

- [ ] **Step 3: Commit**

```bash
git -C "$env:USERPROFILE\.config\opencode" add "skills/security-auditor/scanners/infra-scanner.ps1"
git -C "$env:USERPROFILE\.config\opencode" commit -m "feat: add infra scanner (Docker, CORS, config) for security auditor"
```

---

### Task 5: Create database scanner

**Files:**
- Create: `$env:USERPROFILE\.config\opencode\skills\security-auditor\scanners\db-scanner.ps1`

- [ ] **Step 1: Write the database scanner script**

```powershell
param(
    [Parameter(Mandatory=$true)]
    [string]$ProjectPath
)

$findings = @()
$excludeDirs = @('node_modules', 'vendor', '.git', 'venv', '__pycache__', 'bin', 'obj', '.next', 'build', 'dist')

# Check for hardcoded database credentials
Get-ChildItem -Path $ProjectPath -Include "*.php", "*.py", "*.js", "*.ts", "*.env", "*.yml", "*.yaml", "*.json", "*.xml", "*.conf", "*.sql" -File -Recurse -ErrorAction SilentlyContinue |
Where-Object {
    $excludeDir = $_.DirectoryName
    $skip = $false
    foreach ($ex in $excludeDirs) {
        if ($excludeDir -match [regex]::Escape($ex)) { $skip = $true; break }
    }
    -not $skip
} | ForEach-Object {
    $content = Get-Content -LiteralPath $_.FullName -Raw -ErrorAction SilentlyContinue
    if (-not $content) { return }

    # DB credentials
    if ($content -match "DB_PASSWORD\s*=\s*[''""]?[^''""\s]+[''""]?" -or
        $content -match "db_password\s*[:=]\s*[''""][^''""]+[''""]" -or
        $content -match "password\s*=>\s*[''""]") {
        $findings += @{
            id = "DB-001"; severity = "high"; category = "database"
            file = $_.FullName
            finding = "Database password found in source/config file"
            remediation = "Use environment variables or a secrets manager for DB credentials"
            code_snippet = ""
        }
    }

    # Unsafe SQL patterns
    if ($_.Extension -in '.sql', '.php', '.py', '.js') {
        # DROP without safeguards
        if ($content -match '\bDROP\s+(TABLE|DATABASE)\b' -and $content -notmatch '--\s*(skip|comment)') {
            $findings += @{
                id = "DB-002"; severity = "critical"; category = "database"
                file = $_.FullName
                finding = "Destructive SQL operation (DROP TABLE/DATABASE) detected"
                remediation = "Never use DROP in production migrations. Use soft deletes instead"
                code_snippet = ""
            }
        }
        # TRUNCATE
        if ($content -match '\bTRUNCATE\b') {
            $findings += @{
                id = "DB-003"; severity = "high"; category = "database"
                file = $_.FullName
                finding = "TRUNCATE operation detected (data loss risk)"
                remediation = "Consider soft delete or backup before truncating"
                code_snippet = ""
            }
        }
    }

    # Exposed DB ports in config
    if ($content -match '3306' -or $content -match '5432' -or $content -match '27017' -or $content -match '6379') {
        $findings += @{
            id = "DB-004"; severity = "low"; category = "database"
            file = $_.FullName
            finding = "Database port number detected in config (3306/5432/27017/6379)"
            remediation = "Ensure database ports are not exposed publicly, restrict to internal network"
            code_snippet = ""
        }
    }
}

# Check for SQL files that may contain unsafe operations
$sqlFiles = Get-ChildItem -Path $ProjectPath -Filter "*.sql" -File -Recurse -ErrorAction SilentlyContinue |
    Where-Object { $_.DirectoryName -notmatch 'node_modules|vendor' }

if ($sqlFiles.Count -gt 10) {
    $findings += @{
        id = "DB-005"; severity = "low"; category = "database"
        file = "$(($sqlFiles | Select-Object -First 1).DirectoryName)"
        finding = "Large number of SQL files ($($sqlFiles.Count)) — review for unsafe operations"
        remediation = "Use structured migrations with rollback support"
        code_snippet = ""
    }
}

return $findings | ConvertTo-Json -Depth 3
```

- [ ] **Step 2: Verify the script runs**

Run:
```powershell
& "$env:USERPROFILE\.config\opencode\skills\security-auditor\scanners\db-scanner.ps1" -ProjectPath "C:\laragon\www"
```
Expected: JSON array output.

- [ ] **Step 3: Commit**

```bash
git -C "$env:USERPROFILE\.config\opencode" add "skills/security-auditor/scanners/db-scanner.ps1"
git -C "$env:USERPROFILE\.config\opencode" commit -m "feat: add database scanner for security auditor"
```

---

### Task 6: Create CI/CD scanner

**Files:**
- Create: `$env:USERPROFILE\.config\opencode\skills\security-auditor\scanners\cicd-scanner.ps1`

- [ ] **Step 1: Write the CI/CD scanner script**

```powershell
param(
    [Parameter(Mandatory=$true)]
    [string]$ProjectPath
)

$findings = @()

# Check GitHub Actions
$ghaFiles = Get-ChildItem -Path $ProjectPath -Filter "*.yml" -Recurse -ErrorAction SilentlyContinue |
    Where-Object { $_.DirectoryName -match '\\.github\\workflows' -and $_.DirectoryName -notmatch 'node_modules|vendor' }

if ($ghaFiles.Count -eq 0) {
    $ghaFiles = Get-ChildItem -Path $ProjectPath -Filter "*.yaml" -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.DirectoryName -match '\\.github\\workflows' -and $_.DirectoryName -notmatch 'node_modules|vendor' }
}

if ($ghaFiles.Count -gt 0) {
    foreach ($gf in $ghaFiles) {
        $content = Get-Content -LiteralPath $gf.FullName -Raw -ErrorAction SilentlyContinue
        if (-not $content) { continue }

        # Check for hardcoded secrets
        if ($content -match 'password=|secret=|api_key=|token=') {
            $findings += @{
                id = "CICD-001"; severity = "critical"; category = "cicd"
                file = $gf.FullName
                finding = "Potential hardcoded secret in CI/CD workflow"
                remediation = "Use GitHub Secrets (`secrets.*`) instead of hardcoding values"
                code_snippet = ""
            }
        }

        # Check for untrusted action versions
        if ($content -match 'uses:\s+\S+@main' -or $content -match 'uses:\s+\S+@master') {
            $findings += @{
                id = "CICD-002"; severity = "high"; category = "cicd"
                file = $gf.FullName
                finding = "CI/CD action pinned to `@main` or `@master` (unstable)"
                remediation = "Pin actions to specific commit SHA or semver tag"
                code_snippet = ""
            }
        }

        # Check for `pull_request_target` without review
        if ($content -match 'pull_request_target') {
            $findings += @{
                id = "CICD-003"; severity = "high"; category = "cicd"
                file = $gf.FullName
                finding = "`pull_request_target` trigger used (privileged execution)"
                remediation = "Ensure pull_request_target workflows have proper review gates"
                code_snippet = ""
            }
        }

        # Check for checkout on PR without ref
        if ($content -match 'actions/checkout@' -and $content -notmatch 'ref:|\$') {
            $findings += @{
                id = "CICD-004"; severity = "low"; category = "cicd"
                file = $gf.FullName
                finding = "Git checkout without explicit ref (may use untrusted code)"
                remediation = "Specify `ref: ${{ github.event.pull_request.head.sha }}` for PR triggers"
                code_snippet = ""
            }
        }

        # Check for missing review requirement
        if ($content -match 'pull_request:' -and $content -notmatch 'required_reviews') {
            $findings += @{
                id = "CICD-005"; severity = "medium"; category = "cicd"
                file = $gf.FullName
                finding = "No code review requirement found for pull requests"
                remediation = "Enable branch protection rules requiring reviews"
                code_snippet = ""
            }
        }
    }
} else {
    $findings += @{
        id = "CICD-006"; severity = "low"; category = "cicd"
        file = $ProjectPath
        finding = "No CI/CD workflows found (no .github/workflows directory)"
        remediation = "Consider adding CI/CD pipelines (GitHub Actions, GitLab CI, etc.)"
        code_snippet = ""
    }
}

# Check for Docker Compose
$composeFiles = Get-ChildItem -Path $ProjectPath -Include "docker-compose*.yml", "docker-compose*.yaml" -File -Recurse -ErrorAction SilentlyContinue |
    Where-Object { $_.DirectoryName -notmatch 'node_modules|vendor' }
foreach ($cf in $composeFiles) {
    $content = Get-Content -LiteralPath $cf.FullName -Raw -ErrorAction SilentlyContinue
    if ($content -match 'environment:\s*\n\s+-?\s*\w+\s*[:=]\s*["''](?!\$)') {
        $findings += @{
            id = "CICD-007"; severity = "high"; category = "cicd"
            file = $cf.FullName
            finding = "Hardcoded environment variable in docker-compose"
            remediation = "Use .env file or Docker secrets for sensitive values"
            code_snippet = ""
        }
    }
}

return $findings | ConvertTo-Json -Depth 3
```

- [ ] **Step 2: Verify the script runs**

Run:
```powershell
& "$env:USERPROFILE\.config\opencode\skills\security-auditor\scanners\cicd-scanner.ps1" -ProjectPath "C:\laragon\www"
```
Expected: JSON array output.

- [ ] **Step 3: Commit**

```bash
git -C "$env:USERPROFILE\.config\opencode" add "skills/security-auditor/scanners/cicd-scanner.ps1"
git -C "$env:USERPROFILE\.config\opencode" commit -m "feat: add CI/CD scanner for security auditor"
```

---

### Task 7: Write the main SKILL.md (orchestration + all security logic)

**Files:**
- Create: `$env:USERPROFILE\.config\opencode\skills\security-auditor\SKILL.md`

- [ ] **Step 1: Write SKILL.md with orchestration, all 6 categories, severity matrix, remediation playbooks, and verification gate**

```markdown
---
name: security-auditor
description: Use when completing development, before deployment, after vibecoding/AI code generation, or when reviewing project security. Covers secrets, dependencies, SAST (OWASP Top 10), infrastructure, database, and CI/CD.
---

# Security Auditor Agent

## Core Identity

You are a **Security Auditor** agent. Your job is to find security vulnerabilities in any project, report them with severity levels, and provide concrete remediation steps. You operate with a zero-trust mindset: assume nothing is secure until verified.

You do NOT implement fixes. You find, report, and recommend.

## Audit Categories (MUST run ALL 6)

### 1. Secrets Scanner
- Run: `scanners/secrets-scanner.ps1 -ProjectPath <path>`
- Then manually review .gitignore, .dockerignore, and any config files
- **Critical findings**: committed API keys, private keys, tokens. Must be revoked.
- Look for: .env files, hardcoded passwords, connection strings, npmrc, pip.conf with tokens

### 2. Dependency Auditor
- Run: `scanners/dep-audit.ps1 -ProjectPath <path>`
- Also inspect package.json / composer.json / requirements.txt for outdated packages
- **Critical findings**: Known CVEs with active exploits
- Check for: unpinned versions, deprecated packages, multiple lock files

### 3. SAST Scanner (OWASP Top 10)
- Run: `scanners/sast-scanner.ps1 -ProjectPath <path>`
- Manually review raw queries, template rendering, file operations
- **Critical findings**: SQLi, Command Injection, Insecure Deserialization
- Check for: SQL injection (string interpolation in queries), XSS (unsafe innerHTML, dangerouslySetInnerHTML, v-html), Command Injection (exec, shell_exec, system, eval), Path Traversal (include/require with user input), CSRF (missing tokens), Insecure Deserialization (pickle, unserialize)

### 4. Infrastructure Scanner
- Run: `scanners/infra-scanner.ps1 -ProjectPath <path>`
- Manually review Dockerfiles, nginx/Apache configs, .env files
- **Critical findings**: Wildcard CORS, exposed debug endpoints, root containers
- Check for: Dockerfile best practices, CORS misconfiguration, security headers (HSTS, CSP, X-Frame-Options), debug mode enabled, exposed admin endpoints

### 5. Database Scanner
- Run: `scanners/db-scanner.ps1 -ProjectPath <path>`
- Manually review SQL files, ORM usage, migration scripts
- **Critical findings**: DROP TABLE/DATABASE in production code, SQL injection in raw queries
- Check for: Hardcoded DB credentials, unsafe SQL operations (DROP, TRUNCATE), exposed DB ports, unsafe migrations without rollback

### 6. CI/CD Scanner
- Run: `scanners/cicd-scanner.ps1 -ProjectPath <path>`
- Manually review workflow files for security
- **Critical findings**: Hardcoded secrets in pipeline YAML
- Check for: Hardcoded secrets in workflows, unpinned action versions (@main/@master), pull_request_target without review, missing review requirements, Docker Compose with plaintext env vars

### Invocation Flow In Code

## Orchestration (Invocation)

When invoked, you MUST:

1. **Detect project**: Identify language, framework, package manager, infra files
2. **Subagent dispatch (parallel)**: Dispatch one subagent per category using `task` tool
3. **Each subagent receives**:
   - The project path
   - The category name and scanner script path
   - Specific rules for manual inspection in that category (from sections above)
   - Expected output format
4. **Merge results** into unified JSON report
5. **Calculate severity summary**
6. **Report findings** to user with remediation

### Subagent Dispatch Template

```
Task(
  description="Security audit: <category>",
  prompt="You are auditing <category> for <project_path>.
  
  1. Run the scanner: `scanners/<scanner>.ps1 -ProjectPath <project_path>`
  2. Parse JSON output, add context
  3. Do MANUAL inspection of relevant files for this category
  4. Combine automated + manual findings
  5. Return JSON array of findings with: id, severity, category, file, finding, remediation, code_snippet
  
  Use severity: critical/high/medium/low",
  subagent_type="general"
)
```

## Severity Matrix

| Level | Criteria | Required Action |
|-------|----------|-----------------|
| 🔴 Critical | Credentials exposed, RCE, SQLi, auth bypass, known CVE exploit | Block deployment MUST fix |
| 🟡 High | Hardcoded secrets (low risk), misconfig, outdated deps with CVEs | Fix before merge |
| 🟠 Medium | Missing security headers, weak CSP, info disclosure | Schedule fix |
| 🟢 Low | Best practices, missing .gitignore entries, verbose errors | Note for improvement |

## Remediation Playbooks

### Secrets Exposed (Critical)
1. Revoke the exposed key/token immediately (AWS console, GitHub, Stripe dashboard, etc.)
2. Remove secret from git history: `git filter-repo` or BFG Repo-Cleaner
3. Rotate to new key
4. Add to .gitignore and use env vars

### SQL Injection (Critical)
1. Replace string interpolation with parameterized queries / prepared statements
2. Use ORM query builders instead of raw SQL
3. Add input validation and sanitization
4. Test with: `' OR 1=1 --`

### XSS (High)
1. Replace innerHTML with textContent or innerText
2. Use DOMPurify to sanitize HTML if HTML is needed
3. Add Content-Security-Policy header
4. Escape all user-controlled output

### Command Injection (Critical)
1. Replace exec/system/shell_exec with language-native APIs
2. If exec required: validate input against allowlist, escape shell args
3. Never pass user input directly to shell commands

### CORS Misconfiguration (High)
1. Never use `Access-Control-Allow-Origin: *` with credentials
2. Restrict to specific origins
3. Validate Origin header server-side

### Insecure CI/CD (Critical)
1. Remove hardcoded secrets from workflow files
2. Add to GitHub Secrets / environment variables
3. Pin actions to commit SHA
4. Enable branch protection with required reviews

## Verification Gate

This agent MUST complete ALL of the following before reporting completion:

- [ ] Run all 6 scanner scripts
- [ ] Dispatch subagents for manual inspection of each category
- [ ] Merge results into unified report
- [ ] Classify each finding by severity
- [ ] Flag if any CRITICAL findings exist (do NOT mark complete)
- [ ] Provide executive summary with pass/fail per category

## Report Format

Return results in this structure:

```json
{
  "project": "<name>",
  "scan_date": "<date>",
  "summary": {
    "critical": N,
    "high": N,
    "medium": N,
    "low": N,
    "passed_categories": ["secrets", "deps", ...],
    "failed_categories": ["sast", ...]
  },
  "findings": [
    {
      "id": "SEC-001",
      "severity": "critical",
      "category": "secrets",
      "file": "path/to/file:line",
      "finding": "Description",
      "remediation": "Steps to fix",
      "code_snippet": "relevant code"
    }
  ],
  "executive_summary": "X critical, Y high findings. Fix before deployment."
}
```

## Integration with finishing-a-development-branch

When loaded via finishing-a-development-branch, the security-auditor MUST run automatically before marking work as complete. If critical findings exist, the agent MUST block completion and report findings.

## Tools

- `scanners/*.ps1` — automated scanner scripts
- `bash` — to run scanner scripts and security tools (npm audit, etc.)
- `task` — to dispatch subagents per category in parallel
- `grep`/`glob` — file inspection for manual review
- `read` — review config files, source code

## Skill Behavior Constraints

1. NEVER skip a category — ALL 6 MUST run
2. NEVER downplay severity — if unsure, use higher severity
3. NEVER mark complete if critical findings exist
4. ALWAYS provide remediation steps per finding
5. ALWAYS use the JSON report format
```

- [ ] **Step 2: Verify the directory structure**

Run:
```powershell
Get-ChildItem -LiteralPath "$env:USERPROFILE\.config\opencode\skills\security-auditor" -Recurse -File
```
Expected: SKILL.md + 6 scanner .ps1 files.

- [ ] **Step 3: Commit**

```bash
git -C "$env:USERPROFILE\.config\opencode" add "skills/security-auditor/SKILL.md"
git -C "$env:USERPROFILE\.config\opencode" commit -m "feat: add main SKILL.md orchestrator for security auditor"
```

---

### Task 8: Verification — test skill with sample project

**Files:**
- Run: scanner scripts and manual review

- [ ] **Step 1: Create test project with intentional vulnerabilities**

Create a temporary project with security issues for testing:

```powershell
$testDir = "$env:TEMP\security-audit-test"
Remove-Item -LiteralPath $testDir -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $testDir -Force | Out-Null

# Real AWS key format for detection testing
"const AWS_KEY = 'AKIA1234567890ABCD';" | Out-File -LiteralPath "$testDir\config.js"
# Private key format
"-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEA..." | Out-File -LiteralPath "$testDir\id_rsa"
# SQLi
"db.query('SELECT * FROM users WHERE id = ' + userId);" | Out-File -LiteralPath "$testDir\users.php"
# XSS
"element.innerHTML = userInput;" | Out-File -LiteralPath "$testDir\app.js"
# .env with debug on
"APP_DEBUG=true
DB_PASSWORD=supersecret" | Out-File -LiteralPath "$testDir\.env"
# package.json with known vulnerability pattern (left as exercise)
@"
{
  "name": "test-app",
  "dependencies": { "express": "^4.17.1" }
}
"@ | Out-File -LiteralPath "$testDir\package.json"
```

- [ ] **Step 2: Run each scanner and verify findings**

Run:
```powershell
Write-Host "=== SECRETS SCANNER ==="
& "$env:USERPROFILE\.config\opencode\skills\security-auditor\scanners\secrets-scanner.ps1" -ProjectPath $testDir | ConvertFrom-Json | Format-Table id, severity, finding

Write-Host "=== SAST SCANNER ==="
& "$env:USERPROFILE\.config\opencode\skills\security-auditor\scanners\sast-scanner.ps1" -ProjectPath $testDir | ConvertFrom-Json | Format-Table id, severity, finding

Write-Host "=== INFRA SCANNER ==="
& "$env:USERPROFILE\.config\opencode\skills\security-auditor\scanners\infra-scanner.ps1" -ProjectPath $testDir | ConvertFrom-Json | Format-Table id, severity, finding

Write-Host "=== DB SCANNER ==="
& "$env:USERPROFILE\.config\opencode\skills\security-auditor\scanners\db-scanner.ps1" -ProjectPath $testDir | ConvertFrom-Json | Format-Table id, severity, finding

Write-Host "=== CI/CD SCANNER ==="
& "$env:USERPROFILE\.config\opencode\skills\security-auditor\scanners\cicd-scanner.ps1" -ProjectPath $testDir | ConvertFrom-Json | Format-Table id, severity, finding
```

Expected: Each scanner returns findings. Secrets finds AWS key + private key + .env. SAST finds SQLi + XSS. Infra finds debug mode. DB finds password. CI/CD reports no workflows.

- [ ] **Step 3: Clean up test project**

```powershell
Remove-Item -LiteralPath $testDir -Recurse -Force -ErrorAction SilentlyContinue
```

- [ ] **Step 4: Final commit with all changes**

```bash
git -C "$env:USERPROFILE\.config\opencode" add -A
git -C "$env:USERPROFILE\.config\opencode" commit -m "chore: complete security auditor skill implementation"
```

---

## Self-Review Checklist

- [ ] All 6 scanner scripts created and verified
- [ ] SKILL.md covers orchestration, all categories, severity matrix, remediation, verification gate
- [ ] Subagent dispatch template in SKILL.md for parallel execution
- [ ] JSON report format defined in SKILL.md
- [ ] Integration with finishing-a-development-branch noted
- [ ] All scanner scripts accept `-ProjectPath` parameter and output JSON
- [ ] Scanner scripts exclude node_modules, vendor, .git etc.
- [ ] Severity levels map correctly to required actions
- [ ] No placeholder code or TODOs remain
