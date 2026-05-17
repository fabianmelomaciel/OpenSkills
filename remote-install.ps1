# Remote installer for OpenSkills in Windows
$ErrorActionPreference = "Stop"

Write-Host "`n=== OpenSkills Remote Installer ===" -ForegroundColor Cyan

# Check if git is installed
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Error "Git no esta instalado o no se encuentra en el PATH. Por favor instala Git antes de continuar."
    exit 1
}

# Determine destination directory
$targetDir = "$env:USERPROFILE\.config\opencode\openskills"
if (Test-Path -LiteralPath "$env:USERPROFILE\.config\antigravity") {
    $targetDir = "$env:USERPROFILE\.config\antigravity\openskills"
}

Write-Host "Clonando/Actualizando OpenSkills en $targetDir..." -ForegroundColor Cyan

if (Test-Path -LiteralPath $targetDir) {
    Write-Host "El directorio de destino ya existe. Actualizando con git pull..." -ForegroundColor Yellow
    Push-Location $targetDir
    try {
        git pull
    } catch {
        Write-Warning "No se pudo realizar git pull. Intentando continuar..."
    }
    Pop-Location
} else {
    git clone https://github.com/fabianmelomaciel/OpenSkills.git $targetDir
}

# Run the installer
Write-Host "Ejecutando instalador local..." -ForegroundColor Cyan
& "$targetDir\install.ps1"
