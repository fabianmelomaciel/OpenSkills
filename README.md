# OpenSkills 🛠️

**Skills portables para opencode y antigravity.**

OpenSkills es una colección de skills (agentes de IA) que te ayudan a desarrollar software mejor: desde brainstorming y planificación hasta testing de seguridad y revisión de código.

Funciona de manera autónoma con **opencode** y **antigravity**.

---

## Skills incluidas

### Core (metodologías de desarrollo)

| Skill | Uso |
|-------|-----|
| `brainstorming` | Diseñar features antes de codificar |
| `spec-driven-development` | Definir requerimientos y especificaciones antes de codificar |
| `writing-plans` | Crear planes de implementación detallados |
| `incremental-implementation` | Implementar en rebanadas verticales de forma segura |
| `test-driven-development` | TDD disciplina (red-green-refactor) |
| `context-engineering` | Optimizar el contexto y evitar context flooding |
| `subagent-driven-development` | Ejecutar planes con subagentes + review |
| `executing-plans` | Ejecutar planes en lote con checkpoints |
| `systematic-debugging` | Debuggear bugs sistemáticamente |
| `code-simplification` | Reducir la complejidad y aplicar Chesterton's Fence |
| `verification-before-completion` | Verificar antes de decir "está listo" |
| `finishing-a-development-branch` | Completar ramas de desarrollo |
| `requesting-code-review` | Solicitar code review |
| `receiving-code-review` | Recibir y aplicar code review |
| `dispatching-parallel-agents` | Disparar tareas paralelas independientes |
| `using-git-worktrees` | Aislar workspaces para features |
| `writing-skills` | Crear y testear nuevas skills |

### 🎨 Design Engineering (calidad visual premium)

| Skill | Uso |
|-------|-----|
| `emil-kowalski-design` | Animaciones <300ms, micro-interacciones, perceived performance al estilo Emil Kowalski |
| `impeccable-design-taste` | Auditoría de diseño premium: tipografía, color, espaciado, motion, accesibilidad WCAG AA |

### Agentes (asistentes especializados)

| Agente | Descripción |
|--------|-------------|
| `project-manager` | Escucha al CEO, planea, delega a subagentes, revisa y reporta |
| `optimizador-finops` | Realiza auditoría de calidad SQA de consumo de tokens y APIs de IA (conforme a ISO 31000) |
| `agente-devops` | Diseña y audita empaquetado seguro en contenedores Docker y flujos de CI/CD (conforme a IEEE 730 e ISO 27001) |
| `auditor-de-marketing` | Audita optimización SEO On-Page, OpenGraph en redes y CTAs de conversión en el sitio web |
| `gestor-documental` | Diseña y valida especificaciones técnicas y académicas (Normas APA, ISO 29148, ISO 29119) |
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

#### En Linux/Mac (antigravity / gemini)

```bash
# 1. Clonar
git clone https://github.com/fabianmelomaciel/OpenSkills.git ~/.gemini/config/openskills

# 2. Ejecutar instalador
bash ~/.gemini/config/openskills/install.sh
```

O con el path clásico de antigravity:

```bash
git clone https://github.com/fabianmelomaciel/OpenSkills.git ~/.config/antigravity/openskills
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
      "~/.config/opencode/openskills/skills/optimizador-finops",
      "~/.config/opencode/openskills/skills/agente-devops",
      "~/.config/opencode/openskills/skills/auditor-de-marketing",
      "~/.config/opencode/openskills/skills/gestor-documental",
      "~/.config/opencode/openskills/skills/auditor-de-seguridad"
    ]
  }
}
```


## Compatibilidad con otras herramientas de IA

Dado que las skills de **OpenSkills** están escritas en Markdown estándar con metadatos YAML, son 100% compatibles e integrables de manera nativa o personalizada con otras herramientas líderes de IA:

### 1. Claude Code (CLI de Anthropic)
Claude Code soporta la carga global o local de carpetas de skills con formato `SKILL.md` y frontmatter YAML:
* **Instalación Global:** Los instaladores (`install.ps1` e `install.sh`) detectan automáticamente si tienes Claude Code instalado (`~/.claude`) y copian directamente las skills en `~/.claude/skills/`.
* **Instalación Manual:** Puedes copiar cualquier carpeta de skill a:
  * Global (Usuario): `~/.claude/skills/<nombre-skill>/SKILL.md`
  * Local (Proyecto): `./.claude/skills/<nombre-skill>/SKILL.md`

