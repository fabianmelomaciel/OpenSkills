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
    foreach ($skill in $skillDirs) {
        $destPath = Join-Path -Path "$target\skills" -ChildPath $skill.Name
        Write-Host "  Copiando: $($skill.Name)..." -ForegroundColor Gray
        Remove-Item -LiteralPath $destPath -Recurse -Force -ErrorAction SilentlyContinue
        Copy-Item -LiteralPath $skill.FullName -Destination $destPath -Recurse -Force
    }
    Copy-Item -LiteralPath "$source\install.ps1" -Destination "$target\" -Force -ErrorAction SilentlyContinue
    Copy-Item -LiteralPath "$source\install.sh" -Destination "$target\" -Force -ErrorAction SilentlyContinue
    Copy-Item -LiteralPath "$source\README.md" -Destination "$target\" -Force -ErrorAction SilentlyContinue
    Copy-Item -LiteralPath "$source\package.json" -Destination "$target\" -Force -ErrorAction SilentlyContinue
    Copy-Item -LiteralPath "$source\.gitignore" -Destination "$target\" -Force -ErrorAction SilentlyContinue
    
    # Copiar CODEX.md si no existe para preservar memoria acumulada
    $codexSrc = Join-Path -Path $source -ChildPath "CODEX.md"
    $codexDest = Join-Path -Path $target -ChildPath "CODEX.md"
    if (Test-Path -LiteralPath $codexSrc) {
        if (-not (Test-Path -LiteralPath $codexDest)) {
            Copy-Item -Path $codexSrc -Destination $codexDest -Force
            Write-Host "  CODEX.md instalado por primera vez." -ForegroundColor Gray
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

    if (Test-Path -LiteralPath "$env:USERPROFILE\.config\opencode") {
        $detected += @{ Name = "opencode"; Path = $opencodeDir }
    }
    if (Test-Path -LiteralPath "$env:USERPROFILE\.config\antigravity") {
        $detected += @{ Name = "antigravity"; Path = $antigravityDir }
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
