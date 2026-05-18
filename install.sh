#!/bin/bash
# OpenSkills Installer for Linux/Mac
# Soporta opencode y antigravity

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="$SCRIPT_DIR/skills"

install_powershell() {
    echo "Detectando sistema operativo..."
    if [ "$(uname)" == "Darwin" ]; then
        echo "macOS detectado. Instalando via Homebrew..."
        if command -v brew &> /dev/null; then
            brew install --cask powershell
        else
            echo "ERROR: Homebrew no esta instalado. Instala PowerShell manualmente desde https://github.com/PowerShell/PowerShell"
        fi
    elif [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "Linux ($NAME) detectado."
        case "$ID" in
            ubuntu|debian)
                echo "Instalando para Debian/Ubuntu..."
                sudo apt-get update
                sudo apt-get install -y wget apt-transport-https software-properties-common
                wget -q "https://packages.microsoft.com/config/$ID/$VERSION_ID/packages-microsoft-prod.deb"
                sudo dpkg -i packages-microsoft-prod.deb
                rm packages-microsoft-prod.deb
                sudo apt-get update
                sudo apt-get install -y powershell
                ;;
            fedora|rhel|centos)
                echo "Instalando para RedHat/Fedora..."
                sudo dnf install -y "https://packages.microsoft.com/config/rhel/8/packages-microsoft-prod.rpm"
                sudo dnf install -y powershell
                ;;
            arch)
                echo "Arch Linux detectado."
                echo "Por favor, corre en tu terminal: yay -S powershell-bin"
                ;;
            *)
                echo "Distribucion no soportada para autoinstalacion. Por favor instala pwsh manualmente."
                ;;
        esac
    else
        echo "Sistema operativo no reconocido. Instala pwsh manualmente."
    fi
}

check_dependencies() {
    echo -e "\n=== DIAGNOSTICO DE DEPENDENCIAS ==="
    
    if ! command -v pwsh &> /dev/null; then
        echo -e "  [-] powershell (pwsh): \033[0;31mFALTA (Critico para scanners)\033[0m"
        echo "PowerShell (pwsh) es indispensable para ejecutar la suite de seguridad."
        read -p "  ¿Deseas que el instalador intente instalar PowerShell de forma automatica? [S/N]: " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Ss]$ ]]; then
            install_powershell
        else
            echo "Instalacion automatica omitida. Recuerda instalar PowerShell manualmente."
        fi
    else
        echo -e "  [+] powershell (pwsh): \033[0;32mInstalado\033[0m"
    fi

    local deps=("git" "node" "npm" "composer" "pip" "pip-audit")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            echo -e "  [-] $dep: \033[0;33mFALTA (Opcional)\033[0m"
            if [ "$dep" == "pip-audit" ] && command -v pip &> /dev/null; then
                read -p "      ¿Deseas instalar 'pip-audit' via pip? [S/N]: " -n 1 -r
                echo ""
                if [[ $REPLY =~ ^[Ss]$ ]]; then
                    pip install pip-audit
                fi
            fi
        else
            echo -e "  [+] $dep: \033[0;32mInstalado\033[0m"
        fi
    done
    echo ""
}

echo "=== OpenSkills Installer ==="
echo ""

if [ ! -d "$SKILLS_DIR" ]; then
    echo "ERROR: No se encuentra skills/ en $SCRIPT_DIR"
    exit 1
fi

check_dependencies

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

# Generar CODEX.md si no existe (es local-only, no está en el repo)
if [ ! -f "$TARGET/CODEX.md" ]; then
    cat > "$TARGET/CODEX.md" << 'CODEX_EOF'
# 🧠 OpenSkills: Tactical CODEX (Learning Memory)

This file is the shared, evolving memory of the OpenSkills agent squad. It tracks
environment-specific patterns, technical gotchas, and lessons learned to avoid
repeating the same mistakes.

> [!IMPORTANT]
> This file is **local-only** and listed in .gitignore. Never commit it to a
> public repository — it may contain project-specific paths and patterns.

## 🧠 Environment & Core Intelligence

- **Host OS**: *(e.g. Ubuntu 22.04 / macOS Ventura / Windows PowerShell 5.1)*
- **Active Workspace**: *(e.g. ~/projects/my-app — PHP SaaS)*
- **Stack**: *(e.g. PHP 8.x, MySQL, nginx, cURL)*

## 🛠️ Technical Gotchas & Environment Lessons

- Deployment scripts (git.php, deploy.sh, etc.) must never be reachable from the
  public web. Block in .htaccess or exclude from FTP sync. Classify as HIGH/CRITICAL
  in audits if found exposed.
- .env files must always be in .gitignore. Never commit secrets.

## 💻 Mission Logs & Tactical Learnings

- [YYYY-MM-DD] - (Short title) — (What happened, root cause, fix, what to do differently next time.)
CODEX_EOF
    echo "  CODEX.md generado por primera vez (local-only)."
else
    echo "  CODEX.md ya existe localmente (memoria de aprendizaje conservada)."
fi

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
