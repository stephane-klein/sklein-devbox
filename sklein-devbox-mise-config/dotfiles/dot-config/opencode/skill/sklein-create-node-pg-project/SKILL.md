---
name: sklein-create-node-pg-project
description: Créer un nouveau projet Node.js avec PostgreSQL (raw SQL, migrations, conteneur Podman) basé sur les préférences de Stéphane Klein. Use when user wants to create a Node.js project with PostgreSQL, migrations, or raw SQL.
---

# sklein-create-node-pg-project

Créer un nouveau projet Node.js + PostgreSQL basé sur les préférences de Stéphane Klein. Le projet inclut un conteneur PostgreSQL via Podman Compose, des migrations gérées par `postgres-shift`, et une structure SQL complète (`sqls/schema.sql`, `sqls/fixtures/`, `sqls/migrations/`).

## Déclencheur

Ce skill est activé lorsque l'utilisateur demande de créer un projet Node.js avec PostgreSQL, par exemple :

- "crée un projet node avec PostgreSQL"
- "crée un projet node + pg"
- "initie un projet node et base de données"
- "crée un projet node avec raw SQL"

## Collecte des informations

Si l'utilisateur n'a pas fourni de `PROJECT_SHORT_DESCRIPTION`, l'agent doit lui demander brièvement avant de procéder :

> *« Quel est le but de ce projet ? (1–2 phrases) »*

Si l'utilisateur refuse de donner une description, l'agent peut utiliser une chaîne vide et continuer la génération.

### Question sur Jujutsu

L'agent doit demander à l'utilisateur (use question tool) :

> *« Utiliserez-vous Jujutsu (jj) pour ce projet ? (Oui/Non) »*

- Si **Oui** : `USE_JUJUTSU = true`
- Si **Non** : `USE_JUJUTSU = false`

Cette information sera transmise au template `AGENTS.md`.

### Question sur les secrets d'environnement

L'agent doit demander à l'utilisateur (use question tool) :

> *« Voulez-vous inclure la gestion de variables d'environnement secrètes (fichier `.secret`) ? »*

- Si **Oui** : demander ensuite :

  > *« Voulez-vous intégrer gopass pour la gestion des secrets ? »*

  - Si **Oui** : `INCLUDE_GOPASS_SETUP_SECRET = true`
  - Si **Non** : `INCLUDE_GOPASS_SETUP_SECRET = false`

  `INCLUDE_ENVIRONMENT_SECRETS = true`

- Si **Non** : `INCLUDE_ENVIRONMENT_SECRETS = false` et `INCLUDE_GOPASS_SETUP_SECRET = false`

### Amélioration de la description

Si l'utilisateur a fourni une `PROJECT_SHORT_DESCRIPTION`, l'agent évalue si elle est suffisante et optimale en termes de :
- Clarté
- Concision
- Orthographe et grammaire

Si la description semble insuffisante ou non optimale, l'agent la reformule directement en anglais (une seule version).

Cette version reformulée est utilisée directement dans les templates, sans validation utilisateur.

### Génération de project_slug

L'agent doit déterminer `PROJECT_SLUG` automatiquement :

1. **Dérivation depuis `PROJECT_NAME`** :
   - Convertir en minuscules
   - Remplacer les espaces par des tirets
   - Supprimer tout caractère non alphanumérique ni tiret
   - Exemple : `Mon Super Projet` → `mon-super-projet`

2. **Vérification du dossier cible** :
   - Utiliser le dernier segment du chemin `TARGET_DIR` comme base
   - Appliquer les mêmes règles de transformation

3. **Demande de confirmation** :
   - Si le `PROJECT_NAME` contient des caractères spéciaux ambigus ou si le `PROJECT_SLUG` résultant semble incohérent, demander confirmation à l'utilisateur
   - Proposer le `PROJECT_SLUG` déduit et demander : *« Le nom du repository GitHub sera `{{project_slug}}`. Est-ce correct ? »*
   - L'utilisateur peut accepter ou fournir un `PROJECT_SLUG` personnalisé

## Paramètres

