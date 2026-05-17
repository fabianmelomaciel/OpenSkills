#!/bin/bash
# OpenSkills Installer for Linux/Mac
# Soporta opencode y antigravity

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="$SCRIPT_DIR/skills"

echo "=== OpenSkills Installer ==="
echo ""

if [ ! -d "$SKILLS_DIR" ]; then
    echo "ERROR: No se encuentra skills/ en $SCRIPT_DIR"
    exit 1
fi

# Detectar destino
TARGET=""
if [ -d "$HOME/.config/opencode" ]; then
    TARGET="$HOME/.config/opencode/openskills"
    echo "Detectado: opencode -> $TARGET"
elif [ -d "$HOME/.config/antigravity" ]; then
    TARGET="$HOME/.config/antigravity/openskills"
    echo "Detectado: antigravity -> $TARGET"
else
    TARGET="$HOME/.openskills"
    echo "No se detecto opencode ni antigravity. Usando: $TARGET"
fi

# Crear estructura
mkdir -p "$TARGET/skills"
mkdir -p "$TARGET/docs"

# Copiar skills
echo ""
echo "Instalando skills..."
COUNT=0
for SKILL in "$SKILLS_DIR"/*/; do
    NAME=$(basename "$SKILL")
    echo "  Copiando: $NAME..."
    cp -rf "$SKILL" "$TARGET/skills/$NAME"
    COUNT=$((COUNT + 1))
done

# Copiar archivos base
cp "$SCRIPT_DIR/README.md" "$TARGET/" 2>/dev/null || true
cp "$SCRIPT_DIR/package.json" "$TARGET/" 2>/dev/null || true
cp "$SCRIPT_DIR/.gitignore" "$TARGET/" 2>/dev/null || true
cp "$SCRIPT_DIR/install.sh" "$TARGET/" 2>/dev/null || true

echo ""
echo "Instalacion completa! $COUNT skills instaladas."
echo ""
echo "Agrega estas rutas a tu configuracion:"
echo ""
echo '  "skills": { "paths": ['
for SKILL in "$SKILLS_DIR"/*/; do
    NAME=$(basename "$SKILL")
    echo "    \"$TARGET/skills/$NAME\","
done
echo '  ]}'
echo ""

# Para opencode, configurar automaticamente si existe opencode.json
OPENCODE_CONFIG="$HOME/.config/opencode/opencode.json"
if [ -f "$OPENCODE_CONFIG" ] && command -v jq &> /dev/null; then
    echo "Configurando opencode.json..."
    # Nota: la config manual se explica en el README
    echo "  Puedes usar: jq para actualizar skills.paths manualmente"
fi
