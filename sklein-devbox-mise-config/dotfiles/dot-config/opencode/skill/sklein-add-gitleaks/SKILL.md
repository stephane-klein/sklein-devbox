---
name: sklein-add-gitleaks
description: Ajoute gitleaks (détection de secrets) à un projet existant — hook pre-commit, script pre-push, configuration .gitleaks.toml et intégration Mise.
---

# sklein-add-gitleaks

Ajoute [gitleaks](https://github.com/gitleaks/gitleaks) à un projet existant pour détecter les fuites de secrets avant commit et avant push.

## Déclencheur

Ce skill est activé lorsque l'utilisateur demande d'ajouter gitleaks à un projet, par exemple :

- "ajoute gitleaks au projet"
- "configure gitleaks"
- "intègre la détection de secrets"
- "ajoute un hook pre-commit pour les secrets"
- "setup gitleaks"

## Dépendances

- **mise** — doit être installé sur la machine de l'utilisateur
- **minijinja-cli** — installé via mise (`github:mitsuhiko/minijinja`), requis pour le rendu des templates

## Collecte des informations

L'agent doit demander à l'utilisateur (use `question` tool) :

### Question 1 : Répertoire cible

> *« Dans quel répertoire se trouve le projet cible ? »*

- Défaut : dossier courant (`TARGET_DIR`)

### Question 2 : Jujutsu

> *« Utilises-tu Jujutsu (jj) pour ce projet ? »*

- **Oui** : `USE_JUJUTSU = true`
  - Crée `scripts/setup-jj-alias.sh`
  - Ajoute l'allowlist `.jj/` dans `.gitleaks.toml`
  - Ajoute la tâche `setup-jj-alias` dans `.mise.toml`
- **Non** : `USE_JUJUTSU = false`

### Question 3 : Chemins supplémentaires à exclure

> *« Y a-t-il des chemins supplémentaires à exclure du scan gitleaks ? (ex: certs/, *.tfstate) »*

- L'utilisateur peut fournir une liste séparée par des espaces
- Si vide, seulement les allowlists par défaut sont incluses
- L'agent convertit cette chaîne en liste YAML pour le fichier vars

## Paramètres

| Variable | Requis | Défaut | Description |
|---|---|---|---|
| `TARGET_DIR` | Non | Dossier courant | Répertoire racine du projet cible |
| `USE_JUJUTSU` | Oui | — | `true` ou `false` |
| `EXTRA_ALLOWLIST_PATHS` | Non | `[]` | Liste YAML des chemins supplémentaires à exclure |
| `GITLEAKS_VERSION` | Non | `8.30.1` | Version de gitleaks à utiliser |

## Vérification des conflits

Avant d'écrire quoi que ce soit, l'agent doit vérifier si les fichiers suivants existent déjà dans `TARGET_DIR` :

- `.gitleaks.toml`
- `git-hooks/pre-commit`
- `scripts/gitleaks-check-push.sh`
- `scripts/setup-git-hooks.sh`
- `scripts/setup-jj-alias.sh` (si `USE_JUJUTSU = true`)

Si l'un d'eux existe, l'agent doit **prévenir l'utilisateur**, lister les fichiers concernés, et **demander une confirmation explicite** avant d'écraser.

## Génération des fichiers

1. **Créer un fichier YAML temporaire** `/tmp/opencode/gitleaks-vars.yaml` :

   `EXTRA_ALLOWLIST_PATHS` est une liste YAML. Si l'utilisateur a fourni une chaîne séparée par des espaces, l'agent doit la convertir en liste YAML.

   ```yaml
   use_jujutsu: {{USE_JUJUTSU}}
   extra_allowlist_paths: {{EXTRA_ALLOWLIST_PATHS}}
   gitleaks_version: "{{GITLEAKS_VERSION}}"
   ```

2. **Exécuter generate.sh** :

   ```bash
   /home/sklein/.config/opencode/skill/sklein-add-gitleaks/generate.sh \
     /home/sklein/.config/opencode/skill/sklein-add-gitleaks/template \
     /tmp/opencode/gitleaks-vars.yaml \
     "{{TARGET_DIR}}"
   ```

3. **Supprimer** le fichier temporaire après exécution.

## Mise à jour de `.mise.toml`

L'agent doit lire `.mise.toml` dans `TARGET_DIR` (s'il existe) et l'éditer intelligemment :

### Ajout de gitleaks dans `[tools]`

- Chercher si `"aqua:gitleaks/gitleaks"` est déjà présent dans une section `[tools]`
- Si **absent** : ajouter `"aqua:gitleaks/gitleaks" = "{{GITLEAKS_VERSION}}"` dans la section `[tools]` existante
- Si **déjà présent** : ne rien faire (garder la version existante)

Si `.mise.toml` n'existe pas, le créer avec :

