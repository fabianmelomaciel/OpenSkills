param(
    [Parameter(Mandatory=$true)]
    [string]$ProjectPath
)

$findings = @()
$excludeDirs = @('node_modules', 'vendor', '.git', 'venv', '__pycache__', 'bin', 'obj', '.next', 'build', 'dist')

$checks = @(
    @{ name = "SQL Injection - raw queries"; severity = "critical"
       patterns = @('execute\s*\(\s*["'']SELECT', 'query\s*\(\s*["'']SELECT', 'raw\s*\(\s*["'']SELECT', '\$this->db->query\("')
       extensions = @('.php', '.py', '.js', '.ts', '.java', '.go', '.rb') }
    @{ name = "SQL Injection - string interpolation"; severity = "critical"
       patterns = @('SELECT.*\+.*\$', 'SELECT.*\{.*\}.*FROM', "SELECT.*[''']\s*\+\s*")
       extensions = @('.php', '.py', '.js', '.ts', '.java', '.rb') }
    @{ name = "SQL Injection - exec with params"; severity = "high"
       patterns = @('exec\s*\(.*\$', 'mysql_query\s*\(.*\$')
       extensions = @('.php', '.py') }
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
    @{ name = "Command Injection - exec/shell"; severity = "critical"
       patterns = @('exec\s*\(', 'shell_exec\s*\(', 'system\s*\(', 'popen\s*\(', 'child_process\.exec\s*\(')
       extensions = @('.php', '.py', '.js', '.ts') }
    @{ name = "Command Injection - eval"; severity = "critical"
       patterns = @('\beval\s*\(', 'assert\s*\(')
       extensions = @('.php', '.py', '.js') }
    @{ name = "Path Traversal - file inclusion"; severity = "high"
       patterns = @('include\s*\(.*\$', 'include_once\s*\(.*\$', 'require\s*\(.*\$', 'require_once\s*\(.*\$')
       extensions = @('.php') }
    @{ name = "Path Traversal - file read"; severity = "high"
       patterns = @('file_get_contents\s*\(.*\$', 'readfile\s*\(.*\$', 'fopen\s*\(.*\$')
       extensions = @('.php') }
    @{ name = "Missing CSRF Protection"; severity = "high"
       patterns = @('@csrf_protection\s*=\s*False', '@csrf_exempt', 'csrf_exempt')
       extensions = @('.py') }
    @{ name = "Missing CSRF token check"; severity = "high"
       patterns = @('VerifyToken\s*\(\)')
       extensions = @('.cs', '.vb') }
    @{ name = "Insecure Deserialization - pickle"; severity = "critical"
       patterns = @('pickle\.loads\s*\(', 'pickle\.load\s*\(')
       extensions = @('.py') }
    @{ name = "Insecure Deserialization - unserialize"; severity = "critical"
       patterns = @('unserialize\s*\(')
       extensions = @('.php') }
    @{ name = "Insecure Deserialization - JSON.parse (unsafe)"; severity = "medium"
       patterns = @('JSON\.parse\s*\(')
       extensions = @('.js', '.ts') }
    @{ name = "AI Remnant - Vibe Coding Placeholder"; severity = "medium"
       patterns = @('(//|#)\s*TODO:\s*implement', '(//|#)\s*Insert\s*logic\s*here', '(//|#)\s*Insert\s*code\s*here', '(//|#)\s*write\s*your\s*code\s*here', 'your-api-key-here', 'your_token_here', 'your-password-here', '\[\s*insert\s*code\s*here\s*\]', '<\s*placeholder\s*>')
       extensions = @('.php', '.py', '.js', '.ts', '.java', '.go', '.rb', '.cs', '.tsx', '.jsx') }
    @{ name = "AI Remnant - Lazy Error Handling"; severity = "low"
       patterns = @('catch\s*\(\s*[^)]*\)\s*\{\s*\}', 'catch\s*\{\s*\}', 'except\b[^:]*:\s*pass')
       extensions = @('.js', '.ts', '.tsx', '.jsx', '.cs', '.java', '.py', '.php') }
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
                        "AI Remnant - Vibe Coding*" { "Replace placeholder with complete, functional implementation code" }
                        "AI Remnant - Lazy Error*" { "Implement proper error handling, logging, or recovery logic" }
                        default { "Review code for security implications" }
                    }
                    code_snippet = $snippet
                }
            }
        }
    }
}

return $findings | ConvertTo-Json -Depth 3
