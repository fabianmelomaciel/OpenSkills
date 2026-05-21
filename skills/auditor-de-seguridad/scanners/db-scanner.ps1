param(
    [Parameter(Mandatory=$true)]
    [string]$ProjectPath
)

$findings = @()
$excludeDirs = @('node_modules', 'vendor', '.git', 'venv', '__pycache__', 'bin', 'obj', '.next', 'build', 'dist')

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

    if ($_.Extension -in '.sql', '.php', '.py', '.js') {
        if ($content -match '\bDROP\s+(TABLE|DATABASE)\b' -and $content -notmatch '--\s*(skip|comment)') {
            $findings += @{
                id = "DB-002"; severity = "critical"; category = "database"
                file = $_.FullName
                finding = "Destructive SQL operation (DROP TABLE/DATABASE) detected"
                remediation = "Never use DROP in production migrations. Use soft deletes instead"
                code_snippet = ""
            }
        }
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

    if ($content -match '\b3306\b' -or $content -match '\b5432\b' -or $content -match '\b27017\b' -or $content -match '\b6379\b') {
        $findings += @{
            id = "DB-004"; severity = "low"; category = "database"
            file = $_.FullName
            finding = "Database port number detected in config (3306/5432/27017/6379)"
            remediation = "Ensure database ports are not exposed publicly, restrict to internal network"
            code_snippet = ""
        }
    }
}

$sqlFiles = Get-ChildItem -Path $ProjectPath -Filter "*.sql" -File -Recurse -ErrorAction SilentlyContinue |
    Where-Object { $_.DirectoryName -notmatch 'node_modules|vendor' }
if ($sqlFiles.Count -gt 10) {
    $findings += @{
        id = "DB-005"; severity = "low"; category = "database"
        file = "$(($sqlFiles | Select-Object -First 1).DirectoryName)"
        finding = "Large number of SQL files ($($sqlFiles.Count)) - review for unsafe operations"
        remediation = "Use structured migrations with rollback support"
        code_snippet = ""
    }
}

return $findings | ConvertTo-Json -Depth 3

