<#
.SYNOPSIS
    Convierte un reporte JSON de auditoría de seguridad en un dashboard HTML premium.

.DESCRIPTION
    Toma el archivo JSON generado por el auditor-de-seguridad y lo transforma en un
    reporte visual de primer nivel usando el template dark-mode de OpenSkills.
    
    El script escapa correctamente todos los campos HTML para evitar que snippets de
    código PHP o JavaScript rompan el layout de la página.

.PARAMETER JsonPath
    Ruta al archivo .json con los hallazgos de la auditoría (requerido).

.PARAMETER ReportPath
    Ruta de salida del archivo .html. Por defecto usa el mismo nombre que el JSON.

.PARAMETER TemplatePath
    Ruta al template HTML. Por defecto usa el template del skill auditor-de-seguridad.

.EXAMPLE
    .\generate-report-from-json.ps1 -JsonPath C:\laragon\www\festday\security-audit-report.json

.NOTES
    Parte de OpenSkills — https://github.com/fabianmelomaciel/OpenSkills
#>
param(
    [Parameter(Mandatory=$true)]
    [string]$JsonPath,
    [string]$ReportPath = "",
    [string]$TemplatePath = ""
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Resolving paths
if (-not (Test-Path -LiteralPath $JsonPath)) {
    Write-Host "ERROR: El archivo JSON no existe: $JsonPath" -ForegroundColor Red
    exit 1
}
$JsonPath = (Get-Item $JsonPath).FullName
$BaseDir = Split-Path -Parent $JsonPath

if (-not $TemplatePath) {
    $TemplatePath = Join-Path -Path $scriptDir -ChildPath "skills\auditor-de-seguridad\reports\dashboard-template.html"
}
if (-not (Test-Path -LiteralPath $TemplatePath)) {
    Write-Host "ERROR: La plantilla HTML no existe: $TemplatePath" -ForegroundColor Red
    exit 1
}

# Cargar y parsear JSON
Write-Host "Cargando reporte JSON: $JsonPath" -ForegroundColor Cyan
$reportData = Get-Content -LiteralPath $JsonPath -Raw -Encoding utf8 | ConvertFrom-Json

$projectName = $reportData.project
if (-not $projectName) {
    $projectName = Split-Path -Leaf (Split-Path -Parent $JsonPath)
}

$scanDate = $reportData.scan_date
if (-not $scanDate) {
    $scanDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
}

$criticalCount = $reportData.summary.critical
$highCount = $reportData.summary.high
$mediumCount = $reportData.summary.medium
$lowCount = $reportData.summary.low
$execSummary = $reportData.executive_summary

# Determinar ruta del reporte HTML de salida
if (-not $ReportPath) {
    $ReportPath = [System.IO.Path]::ChangeExtension($JsonPath, ".html")
}

Write-Host "Proyecto: $projectName" -ForegroundColor Gray
Write-Host "Fecha: $scanDate" -ForegroundColor Gray
Write-Host "Hallazgos: Critical=$criticalCount, High=$highCount, Medium=$mediumCount, Low=$lowCount" -ForegroundColor Gray

function Escape-Html ($str) {
    if (-not $str) { return "" }
    return $str.ToString().Replace("&", "&amp;").Replace("<", "&lt;").Replace(">", "&gt;").Replace('"', "&quot;").Replace("'", "&#39;")
}

# Cargar plantilla HTML
$template = Get-Content -LiteralPath $TemplatePath -Raw -Encoding utf8

# Reemplazar metadatos y contadores
$template = $template.Replace("{{PROJECT_NAME}}", $projectName)
$template = $template.Replace("{{SCAN_DATE}}", $scanDate)
$template = $template.Replace("{{CRITICAL_COUNT}}", [string]$criticalCount)
$template = $template.Replace("{{HIGH_COUNT}}", [string]$highCount)
$template = $template.Replace("{{MEDIUM_COUNT}}", [string]$mediumCount)
$template = $template.Replace("{{LOW_COUNT}}", [string]$lowCount)
$template = $template.Replace("{{EXECUTIVE_SUMMARY}}", $execSummary)

# Construir HTML de los hallazgos
$findingsHtml = ""
$idIndex = 1

foreach ($f in $reportData.findings) {
    $badgeClass = "badge-low"
    if ($f.severity -eq "critical") { $badgeClass = "badge-critical" }
    elseif ($f.severity -eq "high") { $badgeClass = "badge-high" }
    elseif ($f.severity -eq "medium") { $badgeClass = "badge-medium" }

    $severityText = $f.severity.Substring(0,1).ToUpper() + $f.severity.Substring(1)
    
    # Manejar el snippet de código, que puede ser opcional
    $escapedSnippet = ""
    if ($f.code_snippet) {
        $escapedSnippet = Escape-Html $f.code_snippet
    } elseif ($f.code) {
        $escapedSnippet = Escape-Html $f.code
    }
    
    $codeBlockHtml = ""
    if (-not [string]::IsNullOrWhiteSpace($escapedSnippet)) {
        $codeBlockHtml = '<div class="code-block">' + $escapedSnippet + '</div>'
    }

    # Manejar campos descriptivos y escapar todos los campos HTML
    $escapedFinding = Escape-Html $f.finding
    $escapedFile = Escape-Html $f.file
    
    $fileHref = $f.file
    if ($f.file -match '^(.*):(\d+)$') {
        $fileHref = $Matches[1]
    }
    $absoluteFileHref = $fileHref
    if (-not [string]::IsNullOrEmpty($fileHref) -and -not [System.IO.Path]::IsPathRooted($fileHref)) {
        $absoluteFileHref = Join-Path -Path $BaseDir -ChildPath $fileHref
    }
    $fileUri = $absoluteFileHref.Replace("\", "/")
    if ($fileUri.StartsWith("/")) {
        $fileUri = "file://" + $fileUri
    } else {
        $fileUri = "file:///" + $fileUri
    }
    
    $description = $f.finding
    if ($f.description -and $f.description -ne $f.finding) {
        $description = $f.description
    }
    $escapedDescription = Escape-Html $description

    $escapedRemediation = ""
    if ($f.remediation) {
        $escapedRemediation = (Escape-Html $f.remediation).Replace("`n", "<br>").Replace("\n", "<br>")
    }

    $findingsHtml += @"
        <div class="finding-card" id="card-$idIndex">
            <div class="finding-header" onclick="toggleFinding('$idIndex')">
                <div class="finding-title-group">
                    <span class="badge $badgeClass">$severityText</span>
                    <span class="finding-title">$escapedFinding</span>
                </div>
                <div class="finding-file-group">
                    <svg viewBox="0 0 24 24"><path d="M19 3H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm-5 14H7v-2h7v2zm3-4H7v-2h10v2zm0-4H7V7h10v2z"/></svg>
                    <a href="$fileUri" target="_blank" onclick="event.stopPropagation();">$escapedFile</a>
                </div>
                <div class="chevron">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M6 9l6 6 6-6"/></svg>
                </div>
            </div>
            <div id="content-$idIndex" class="finding-content">
                <div class="finding-details-grid">
                    <div class="info-panel">
                        <h4>Descripción del hallazgo</h4>
                        <p style="color: var(--text-muted);">$escapedDescription</p>
                    </div>
                    <div class="info-panel remediation-panel">
                        <h4>Remediación recomendada</h4>
                        <p style="color: #cbd5e1;">$escapedRemediation</p>
                    </div>
                </div>
                $codeBlockHtml
            </div>
        </div>
"@
    $idIndex++
}

if ($reportData.findings.Count -eq 0) {
    $findingsHtml = @"
        <div class="finding-card" style="padding: 3rem; text-align: center; color: var(--passed); font-weight: bold; font-size: 1.25rem;">
            🎉 ¡Felicidades! No se detectaron vulnerabilidades en el proyecto.
        </div>
"@
}

# Reemplazar marcador de posición
$placeholderPattern = '(?s)<!-- FINDINGS_PLACEHOLDER_START -->.*?<!-- FINDINGS_PLACEHOLDER_END -->'
$template = [regex]::Replace($template, $placeholderPattern, $findingsHtml)

# Escribir el reporte HTML
$template | Out-File -FilePath $ReportPath -Encoding utf8 -Force
Write-Host "Reporte visual premium generado en: $ReportPath" -ForegroundColor Green

# Intentar abrir el reporte en el navegador automáticamente
try {
    Start-Process $ReportPath
} catch {}

$formattedPath = $ReportPath.Replace("\", "/")
if ($formattedPath.StartsWith("/")) {
    $reportUri = "file://" + $formattedPath
} else {
    $reportUri = "file:///" + $formattedPath
}
Write-Host "Ver Reporte de Seguridad HTML en tu navegador: $reportUri`n" -ForegroundColor Green