### 2. Cursor IDE (Rules `.mdc`)
Cursor permite aplicar reglas automáticamente según los archivos en los que trabajes:
* Copia cualquier archivo `SKILL.md` al directorio `.cursor/rules/` de tu proyecto y renómbralo con extensión `.mdc`.
* Agrega las directivas de exclusión/inclusión de archivos en la cabecera del archivo usando glob patterns:
  ```yaml
  ---
  description: Reglas de TDD para el proyecto
  globs: ["src/**/*.ts", "tests/**/*.ts"]
  alwaysApply: false
  ---
  ```

### 3. GitHub Copilot (`.instructions.md`)
Copilot Chat lee archivos de instrucciones del sistema en el repositorio:
* Copia la skill al directorio `.github/instructions/` de tu proyecto y llámala `<nombre-skill>.instructions.md`.
* Añade la directiva `applyTo` en la cabecera YAML para indicarle qué archivos vigilar:
  ```markdown
  ---
  applyTo:
    - src/components/**
    - src/lib/**
  ---
  ```

### 4. Aider CLI
Puedes pasar cualquier skill de OpenSkills directamente a Aider al iniciar la sesión:
* Inicia Aider con el parámetro de instrucciones:
  ```bash
  aider --instructions-file skills/core/code-simplification/SKILL.md
  ```

---

## Uso básico

### Cargar un skill

En opencode/antigravity, los skills se cargan automáticamente según la tarea. Para invocar uno manualmente:

> "Usa el skill `auditor-de-seguridad` para auditar este proyecto"

> "Activa `writing-plans` para crear el plan de implementación"

### Agentes primarios

Los agentes `project-manager`, `optimizador-finops`, `agente-devops`, `auditor-de-marketing`, `gestor-documental` y `auditor-de-seguridad` se configuran como agentes primarios. Puedes invocarlos directamente:

> "@project-manager necesito construir un login"

> "@optimizador-finops optimiza el consumo de este prompt"

> "@agente-devops crea un Dockerfile seguro"

> "@auditor-de-marketing audita el SEO y conversiones de este sitio"

> "@gestor-documental formatea este reporte en normas APA"

> "@auditor-de-seguridad escanea este proyecto"

---

## 🧩 Filosofía de Código: Componentes Pequeños y "Humanizados"

OpenSkills adopta una filosofía de desarrollo estricta orientada a la eficiencia y el camuflaje:
1. **Micro-Componentes para Ahorro de Tokens:** Todo el código se diseña y construye en archivos/componentes pequeños y modulares. Esto evita lecturas gigantes de archivos largos, ahorrando masivamente el consumo de tokens de contexto cuando interactúas con los agentes.
2. **Refactorización Activa:** Si un agente detecta un archivo voluminoso, intentará sugerir o realizar una refactorización para compactarlo y dividirlo.
3. **Código "Humanizado":** Los agentes están instruidos para generar comentarios naturales (sin jerga robótica) y aplicar espaciados aleatorios e irregulares (estilo humano). Al inspeccionar el código, no presentará el típico formato rígido y predecible que delata que fue hecho con IA.

---

## 🧠 Aprendizaje Dinámico (Sistema CODEX)

OpenSkills incorpora un **Bucle de Memoria Persistente Compartida** a través del sistema **CODEX**. Esto permite que los agentes aprendan activamente de tu entorno de desarrollo local y eviten cometer los mismos errores o repetir contexto ya conocido.

### ¿Cómo funciona el aprendizaje?
1. **Lectura Activa (CODEX-FIRST):** Al iniciar una tarea, el agente lee el archivo `CODEX.md` **antes de hacer cualquier pregunta**. Si el contexto del proyecto está documentado, no te lo vuelve a pedir.
2. **Token Economy:** Los agentes siguen las reglas de economía de tokens del CODEX — output compacto, sin preámbulos, sin preguntas innecesarias.
3. **Escritura en Caliente:** Si durante la tarea el agente descubre un patrón de error, soluciona un bug de configuración o aprende una directiva del proyecto, **edita el `CODEX.md` para registrar el aprendizaje** en Mission Logs.
4. **Verificación Inmediata (Micro-Verification):** Tras cada modificación de código, el agente verifica la sintaxis, la compilación o ejecuta tests locales inmediatamente antes de continuar, previniendo cascadas de fallos costosas en tokens.
5. **Aprendizaje de Contexto Dinámico:** Al resolverse cualquier bug o quirk del entorno, este se documenta en caliente en el CODEX para que otros subagentes o futuras tareas no consuman tokens en diagnosticar de nuevo el mismo problema.

