#!/bin/bash
# OpenSkills Auditoría de Seguridad - Wrapper de ejecución para Linux/Mac

if ! command -v pwsh &> /dev/null; then
    echo -e "\033[0;31mERROR: PowerShell (pwsh) no está instalado.\033[0m"
    echo "Por favor ejecuta el instalador './install.sh' primero para configurarlo automáticamente."
    exit 1
fi

if [ -z "$1" ]; then
    echo "Uso: ./audit.sh <ruta-del-proyecto> [ruta-del-reporte-html]"
    exit 1
fi

# Resolver ruta absoluta en Linux/macOS
if command -v realpath &> /dev/null; then
    PROJECT_PATH=$(realpath "$1")
else
    PROJECT_PATH="$1"
fi

REPORT_PATH=""
if [ ! -z "$2" ]; then
    if command -v realpath &> /dev/null; then
        REPORT_PATH=$(realpath "$2")
    else
        REPORT_PATH="$2"
    fi
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Ejecutar a través de pwsh
pwsh -ExecutionPolicy Bypass -File "$SCRIPT_DIR/audit.ps1" -ProjectPath "$PROJECT_PATH" -ReportPath "$REPORT_PATH"
