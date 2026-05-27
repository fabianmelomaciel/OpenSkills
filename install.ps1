param(
    [string]$TargetDir = "",
    [switch]$Help
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$skillsDir = Join-Path -Path $scriptDir -ChildPath "skills"

function InstallToDir($target, $source) {
    if (-not $source) { $source = $scriptDir }
    Write-Host "`nInstalando OpenSkills en: $target" -ForegroundColor Cyan
    New-Item -ItemType Directory -Path $target -Force | Out-Null
    $skillDirs = Get-ChildItem -LiteralPath "$source\skills" -Directory
    $isClaude = $target.EndsWith(".claude\skills") -or $target.EndsWith(".claude/skills")
    foreach ($skill in $skillDirs) {
        if ($isClaude) {
            $destPath = Join-Path -Path $target -ChildPath $skill.Name
        } else {
            $destPath = Join-Path -Path "$target\skills" -ChildPath $skill.Name
        }
        Write-Host "  Copiando: $($skill.Name)..." -ForegroundColor Gray
        Remove-Item -LiteralPath $destPath -Recurse -Force -ErrorAction SilentlyContinue
        Copy-Item -LiteralPath $skill.FullName -Destination $destPath -Recurse -Force
    }
    if (-not $isClaude) {
        Copy-Item -LiteralPath "$source\install.ps1" -Destination "$target\" -Force -ErrorAction SilentlyContinue
        Copy-Item -LiteralPath "$source\install.sh" -Destination "$target\" -Force -ErrorAction SilentlyContinue
        Copy-Item -LiteralPath "$source\README.md" -Destination "$target\" -Force -ErrorAction SilentlyContinue
        Copy-Item -LiteralPath "$source\package.json" -Destination "$target\" -Force -ErrorAction SilentlyContinue
        Copy-Item -LiteralPath "$source\.gitignore" -Destination "$target\" -Force -ErrorAction SilentlyContinue
    
    # Generar CODEX.md si no existe en destino (es local-only, no está en el repo)
    $codexDest = Join-Path -Path $target -ChildPath "CODEX.md"
    if (-not (Test-Path -LiteralPath $codexDest)) {
        $codexTemplate = @"
# 🧠 OpenSkills: Tactical CODEX (Learning Memory)

This document is the shared, dynamically evolving persistent memory of the OpenSkills agent squad. It prevents re-explaining context, repeating solved problems, and wasting tokens on re-discovery.

> [!IMPORTANT]
> **AGENT DIRECTIVE:** Read this file at the START of every task. Apply all entries. Do NOT ask the user to re-explain anything documented here. Write back learnings after completing tasks.

> [!NOTE]
> This file is **local-only** and listed in .gitignore. Your instance is yours — fill it with your project's truths.

## 🎯 Project Context Quick Reference

- **Project Name**: [e.g. Festday — PHP SaaS for event ticketing]
- **Primary Language & Framework**: [e.g. PHP 8.2 / Custom MVC + Vue 3 frontend]
- **Local Server**: [e.g. Laragon — Apache 2.4, MySQL 8, port 80]
- **Package Manager(s)**: [e.g. Composer 2.x + npm 10]
- **Key Directories**: [e.g. /src = app, /public = web root]
- **Database**: [e.g. MySQL 8 @ 127.0.0.1:3306]
- **Deployment**: [e.g. cPanel shared hosting via git.php webhook]
- **Design System**: [e.g. Custom CSS with --color-primary HSL]

## 💡 Token Economy Rules

1. Read CODEX first — never ask the user to re-explain documented context.
2. Compact output — prefer tables and bullets over narrative prose.
3. No preamble — skip openers, start doing.
4. Reference don't repeat — cite past Mission Logs by date instead of re-explaining.
5. Minimal clarifying questions — check files before asking.
6. Immediate Code Verification (Verify-As-You-Go) — Never assume a code edit works. Immediately run syntax, compile, linter, or test commands after every single modification.
7. Dynamic Context Learning — Write new findings (gotchas, environment/config quirks) to CODEX.md under Technical Gotchas or Mission Logs immediately after resolving them.

## 🏗️ Active Design System

- **Primary Font**: [e.g. Inter via Google Fonts]
- **Color Palette**: [e.g. HSL dark mode: bg hsl(224,14%,10%)]
- **Border Radius Scale**: [e.g. 4/8/12/16px]
- **Animation Standard**: [e.g. 150ms cubic-bezier(0.16,1,0.3,1)]

## 🛠️ Technical Gotchas & Environment Lessons

- Deployment scripts must never be web-accessible. Block in .htaccess. Classify as CRITICAL in audits.
- .env files must always be in .gitignore. In Apache: RewriteRule ^\.env - [F,L] in .htaccess.
- OpenSkills path (Windows Antigravity): %USERPROFILE%\.gemini\config\skills

## 💻 Mission Logs & Tactical Learnings

- [YYYY-MM-DD] - (Short title) — (What happened, root cause, fix, what to do differently next time.)
"@
        $codexTemplate | Out-File -FilePath $codexDest -Encoding utf8 -Force
        Write-Host "  CODEX.md generado por primera vez (local-only)." -ForegroundColor Gray
    } else {
        Write-Host "  CODEX.md ya existe localmente (memoria de aprendizaje conservada)." -ForegroundColor Yellow
    }
    }
    Write-Host "  Listo: $($skillDirs.Count) skills instaladas" -ForegroundColor Green
}

function InstallToOpendir($source) {
    $targetCore = "$env:USERPROFILE\.config\opencode\skills"
    Write-Host "`nInstalando skills directamente en opencode skills/..." -ForegroundColor Cyan
    $skillDirs = Get-ChildItem -LiteralPath "$source\skills" -Directory
    foreach ($skill in $skillDirs) {
        $destPath = Join-Path -Path $targetCore -ChildPath $skill.Name
        Remove-Item -LiteralPath $destPath -Recurse -Force -ErrorAction SilentlyContinue
        Copy-Item -LiteralPath $skill.FullName -Destination $destPath -Recurse -Force
        Write-Host "  Instalado: $($skill.Name)" -ForegroundColor Gray
    }
    Write-Host "  $($skillDirs.Count) skills instaladas en opencode" -ForegroundColor Green
}

function Check-Dependencies {
    Write-Host "`n=== DIAGNOSTICO DE DEPENDENCIAS ===" -ForegroundColor Cyan
    $dependencies = @(
        @{ Name = "git"; Command = "git --version"; Severity = "high"; Desc = "Control de versiones" }
        @{ Name = "node"; Command = "node --version"; Severity = "medium"; Desc = "Multiplataforma y auditoria JS" }
        @{ Name = "npm"; Command = "npm --version"; Severity = "medium"; Desc = "Gestor de paquetes JS" }
        @{ Name = "composer"; Command = "composer --version"; Severity = "medium"; Desc = "Gestor de paquetes PHP" }
        @{ Name = "python"; Command = "python --version"; Severity = "low"; Desc = "Auditoria Python" }
        @{ Name = "pip-audit"; Command = "pip-audit --version"; Severity = "medium"; Desc = "Escaneo de seguridad Python" }
    )
    foreach ($dep in $dependencies) {
        $status = "OK"
        $color = "Green"
        $check = Get-Command $dep.Name -ErrorAction SilentlyContinue
        if (-not $check) {
            $status = "FALTA (Recomendado)"
            $color = "Yellow"
            if ($dep.Severity -eq "high") {
                $status = "FALTA (Critico)"
                $color = "Red"
            }
            Write-Host "  [-] $($dep.Name) ($($dep.Desc)): $status" -ForegroundColor $color
            
            if ($dep.Name -eq "pip-audit" -and (Get-Command "pip" -ErrorAction SilentlyContinue)) {
                $response = Read-Host "      ¿Deseas instalar 'pip-audit' automaticamente ahora via pip? [S/N]"
                if ($response -eq 'S' -or $response -eq 's') {
                    Write-Host "      Instalando pip-audit..." -ForegroundColor Cyan
                    & pip install pip-audit
                }
            }
        } else {
            Write-Host "  [+] $($dep.Name) ($($dep.Desc)): Instalado" -ForegroundColor $color
        }
    }
    Write-Host ""
}

if ($Help) {
    Write-Host @"
OpenSkills Installer
====================
Instala skills de OpenSkills en opencode o antigravity.

USO:
  .\install.ps1                              - Detecta e instala automaticamente
  .\install.ps1 -TargetDir "C:\ruta"          - Instala en ruta personalizada
  .\install.ps1 -Help                         - Muestra esta ayuda

SIN PARAMETROS: Detecta opencode o antigravity y instala alli.
"@ -ForegroundColor Cyan
    exit 0
}

if (-not (Test-Path -LiteralPath $skillsDir)) {
    Write-Host "ERROR: No se encuentra el directorio skills/ en $scriptDir" -ForegroundColor Red
    exit 1
}

Check-Dependencies

if (-not $TargetDir) {
    $detected = @()
    $opencodeDir = "$env:USERPROFILE\.config\opencode\openskills"
    $antigravityDir = "$env:USERPROFILE\.config\antigravity\openskills"
    $antigravityGeminiDir = "$env:USERPROFILE\.gemini\config\openskills"

    if (Test-Path -LiteralPath "$env:USERPROFILE\.config\opencode") {
        $detected += @{ Name = "opencode"; Path = $opencodeDir }
    }
    if (Test-Path -LiteralPath "$env:USERPROFILE\.config\antigravity") {
        $detected += @{ Name = "antigravity"; Path = $antigravityDir }
    }
    if (Test-Path -LiteralPath "$env:USERPROFILE\.gemini\config") {
        $detected += @{ Name = "antigravity (gemini)"; Path = $antigravityGeminiDir }
    }
    if (Test-Path -LiteralPath "$env:USERPROFILE\.claude") {
        $detected += @{ Name = "claude-code"; Path = "$env:USERPROFILE\.claude\skills" }
    }

    if ($detected.Count -eq 0) {
        Write-Host "No se detecto opencode ni antigravity. Usando: $env:USERPROFILE\.openskills" -ForegroundColor Yellow
        $TargetDir = "$env:USERPROFILE\.openskills"
    } elseif ($detected.Count -eq 1) {
        $TargetDir = $detected[0].Path
        Write-Host "Detectado: $($detected[0].Name) -> $TargetDir" -ForegroundColor Green
    } else {
        Write-Host "Detectados opencode y antigravity. Instalando en ambos..." -ForegroundColor Green
        foreach ($d in $detected) { InstallToDir $d.Path $scriptDir }
        InstallToOpendir $scriptDir
        Write-Host "`nInstalacion completa en ambos!" -ForegroundColor Green
        return
    }
}

InstallToDir $TargetDir $scriptDir
