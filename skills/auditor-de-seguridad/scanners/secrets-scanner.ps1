param(
    [Parameter(Mandatory=$true)]
    [string]$ProjectPath
)

$maxFileSize = 5MB
$textExtensions = @('.ps1', '.py', '.js', '.ts', '.jsx', '.tsx', '.php', '.rb', '.go', '.rs', '.java', '.cs', '.cpp', '.h', '.c', '.swift', '.kt', '.scala', '.sh', '.bash', '.zsh', '.ps1', '.yml', '.yaml', '.json', '.xml', '.config', '.env', '.env.*', '.ini', '.cfg', '.conf', '.htaccess', '.dockerfile', '.md', '.txt', '.csv', '.sql', '.rb', '.lock', '.toml', '.gradle', '.tf', '.hcl', '.vue', '.svelte', '.astro', '.mjs', '.cjs', '.mts', '.cts')

$patterns = @(
    @{ pattern = 'AKIA[0-9A-Z]{16}'; severity = 'critical'; name = 'AWS Access Key' }
    @{ pattern = '-----BEGIN.*PRIVATE KEY-----'; severity = 'critical'; name = 'Private Key' }
    @{ pattern = 'sk_live_[0-9a-zA-Z]{24,}'; severity = 'critical'; name = 'Stripe Live Key' }
    @{ pattern = 'sk_test_[0-9a-zA-Z]{24,}'; severity = 'high'; name = 'Stripe Test Key' }
    @{ pattern = 'ghp_[0-9a-zA-Z]{36}'; severity = 'critical'; name = 'GitHub PAT' }
    @{ pattern = 'gho_[0-9a-zA-Z]{36}'; severity = 'critical'; name = 'GitHub OAuth' }
    @{ pattern = 'xox[bpsa]-[0-9a-zA-Z\-]{10,}'; severity = 'high'; name = 'Slack Token' }
    @{ pattern = 'SG\.[0-9a-zA-Z\-_]{22}\.[0-9a-zA-Z\-_]{43}'; severity = 'critical'; name = 'SendGrid Key' }
    @{ pattern = 'password\s*[:=]\s*["''][^"'']+["'']'; severity = 'high'; name = 'Hardcoded Password' }
    @{ pattern = 'secret\s*[:=]\s*["''][^"'']+["'']'; severity = 'high'; name = 'Hardcoded Secret' }
    @{ pattern = 'connection[_ ]?string\s*[:=]\s*["''][^"'']+["'']'; severity = 'high'; name = 'Connection String' }
)

$excludeDirNames = @('node_modules', 'vendor', '.git', 'venv', '__pycache__', '.next', 'build', 'dist', '.nuget', '.idea', '.vscode')

$envPatterns = @('.env', '.env.example', '.env.local', '.env.production', '.env.development', '.env.staging')

function IsTextFile($path) {
    $ext = [System.IO.Path]::GetExtension($path).ToLower()
    $name = [System.IO.Path]::GetFileName($path).ToLower()
    if ($name -in $envPatterns -or $name -like '.env.*') { return $true }
    if ($ext -in $textExtensions) { return $true }
    return $false
}

function ShouldExcludeDir($dirPath) {
    $parts = $dirPath -split '[\\/]'
    foreach ($part in $parts) {
        if ($part -in $excludeDirNames) { return $true }
    }
    return $false
}

function IsBinaryContent($content) {
    return $content -match "`0"
}

$findings = New-Object System.Collections.Generic.List[hashtable]

Get-ChildItem -Path $ProjectPath -File -Recurse -ErrorAction SilentlyContinue | Where-Object {
    $_.Length -le $maxFileSize -and (IsTextFile $_.FullName) -and -not (ShouldExcludeDir $_.DirectoryName)
} | ForEach-Object {
    $content = Get-Content -LiteralPath $_.FullName -Raw -ErrorAction SilentlyContinue
    if (-not $content -or (IsBinaryContent $content)) { return }
    foreach ($p in $patterns) {
        $matches = [regex]::Matches($content, $p.pattern)
        foreach ($m in $matches) {
            $line = ($content.Substring(0, $m.Index) -split "`n").Count
            $contextStart = [Math]::Max(0, $m.Index - 40)
            $contextLen = [Math]::Min(80, $content.Length - $contextStart)
            $snippet = $content.Substring($contextStart, $contextLen) -replace "`n", " "
            $findings.Add(@{
                id = "SEC-$(($findings.Count + 1).ToString('D3'))"
                severity = $p.severity
                category = "secrets"
                file = "$($_.FullName):$line"
                finding = "$($p.name) detected"
                remediation = "Move to environment variable or secrets manager (e.g. .env file, GitHub Secrets, AWS Secrets Manager)"
                code_snippet = $snippet.Trim()
            })
        }
    }
}

$envFiles = Get-ChildItem -Path $ProjectPath -Filter ".env*" -File -ErrorAction SilentlyContinue | Where-Object { -not (ShouldExcludeDir $_.DirectoryName) -and $_.Name -ne ".env.example" -and $_.Name -ne ".env.template" }
foreach ($f in $envFiles) {
    $findings.Add(@{
        id = "SEC-$(($findings.Count + 1).ToString('D3'))"
        severity = "high"
        category = "secrets"
        file = $f.FullName
        finding = ".env file found in repository"
        remediation = "Add .env* to .gitignore and use .env.example for documentation"
        code_snippet = ""
    })
}

$gitignore = Get-ChildItem -Path $ProjectPath -Filter ".gitignore" -File -ErrorAction SilentlyContinue | Select-Object -First 1
if ($gitignore) {
    $gitcontent = Get-Content -LiteralPath $gitignore.FullName -Raw -ErrorAction SilentlyContinue
    if ($gitcontent -notmatch '\.env') {
        $findings.Add(@{
            id = "SEC-$(($findings.Count + 1).ToString('D3'))"
            severity = "medium"
            category = "secrets"
            file = $gitignore.FullName
            finding = ".gitignore does not contain .env entries"
            remediation = "Add `.env*` and `.env.local` to .gitignore"
            code_snippet = ""
        })
    }
}

return $findings | ConvertTo-Json -Depth 3
