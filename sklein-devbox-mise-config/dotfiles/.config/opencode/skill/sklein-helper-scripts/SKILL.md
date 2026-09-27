---
name: sklein-helper-scripts
description: Conventions pour la création de scripts helper dans des dossiers scripts/
---

# sklein-helper-scripts

## Emplacement

Les scripts helper se placent dans des dossiers `scripts/`. Un projet peut en contenir plusieurs, à la racine comme dans des sous-dossiers.

Exemples : `./scripts/up.sh`, `./packages/cli/scripts/test.sh`, `./services/api/scripts/deploy.sh`.

## Boilerplate

Chaque script commence par :

```bash
#!/usr/bin/env bash
set -e

cd "$(dirname "$0")/../"

# ...
```

- `#!/usr/bin/env bash` — shebang portable
- `set -e` — arrêt sur erreur
- `cd "$(dirname "$0")/../"` — le script s'exécute toujours depuis le répertoire parent du dossier `scripts/` contenant le script, quel que soit le répertoire d'appel

## Référence

<https://notes.sklein.xyz/2026-05-07_1213/zen/>