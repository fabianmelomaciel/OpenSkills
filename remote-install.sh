#!/bin/bash
# Remote installer for OpenSkills in Linux/Mac
set -e

echo ""
echo "=== OpenSkills Remote Installer ==="
echo ""

# Check if git is installed
if ! command -v git &> /dev/null; then
    echo "ERROR: Git no esta instalado o no se encuentra en el PATH. Por favor instala Git antes de continuar."
    exit 1
fi

# Determine destination directory
TARGET="$HOME/.config/opencode/openskills"
if [ -d "$HOME/.config/antigravity" ]; then
    TARGET="$HOME/.config/antigravity/openskills"
fi

echo "Clonando/Actualizando OpenSkills en $TARGET..."

if [ -d "$TARGET" ]; then
    echo "El directorio de destino ya existe. Actualizando con git pull..."
    cd "$TARGET"
    git pull || echo "Advertencia: No se pudo realizar git pull. Intentando continuar..."
    cd - > /dev/null
else
    git clone https://github.com/fabianmelomaciel/OpenSkills.git "$TARGET"
fi

# Run the installer
echo "Ejecutando instalador local..."
bash "$TARGET/install.sh"
