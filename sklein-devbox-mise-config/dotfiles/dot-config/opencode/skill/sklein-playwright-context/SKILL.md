---
name: sklein-playwright-context
description: Contexte Playwright pour Stéphane — Chromium headless déjà lancé via pitchfork, app web déjà en cours d'exécution locale. Utiliser quand l'utilisateur demande d'utiliser Playwright, de faire des tests e2e, du browser automation, ou du scraping.
---

# Contexte Playwright

## Prérequis déjà satisfaits

Avant toute utilisation de Playwright, ces prérequis sont **déjà en place** :

- **Chromium headless** est déjà lancé par `pitchfork` (service `global/chromium-headless`) et expose le protocole CDP sur `http://127.0.0.1:9222`
- **L'application web** est déjà en cours d'exécution locale (ex: `pnpm run dev`)

## Règles

1. **Ne pas lancer Chromium** — il tourne déjà via pitchfork
2. **Ne pas lancer l'application web** — elle tourne déjà
3. **Ne jamais lancer `playwright-mcp --no-sandbox`** directement
4. **Ne jamais installer de package** — ni `playwright`, ni `playwright-mcp`, ni `@playwright/test`, ni aucun autre package lié

## Activation du MCP Playwright

Le MCP Playwright est défini dans `~/.config/opencode/opencode.jsonc` avec `"enabled": false`. Si tu as besoin de l'utiliser, **demande au développeur** d'activer manuellement le MCP server en passant `"enabled": true` dans la configuration.
