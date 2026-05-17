param(
    [Parameter(Mandatory=$true)]
    [string]$ProjectPath
)

$findings = @()
$hasAnyManager = $false
$packageJson = Get-ChildItem -Path $ProjectPath -Filter "package.json" -File -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.DirectoryName -notmatch 'node_modules' }
if ($packageJson) {
    $hasAnyManager = $true
    $packageLock = Get-ChildItem -Path $ProjectPath -Filter "package-lock.json" -File -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $packageLock) {
        $findings += @{
            id = "DEP-001"; severity = "medium"; category = "dependencies"
            file = "$(($packageJson | Select-Object -First 1).FullName)"
            finding = "No package-lock.json found"
            remediation = "Run npm install to generate package-lock.json for reproducible builds"
            code_snippet = ""
        }
    }
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
                    remediation = "Run npm audit fix or update affected packages manually"
                    code_snippet = "Critical: $($vulns.critical), High: $($vulns.high)"
                }
            }
            if ($vulns.high -gt 0) {
                $findings += @{
                    id = "DEP-003"; severity = "high"; category = "dependencies"
                    file = "package.json"
                    finding = "$($vulns.high) high vulnerabilities in npm dependencies"
                    remediation = "Run npm audit fix or update affected packages"
                    code_snippet = "High: $($vulns.high)"
                }
            }
        }
    } catch {}
}
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
                    remediation = "Run composer update for affected packages"
                    code_snippet = ""
                }
            }
        }
    } catch {}
}
$reqFiles = Get-ChildItem -Path $ProjectPath -Filter "requirements*.txt" -File -ErrorAction SilentlyContinue
if ($reqFiles) {
    $hasAnyManager = $true
    $pipAuditAvailable = Get-Command "pip-audit" -ErrorAction SilentlyContinue
    if (-not $pipAuditAvailable) {
        $findings += @{
            id = "DEP-005"; severity = "low"; category = "dependencies"
            file = "requirements.txt"
            finding = "pip-audit not installed - cannot audit Python dependencies"
            remediation = "Run pip install pip-audit then pip-audit"
            code_snippet = ""
        }
    }
}
foreach ($req in $reqFiles) {
    $lines = Get-Content -LiteralPath $req.FullName -ErrorAction SilentlyContinue
    $pinned = ($lines | Where-Object { $_ -match '==' }).Count
    if ($pinned -gt 0) {
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
