# OpenSkills 🛠️

**Skills portables para opencode y antigravity.**

OpenSkills es una colección de skills (agentes de IA) que te ayudan a desarrollar software mejor: desde brainstorming yplanificación hasta testing de seguridad y revisión de código.

Funciona de manera autónoma con **opencode** y **antigravity**.

---

## Skills incluidas

### Core (metodologías de desarrollo)

| Skill | Uso |
|-------|-----|
| `brainstorming` | Diseñar features antes de codificar |
| `writing-plans` | Crear planes de implementación detallados |
| `test-driven-development` | TDD disciplina (red-green-refactor) |
| `subagent-driven-development` | Ejecutar planes con subagentes + review |
| `executing-plans` | Ejecutar planes en lote con checkpoints |
| `systematic-debugging` | Debuggear bugs sistemáticamente |
| `verification-before-completion` | Verificar antes de decir "está listo" |
| `finishing-a-development-branch` | Completar ramas de desarrollo |
| `requesting-code-review` | Solicitar code review |
| `receiving-code-review` | Recibir y aplicar code review |
| `dispatching-parallel-agents` | Disparar tareas paralelas independientes |
| `using-git-worktrees` | Aislar workspaces para features |
| `writing-skills` | Crear y testear nuevas skills |

### Agentes (asistentes especializados)

| Agente | Descripción |
|--------|-------------|
| `project-manager` | Escucha al CEO, planea, delega a subagentes, revisa y reporta |
| `creador-contenido-redes` | Analiza videos y optimiza contenido para redes sociales |
| `auditor-de-seguridad` | Escanea proyectos buscando vulnerabilidades, secrets, SAST, dependencias, infraestructura, DB y CI/CD |

---

## Instalación

### Instalación Remota (One-Liner Rápida) 🚀

Si quieres instalar o actualizar OpenSkills directamente desde la web sin necesidad de clonar o descargar manualmente:

#### En Windows (PowerShell)
```powershell
irm https://raw.githubusercontent.com/fabianmelomaciel/OpenSkills/main/remote-install.ps1 | iex
```

#### En Linux/Mac (Bash)
```bash
curl -fsSL https://raw.githubusercontent.com/fabianmelomaciel/OpenSkills/main/remote-install.sh | bash
```

---

### Desde GitHub (clonado manual)

#### En Windows (opencode)

```powershell
# 1. Clonar el repositorio
git clone https://github.com/fabianmelomaciel/OpenSkills.git "$env:USERPROFILE\.config\opencode\openskills"

# 2. Ejecutar instalador
& "$env:USERPROFILE\.config\opencode\openskills\install.ps1"
```

O desde cualquier ubicación:

```powershell
git clone https://github.com/fabianmelomaciel/OpenSkills.git C:\laragon\www\OpenSkills
cd C:\laragon\www\OpenSkills
.\install.ps1
```

#### En Linux/Mac (antigravity)

```bash
# 1. Clonar
git clone https://github.com/fabianmelomaciel/OpenSkills.git ~/.config/antigravity/openskills

# 2. Ejecutar instalador
bash ~/.config/antigravity/openskills/install.sh
```

### Instalación manual

Copia las skills que necesites a tu directorio de skills:

```bash
# opencode
cp -r skills/* ~/.config/opencode/skills/

# antigravity
cp -r skills/* ~/.config/antigravity/skills/
```

Luego agrega las rutas a tu configuración:

**opencode.json:**
```json
{
  "skills": {
    "paths": [
      "~/.config/opencode/openskills/skills/core",
      "~/.config/opencode/openskills/skills/project-manager",
      "~/.config/opencode/openskills/skills/creador-contenido-redes",
      "~/.config/opencode/openskills/skills/auditor-de-seguridad"
    ]
  }
}
```

---

## Uso básico

### Cargar un skill

En opencode/antigravity, los skills se cargan automáticamente según la tarea. Para invocar uno manualmente:

> "Usa el skill `auditor-de-seguridad` para auditar este proyecto"

> "Activa `writing-plans` para crear el plan de implementación"

### Agentes primarios

Los agentes `project-manager`, `creador-contenido-redes` y `auditor-de-seguridad` se configuran como agentes primarios. Puedes invocarlos directamente:

> "@project-manager necesito construir un login"

> "@creador-contenido-redes optimiza este video"

> "@auditor-de-seguridad escanea este proyecto"

---

## Skills personalizadas

Puedes crear tus propias skills en `skills/` y contribuirlas via Pull Request.

Estructura de una skill:

```
skills/mi-skill/
  └── SKILL.md    ← Instrucciones para el agente
```

El SKILL.md debe tener frontmatter YAML:

```yaml
---
name: mi-skill
description: "Usar cuando [condiciones especificas]"
---
```

Ver `skills/core/writing-skills` para la guía completa.

---

## Desarrollo

```powershell
# Ver estructura completa
Get-ChildItem -Recurse -File

# Probar un scanner
& "skills\auditor-de-seguridad\scanners\secrets-scanner.ps1" -ProjectPath "C:\ruta\del\proyecto"
```

---

## Licencia

MIT — Fabian Melo Maciel