- **`PROJECT_NAME`** (requis) : nom du projet. Peut contenir des tirets, pas d'espaces.
- **`PROJECT_SHORT_DESCRIPTION`** : courte explication du projet et de son but (1–2 phrases).
- **`PROJECT_SLUG`** (optionnel) : nom du repository GitHub (minuscules, tirets, pas d'espaces). Si non fourni, il est déduit automatiquement de `PROJECT_NAME`.
- **`TARGET_DIR`** (optionnel) : chemin absolu ou relatif du répertoire cible. Par défaut : le dossier courant.

## Valeurs fixes

- **`AUTHOR_NAME`** = `Stéphane Klein`

## Version Prefix Doctrine

Toutes les dépendances directes dans `package.json` utilisent le préfixe **tilde (`~`)** plutôt que caret (`^`) ou pin exact.

**Fichiers concernés :**
- `template/package.json.jinja` — chaque version est préfixée par `~` (ex: `"~{{ last_biome_version }}"`)
- `template/.npmrc` — contient `save-prefix=~` pour que `pnpm add` conserve le tilde

**Rationnel :**
- `^` (caret) autorise les montées minor, qui ont déjà causé des régressions en équipe
- pin exact (`"1.2.3"`) bloque les patches de sécurité — pas de mise à jour sans intervention manuelle
- `~` (tilde) est le compromis : les patches de sécurité arrivent via `pnpm update`, les minors/majors nécessitent une décision explicite

## Récupération automatique des versions

Avant toute génération, l'agent doit récupérer dynamiquement :

1. **Dernière version LTS de Node.js** via `https://nodejs.org/dist/index.json` :
   - Filtrer les entrées où `lts` n'est pas `false`.
   - Trier par `date` décroissante et prendre la dernière version (ex: `22.14.0`).
   - Ne garder que le numéro de version, sans le préfixe `v`.

2. **Dernière version de pnpm** via `curl -s https://registry.npmjs.org/pnpm/latest | jq -r '.version'` :
   - Exemple de résultat : `10.8.0`

3. **Dernière version de Biome** via `curl -s https://registry.npmjs.org/@biomejs/biome/latest | jq -r '.version'` :
   - Exemple de résultat : `2.3.11`

4. **Dernière version de npm-package-json-lint** via `curl -s https://registry.npmjs.org/npm-package-json-lint/latest | jq -r '.version'` :
   - Exemple de résultat : `9.0.2`

Si l'une de ces requêtes échoue ou retourne une donnée inutilisable, l'agent **doit échouer proprement** et informer l'utilisateur que la création du projet est impossible sans les versions à jour.

## Vérification des conflits

Avant d'écrire quoi que ce soit, l'agent doit vérifier si les fichiers cibles existent déjà dans `TARGET_DIR`.
Si un ou plusieurs de ces fichiers existent déjà, l'agent doit **prévenir l'utilisateur**, lister les fichiers concernés, et **demander une confirmation explicite** avant d'écraser. Sans confirmation, l'opération s'arrête.

## Génération des fichiers via generate.sh

Une fois les versions récupérées et les conflits résolus (ou confirmés par l'utilisateur) :

1. **Créer un fichier YAML temporaire** `/tmp/opencode/vars.yaml` :
   ```yaml
   author_name: Stéphane Klein
   project_name: "{{PROJECT_NAME}}"
   project_slug: "{{PROJECT_SLUG}}"
   project_short_description: "{{PROJECT_SHORT_DESCRIPTION}}"
   use_jujutsu: {{USE_JUJUTSU}}
    last_node_lts_version: "{{LAST_NODE_LTS_VERSION}}"
    last_pnpm_version: "{{LAST_PNPM_VERSION}}"
    last_biome_version: "{{LAST_BIOME_VERSION}}"
    last_npm_package_json_lint_version: "{{LAST_NPM_PACKAGE_JSON_LINT_VERSION}}"
    include_environment_secrets: {{INCLUDE_ENVIRONMENT_SECRETS}}
   include_gopass_setup_secret: {{INCLUDE_GOPASS_SETUP_SECRET}}
   ```

2. **Exécuter generate.sh** :
   ```bash
   /home/sklein/.config/opencode/skill/sklein-create-node-pg-project/generate.sh \
     /home/sklein/.config/opencode/skill/sklein-create-node-pg-project/template \
     /tmp/opencode/vars.yaml \
     "{{TARGET_DIR}}"
   ```

3. **Supprimer** le fichier temporaire après exécution.

**Note :** le fichier `.npmrc` est également créé (contient `save-prefix=~`). Voir la section "Version Prefix Doctrine" pour le rationnel.

**L'agent ne doit PAS exécuter `pnpm install` ni aucune autre commande d'installation.**

## Arrêt strict après initialisation

**Ce skill a un périmètre strict : initialiser le projet et rien d'autre.**

Une fois les fichiers créés et la confirmation envoyée, l'agent **doit s'arrêter**. Il ne doit en aucun cas :

- Commencer à coder de la logique métier, des composants, ou du code source quelconque
- Exécuter des commandes (`pnpm install`, `pnpm dev`, `pnpm build`, `pnpm test`, `git init`, etc.)
- Créer des fichiers supplémentaires au-delà de ceux générés par `generate.sh`
- Continuer le développement du projet de quelque manière que ce soit

L'initialisation est **terminée** quand les fichiers sont écrits. L'utilisateur décidera lui-même de la suite.

## Confirmation finale

Après avoir écrit les fichiers, l'agent confirme le succès à l'utilisateur en listant les fichiers créés et le répertoire cible, **puis s'arrête**.
