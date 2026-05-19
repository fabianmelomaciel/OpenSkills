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
            finding = "Dockerfile uses :latest tag (unpredictable builds)"
            remediation = "Pin to specific version tags like :18.04 or digest SHA"
            code_snippet = ""
        }
    }
    if ($content -match 'USER\s+root') {
        $findings += @{
            id = "INF-002"; severity = "medium"; category = "infrastructure"
            file = $df.FullName
            finding = "Docker container runs as root"
            remediation = "Add USER nobody or create a non-root user"
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

$corsFiles = Get-ChildItem -Path $ProjectPath -Include "*.php", "*.py", "*.js", "*.ts", "*.json", "*.yaml", "*.yml" -File -Recurse -ErrorAction SilentlyContinue |
    Where-Object { $_.DirectoryName -notmatch 'node_modules|vendor|venv' }
foreach ($cf in $corsFiles) {
    $content = Get-Content -LiteralPath $cf.FullName -Raw -ErrorAction SilentlyContinue
    if (-not $content) { continue }
    if ($content -match 'Access-Control-Allow-Origin\s*[:=]\s*["'']\*["'']') {
        $findings += @{
            id = "INF-004"; severity = "high"; category = "infrastructure"
            file = $cf.FullName
            finding = "Wildcard CORS origin (*) detected"
            remediation = "Restrict Access-Control-Allow-Origin to specific origins"
            code_snippet = ""
        }
        break
    }
}

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

# Check that .htaccess blocks .env access if .env is present
if ($envFiles) {
    $htaccessFiles = Get-ChildItem -Path $ProjectPath -Filter ".htaccess" -File -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.DirectoryName -notmatch 'node_modules|vendor|venv' }
    if ($htaccessFiles) {
        foreach ($ht in $htaccessFiles) {
            $htContent = Get-Content -LiteralPath $ht.FullName -Raw -ErrorAction SilentlyContinue
            if ($htContent) {
                $hasComment = $htContent -match '#\s*Bloquear\s+\.env\s+via\s+rewrite'
                $hasRule = $htContent -match 'RewriteRule\s+\^\\\.env\s+-\s+\[F,L\]'
                if (-not ($hasComment -and $hasRule)) {
                    $findings += @{
                        id = "INF-009"; severity = "high"; category = "infrastructure"
                        file = $ht.FullName
                        finding = ".htaccess does not protect .env file with rewrite block rules"
                        remediation = "Add the following rules to the top of your .htaccess file:`n# Bloquear .env via rewrite`nRewriteRule ^\.env - [F,L]"
                        code_snippet = ""
                    }
                }
            }
        }
    } else {
        # Check if project contains php files, indicating apache might be used
        $hasPhp = Get-ChildItem -Path $ProjectPath -Filter "*.php" -File -Recurse -ErrorAction SilentlyContinue |
            Where-Object { $_.DirectoryName -notmatch 'node_modules|vendor|venv' } | Select-Object -First 1
        if ($hasPhp) {
            $findings += @{
                id = "INF-010"; severity = "high"; category = "infrastructure"
                file = $ProjectPath
                finding = ".env file exists but no .htaccess file was found in a PHP project"
                remediation = "Create a .htaccess file in the web root containing:`n# Bloquear .env via rewrite`nRewriteRule ^\.env - [F,L]"
                code_snippet = ""
            }
        }
    }
}

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
                finding = "Debug endpoint or tool detected ($dp)"
                remediation = "Remove debug routes and tools before production deployment"
                code_snippet = ""
            }
            break
        }
    }
}

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
