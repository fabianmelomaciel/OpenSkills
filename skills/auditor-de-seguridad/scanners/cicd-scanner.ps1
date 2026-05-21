param(
    [Parameter(Mandatory=$true)]
    [string]$ProjectPath
)

$findings = @()

$ghaFiles = Get-ChildItem -Path $ProjectPath -Filter "*.yml" -Recurse -ErrorAction SilentlyContinue |
    Where-Object { $_.DirectoryName -match '\.github[\\/]workflows' -and $_.DirectoryName -notmatch 'node_modules|vendor' }
if ($ghaFiles.Count -eq 0) {
    $ghaFiles = Get-ChildItem -Path $ProjectPath -Filter "*.yaml" -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.DirectoryName -match '\.github[\\/]workflows' -and $_.DirectoryName -notmatch 'node_modules|vendor' }
}

if ($ghaFiles.Count -gt 0) {
    foreach ($gf in $ghaFiles) {
        $content = Get-Content -LiteralPath $gf.FullName -Raw -ErrorAction SilentlyContinue
        if (-not $content) { continue }
        if ($content -match 'password=|secret=|api_key=|token=') {
            $findings += @{
                id = "CICD-001"; severity = "critical"; category = "cicd"
                file = $gf.FullName
                finding = "Potential hardcoded secret in CI/CD workflow"
                remediation = "Use GitHub Secrets (secrets.*) instead of hardcoding values"
                code_snippet = ""
            }
        }
        if ($content -match 'uses:\s+\S+@main' -or $content -match 'uses:\s+\S+@master') {
            $findings += @{
                id = "CICD-002"; severity = "high"; category = "cicd"
                file = $gf.FullName
                finding = "CI/CD action pinned to @main or @master (unstable)"
                remediation = "Pin actions to specific commit SHA or semver tag"
                code_snippet = ""
            }
        }
        if ($content -match 'pull_request_target') {
            $findings += @{
                id = "CICD-003"; severity = "high"; category = "cicd"
                file = $gf.FullName
                finding = "pull_request_target trigger used (privileged execution)"
                remediation = "Ensure pull_request_target workflows have proper review gates"
                code_snippet = ""
            }
        }
        if ($content -match 'actions/checkout@' -and $content -notmatch 'ref:|\$') {
            $findings += @{
                id = "CICD-004"; severity = "low"; category = "cicd"
                file = $gf.FullName
                finding = "Git checkout without explicit ref (may use untrusted code)"
                remediation = "Specify ref for PR triggers"
                code_snippet = ""
            }
        }
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