```toml
[tools]
"aqua:gitleaks/gitleaks" = "{{GITLEAKS_VERSION}}"
```

### Ajout des tâches

Ajouter uniquement les tâches **absentes** dans le fichier. Pour chaque tâche, vérifier si `[tasks.<name>]` existe déjà :

| Tâche | Condition | Contenu |
|---|---|---|---|
| `setup-git-hooks` | Toujours | `run = "scripts/setup-git-hooks.sh"` |
| `setup-jj-alias` | Si `USE_JUJUTSU = true` | `run = "scripts/setup-jj-alias.sh"` |
| `gitleaks-check-push` | Toujours | `run = "scripts/gitleaks-check-push.sh"` |
| `gitleaks-scan` | Toujours | `run = "gitleaks dir --no-banner -v {{config_root}}"` (littéral, avec `{{config_root}}` qui sera résolu par Mise) |
| `gitleaks-history-scan` | Si `USE_JUJUTSU = true` | `description = "Scan entire jj commit history for secrets with gitleaks"`<br>`run = "gitleaks git --no-banner -v .git"` |

Pour l'insertion, ajouter chaque tâche manquante à la fin du fichier (avant-dernière ligne si un `[hooks.enter]` existe, sinon tout à la fin).

## Mise à jour du `README.md`

L'agent doit lire `README.md` dans `TARGET_DIR` (s'il existe).

### Recherche d'une section existante

Chercher les motifs suivants (insensible à la casse) :

- `Secret detection with gitleaks`
- `## Gitleaks`
- `secret detection`

Si l'un d'eux est trouvé, **ne pas modifier** `README.md` (la documentation gitleaks existe déjà).

### Ajout d'une nouvelle section

Si aucune section gitleaks n'existe :

1. **Chercher une section `## Contribution`** dans le `README.md`
   - **Si trouvée** : ajouter un sous-titre `### Secret detection with gitleaks` à la fin de cette section
   - **Si absente** : créer `## Contribution` avec le sous-titre `### Secret detection with gitleaks` à la fin du fichier

2. **Texte à insérer** (adapter selon `USE_JUJUTSU`) :

   Si `USE_JUJUTSU = true` :

   ```markdown
   ### Secret detection with gitleaks

   [Gitleaks](https://github.com/gitleaks/gitleaks) scans for secrets before they
   reach the remote repository. It runs at two points:

   - **`git commit`** — the `git-hooks/pre-commit` hook checks staged files.
   - **`jj publish`** — local alias that runs `mise run gitleaks-check-push` before
     `jj git push`.

   Configuration is in `.gitleaks.toml`.

   **One-time setup after clone:**

   ```
   mise install
   mise run setup-git-hooks
   mise run setup-jj-alias
   ```

   **Manual scan** (outside of hooks):

   ```
   mise run gitleaks-scan            # working directory scan
   mise run gitleaks-check-push      # pre-push scan (called by `jj publish`)
   mise run gitleaks-history-scan    # scan entire jj commit history
   ```

   Si `USE_JUJUTSU = false` :

   ```markdown
   ### Secret detection with gitleaks

   [Gitleaks](https://github.com/gitleaks/gitleaks) scans for secrets before they
   reach the remote repository.

   - **`git commit`** — the `git-hooks/pre-commit` hook checks staged files.

   Configuration is in `.gitleaks.toml`.

   **One-time setup after clone:**

   ```
   mise install
   mise run setup-git-hooks
   ```

   **Manual scan** (outside of hooks):

   ```
   mise run gitleaks-scan        # full project scan
   mise run gitleaks-check-push  # pre-push scan
   ```

## Post-génération

L'agent doit exécuter les commandes suivantes dans `TARGET_DIR` :

```bash
chmod +x scripts/gitleaks-check-push.sh scripts/setup-git-hooks.sh
```

Et si `USE_JUJUTSU = true` :

```bash
chmod +x scripts/setup-jj-alias.sh
```

Puis informer l'utilisateur des prochaines étapes :

```
Configuration gitleaks ajoutée. Prochaines étapes :

1. mise install                    # Installe gitleaks (via aqua)
2. mise run setup-git-hooks        # Active le hook pre-commit
```

Si `USE_JUJUTSU = true`, ajouter :

```
3. mise run setup-jj-alias         # Crée l'alias jj publish
```

## Arrêt strict après génération

**Ce skill a un périmètre strict : ajouter gitleaks au projet et rien d'autre.**

Une fois les fichiers créés, `.mise.toml` et `README.md` mis à jour, et la confirmation envoyée, l'agent **doit s'arrêter sans rien faire d'autre**.

## Référence

- [Gitleaks](https://github.com/gitleaks/gitleaks)
- [Projet homelab.sklein.xyz](https://github.com/stephane-klein/homelab.sklein.xyz) — projet source de l'intégration
