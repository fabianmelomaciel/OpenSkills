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

## 🧠 Aprendizaje Dinámico (Sistema CODEX)

OpenSkills incorpora un **Bucle de Memoria Persistente Compartida** a través del sistema **CODEX**. Esto permite que los agentes aprendan activamente de tu entorno de desarrollo local y eviten cometer los mismos errores o gotchas técnicos en el futuro.

### ¿Cómo funciona el aprendizaje?
1. **Lectura Activa:** Al iniciar una tarea, el agente busca y lee el archivo `CODEX.md` (buscando hacia arriba desde su carpeta o en el directorio raíz de ejecución).
2. **Aplicación de Lecciones:** Adapta sus decisiones y comandos de acuerdo con las configuraciones y gotchas específicos de tu máquina documentados allí (como versiones de PHP, puertos de bases de datos, etc.).
3. **Escritura en Caliente:** Si durante la tarea el agente descubre un patrón de error del entorno, soluciona un bug de configuración complejo o aprende una directiva del proyecto, **edita el archivo `CODEX.md` para registrar el aprendizaje** en la sección de Mission Logs.

> [!NOTE]
> **Preservación de Memoria:** Los instaladores (`install.ps1` y `install.sh`) están configurados para instalar `CODEX.md` **únicamente si no existe**. Si ya hay un archivo `CODEX.md` en tu directorio local activo, el instalador lo conservará intacto. ¡Tu memoria de aprendizaje agéntica acumulada está 100% protegida!

---

## 🎨 Report Dashboards Visuales Premium

Los agentes de análisis ahora generan reportes visuales de primer nivel (diseñados con Vanilla HTML5, CSS3, animaciones de transición, dark-mode y glassmorphism) ubicados en su subcarpeta `/reports`:

### 🔒 1. Dashboard de Auditoría de Seguridad (`auditor-de-seguridad`)
Generado dinámicamente usando la plantilla [dashboard-template.html](file:///c:/laragon/www/OpenSkills/skills/auditor-de-seguridad/reports/dashboard-template.html).
* **Métricas en Rejilla (Stats Grid):** Conteo visual rápido de vulnerabilidades críticas, altas, medias y bajas con sombras luminosas (glow-effects).
* **Acordeones Interactivos:** Expande o contrae los hallazgos haciendo clic en ellos (desarrollado con transiciones CSS fluidas).
* **Remediación Focalizada:** Tarjetas con colores de advertencia según la severidad para guiar al desarrollador en la solución.
* **Visor de Código:** Bloques oscuros estilizados tipo terminal con tipografía monospace para examinar los fragmentos vulnerables.

### 📱 2. Planificador Editorial de Contenido (`creador-contenido-redes`)
Generado usando la plantilla [content-template.html](file:///c:/laragon/www/OpenSkills/skills/creador-contenido-redes/reports/content-template.html).
* **Ganchos Virales:** Caja interactiva que despliega los ganchos recomendados para los primeros 3 segundos junto con sugerencias de gesticulación o tomas.
* **Clips Sugeridos:** Listas ordenadas con marcas de tiempo óptimas para recortar fragmentos virales de alto impacto.
* **Optimización Multiplataforma por Pestañas:** Un sistema interactivo que te permite alternar dinámicamente entre **TikTok**, **Instagram Reels** y **YouTube Shorts**, con temáticas visuales de color propias de cada red.
* **Cajas de Copiado Rápido (Copy-to-Clipboard):** Botones inteligentes integrados que con un solo clic copian la descripción o hashtags al portapapeles y muestran feedback visual en color verde (`¡Copiado!`).

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