### Secciones del CODEX v2
| Sección | Propósito |
|---------|----------|
| 🎯 Project Context Quick Reference | Stack, DB, directorios, deployment — no te lo vuelven a preguntar |
| 💡 Token Economy Rules | Reglas de eficiencia que siguen todos los agentes |
| 🏗️ Active Design System | Paleta, tipografía, radios — para consistencia visual |
| 🛠️ Technical Gotchas | Quirks del entorno, reglas del proyecto |
| 💻 Mission Logs | Historial de decisiones y soluciones |

> [!NOTE]
> **Preservación de Memoria:** Los instaladores (`install.ps1` y `install.sh`) instalan `CODEX.md` **únicamente si no existe**. Si ya hay un `CODEX.md` en tu directorio local activo, el instalador lo conservará intacto. ¡Tu memoria de aprendizaje acumulada está 100% protegida!

---

## 🎨 Report Dashboards Visuales Premium

Los agentes de análisis ahora generan reportes visuales de primer nivel (diseñados con Vanilla HTML5, CSS3, animaciones de transición, dark-mode y glassmorphism) ubicados en su subcarpeta `/reports` y **proveen un enlace directo clickable `file:///` al final de su ejecución** para abrirlos instantáneamente en tu navegador.

### 🔒 1. Dashboard de Auditoría de Seguridad (`auditor-de-seguridad`)
Generado dinámicamente usando la plantilla [dashboard-template.html](file:///c:/laragon/www/OpenSkills/skills/auditor-de-seguridad/reports/dashboard-template.html).
* **Métricas en Rejilla (Stats Grid):** Conteo visual rápido de vulnerabilidades críticas, altas, medias y bajas con sombras luminosas (glow-effects).
* **Acordeones Interactivos:** Expande o contrae los hallazgos haciendo clic en ellos (desarrollado con transiciones CSS fluidas).
* **Remediación Focalizada:** Tarjetas con colores de advertencia según la severidad para guiar al desarrollador en la solución.
* **Visor de Código:** Bloques oscuros estilizados tipo terminal con tipografía monospace para examinar los fragmentos vulnerables.

> 💡 **¿Ya tienes un JSON de auditoría?** Usa `generate-report-from-json.ps1` para convertirlo al dashboard premium sin tener que re-ejecutar los scanners:
> ```powershell
> .\generate-report-from-json.ps1 -JsonPath .\mi-proyecto\security-audit-report.json
> ```


### 💰 2. Dashboard de Optimización FinOps (`optimizador-finops`)
Generado usando la plantilla [finops-template.html](file:///c:/laragon/www/OpenSkills/skills/optimizador-finops/reports/finops-template.html).
* **Eficiencia de Costes (Amber/Gold Theme):** Métricas clave como el ahorro de tokens estimado, redundancia de prompts e índices de llamadas a APIs.
* **Refactorización Propuesta:** Caja de código interactiva con botón de copiado rápido (`Copy-to-Clipboard`) para aplicar las optimizaciones de prompts y lógica.
* **Gestión de Riesgos de Consumo (ISO 31000):** Tarjetas organizadas por severidad de fuga financiera (Critical, High, Medium, Low) con acordeones CSS.

### 🚀 3. Dashboard de Seguridad de Despliegues (`agente-devops`)
Generado usando la plantilla [devops-template.html](file:///c:/laragon/www/OpenSkills/skills/agente-devops/reports/devops-template.html).
* **Mapeo de Calidad de Configuración (Electric Blue Theme):** Puntuación global SCM (SCM Quality Score), estado de privilegios root y pinning de dependencias.
* **Auditoría de Entornos (IEEE 730 & ISO 27001):** Validaciones sobre imágenes base de Dockerfiles, docker-compose y GitHub Actions.
* **Scaffolding Seguro:** Plantillas listas de Dockerfile y Compose libres de vulnerabilidades con botones de copiado rápido interactivos.

### 📢 4. Dashboard de Optimización de Marketing & SEO (`auditor-de-marketing`)
Generado usando la plantilla [marketing-template.html](file:///c:/laragon/www/OpenSkills/skills/auditor-de-marketing/reports/marketing-template.html).
* **Calidad de Crecimiento (Sunset Coral Theme):** Muestra el On-Page SEO score, estado de etiquetas OpenGraph para redes sociales e índice de conversión de CTAs.
* **Auditoría de Embudo:** Identifica elementos críticos sobre/bajo el pliegue (above/below the fold) y sugiere código HTML optimizado con botones interactivos.

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
