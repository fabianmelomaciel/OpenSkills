# 🧠 OpenSkills: Tactical CODEX (Learning Memory)

This document represents the shared, dynamically evolving persistent memory of the OpenSkills agent squad. It tracks environment-specific nuances, tactical patterns, and successful solutions to prevent the repetition of past failures.

> [!IMPORTANT]
> This file is a dynamic runtime journal. Do not hardcode absolute user paths, specific machine directories, or local usernames in the master repository version. The executing agent will automatically detect and document the host environment nuances upon its first execution in a new workspace.

## 🧠 Environment & Core Intelligence
- **Host OS**: Windows (PowerShell 5.1)
- **Active Workspace**: C:\laragon\www\clic404 (PHP SaaS project)
- **Workspace Settings**: PHP 8.x, Laragon/XAMPP, MySQL, cURL

## 🛠️ Technical Gotchas & Environment Lessons
- All cURL calls use `CURLOPT_SSL_VERIFYPEER => false` — this is a local dev convenience but must be removed for production. On Windows, CACert bundle path should be configured in php.ini or provided explicitly.
- SMTP credentials stored in plaintext in `.env` — other credentials use `ENC()` wrapper but SMTP does not.

## 💻 Mission Logs & Tactical Learnings
- [2026-05-18] - FinOps Audit on CLIC404 — Identified 14 findings (1 critical, 5 high, 4 medium, 4 low). Key wins: PayPal OAuth token caching could save ~30% API calls; polling backoff reduces HTTP overhead ~40%; SSL verification disabled everywhere is a PCI-DSS compliance risk. Report generated at `reports/finops-audit-2026-05-18.html`.
- [2026-05-18] - SMTP credentials migration from .env to DB settings — Mailer.php refactored to use `getSetting()` pattern (same as PayPalHelper/MercadoPagoHelper). Added smtp_host/smtp_port/smtp_user/smtp_pass to Auth::seed(). Commented out SMTP lines in .env. Fixed duplicate `$port` assignment and added `stream_set_timeout()` in `smtpRead()`. SQL migration script provided for existing credentials.
- [2026-05-18] - FinOps Re-Audit — Mailer fix verified correct. Found FTP credentials in git.php but user corrected: `git.php` has `'git.php'` in its own exclude array (line 26), so it never gets uploaded to production. FIN-015 recalified from critical→low. FIN-016 password reuse also recalified from critical→low. post/config.php remains a medium finding. Report updated at `reports/finops-audit-2026-05-18.html`. 2 resolved (FIN-001, FIN-007), 2 recalified.
- [2026-05-18] - Security Audit festday — El reporte generado automáticamente por el agente usaba un diseño light-mode con los hallazgos renderizados por JavaScript (`const findings = [...]`), lo que causaba bugs visuales y texto crudo al final de la página. Lo correcto es usar `generate-report-from-json.ps1` para convertir cualquier JSON de auditoría al template premium dark-mode (`dashboard-template.html`). Importante: escapar siempre los campos HTML antes de inyectarlos, especialmente si el JSON contiene snippets con PHP o JS.
- [2026-05-18] - **`git.php` nunca debe llegar a producción.** Es un script de deploy que no tiene ningún control de acceso — cualquiera que encuentre la URL puede subir archivos al servidor. La regla aplica a todos los proyectos: excluirlo del deploy (FTP sync), agregarlo al `.gitignore` o bloquearlo en `.htaccess` con `Deny from all`. En auditorías, su presencia accesible es siempre HIGH o CRITICAL.
