---
name: sklein-generate-project-template
description: Génère le template (template/), le script generate.sh, le vars-example.yaml, et le SKILL.md d'un projet à partir d'un projet source existant. Use when user wants to create a project scaffolding template from an existing project.
---

# sklein-generate-project-template

Meta-outil de génération de templates de projet. À partir d'un projet source
existant, produit un artefact auto-suffisant (template + `generate.sh` +
`vars-example.yaml` + `SKILL.md`) permettant de créer de nouveaux projets du
même type.

## Déclencheur

Ce skill est activé lorsque l'utilisateur demande de créer un template à partir
d'un projet existant, par exemple :

- « génère un template à partir de ce projet »
- « crée un template de scaffolding pour ce projet »
- « template ce projet »
- « transforme ce projet en template paramétrable »

## Collecte des informations initiales

Avant toute analyse, l'agent doit demander (use question tool) :

### Chemin du projet source

> *« Quel est le chemin du projet source à templatiser ? »*

- Demander un chemin absolu.
- Vérifier que le dossier existe et contient des fichiers.
- Si le dossier n'existe pas ou est vide → erreur, s'arrêter.

### Chemin de destination du template

> *« Où souhaitez-vous créer le dossier template ? »*

- Par défaut : `<projet_source>/../template/` ou le dossier courant.
- Si le dossier existe déjà → avertir et demander confirmation avant écrasement.

---

## Vue d'ensemble du workflow

- **Phase 1** — Analyse du projet source
- **Phase 2** — Génération du dossier template/
- **Phase 3** — Génération du vars-example.yaml
- **Phase 4** — Génération du script generate.sh
- **Phase 5** — Validation par reconstruction
- **Phase 6** — Génération du SKILL.md

Chaque phase produit un résultat vérifiable avant de passer à la suivante.
Ne jamais sauter de phase. Ne jamais passer à la phase suivante sans
confirmation de l'utilisateur pour la phase en cours.

---

## Phase 1 — Analyse du projet source

**Objectif** : identifier toutes les variables, les blocs conditionnels, et les
fichiers conditionnels du projet source.

### 1.1 Fichiers à analyser

Lire **uniquement** les fichiers déterminants :

- Fichiers de configuration racine : `package.json`, `.mise.toml`, `.envrc`,
  `compose.yaml`, `Containerfile`, `biome.jsonc`, `.editorconfig`
- Fichiers de documentation racine : `README.md`, `AGENTS.md`, `NEXT_STEPS.md`
- Tout autre fichier que l'utilisateur signale comme pertinent

**Ne pas analyser** :
- `node_modules/`, `.git/`, `.jj/`
- Fichiers binaires (images, archives)
- Fichiers de lock (`pnpm-lock.yaml`, `package-lock.json`)

### 1.2 Variables de base (toujours présentes)

Ces 4 variables sont systématiquement identifiées. L'agent doit les extraire
du projet source :

| Variable | Source typique | Valeur par défaut |
|----------|---------------|-------------------|
| `project_name` | `package.json` → `"name"` | — |
| `project_slug` | `.envrc`, `.mise.toml` | — |
| `project_short_description` | `README.md` (1ère ligne après le titre) | — |
| `author_name` | `package.json` → `"author"` | `Stéphane Klein` |

Pour chaque variable de base, l'agent extrait la valeur du projet source et
demande confirmation (use question tool) :

> *« `project_name` = `{{valeur}}`. Est-ce correct ? »*

Si l'utilisateur répond non, lui demander la valeur correcte.

Pour `author_name`, si la valeur trouvée est `Stéphane Klein`, ne pas
demander confirmation (c'est la valeur par défaut).

### 1.3 Variables candidates supplémentaires

Après avoir extrait les variables de base, l'agent scanne les fichiers
déterminants à la recherche de **valeurs potentiellement variables** :

1. **Numéros de version** dans `package.json` (dependencies, devDependencies)
   et `.mise.toml` (outils versionnés).

2. **Booléens** dans les fichiers `.jinja` (si le projet source a déjà des
   traces de templating) ou dans les fichiers de configuration.

3. **Chaînes récurrentes** qui apparaissent dans plusieurs fichiers.

Pour chaque valeur candidate détectée, l'agent propose à l'utilisateur
(use question tool, multiple: true) :

> *« J'ai détecté les valeurs suivantes qui pourraient être des variables.
> Lesquelles souhaitez-vous templatiser ? »*

L'utilisateur peut :
- Sélectionner les candidats à templatiser
- Ajouter une variable manuellement (nom + valeur actuelle)
- Refuser toutes les propositions

Pour chaque variable retenue, l'agent demande (use question tool) :

> *« Quel nom donner à la variable `{{valeur}}` ? (snake_case) »*

Proposer un nom déduit automatiquement (ex: `2.5.3` dans `@biomejs/biome` →
`last_biome_version`) que l'utilisateur peut accepter ou modifier.

### 1.4 Blocs conditionnels dans les fichiers

L'agent scanne les fichiers pour détecter des **sections de contenu** qui
pourraient être conditionnelles (intuition sémantique : blocs thématiques dans
la documentation, sections de configuration optionnelles).

Pour chaque section candidate, l'agent demande (use question tool) :

> *« Dans `README.md`, je vois un bloc de X lignes sur les variables
> d'environnement secrètes. Voulez-vous le rendre conditionnel ? »*

Si l'utilisateur répond oui, demander :

> *« Quelle variable booléenne contrôle ce bloc ? »*

L'utilisateur fournit le nom de la variable. L'agent enregistre :
- Le fichier concerné
- La variable booléenne de contrôle
- Les lignes exactes du bloc (début → fin)

### 1.5 Fichiers conditionnels (inclusion/exclusion)

L'agent demande (use question tool) :

> *« Certains fichiers du projet ne doivent-ils être inclus que sous
> condition ? (par exemple, des scripts optionnels) »*

Si l'utilisateur répond oui, pour chaque fichier conditionnel :

> *« Quel fichier ? »* — l'utilisateur donne le chemin relatif.

> *« Quelle variable booléenne le contrôle ? »*

L'agent enregistre l'association : `fichier → variable_booléenne`.

### 1.6 Récapitulatif de la phase 1

Avant de passer à la phase 2, l'agent affiche un récapitulatif complet :

```
Variables identifiées :
  project_name = "gestion-de-contacts"
  project_slug = "gestion-de-contacts"
  project_short_description = "A Node.js + PostgreSQL application for managing contacts"
  author_name = "Stéphane Klein"
  last_node_lts_version = "24.18.0"
  last_pnpm_version = "11.13.0"
  last_biome_version = "2.5.3"
  use_jujutsu = true
  include_environment_secrets = true
  include_gopass_setup_secret = true

Blocs conditionnels dans les fichiers :
  AGENTS.md → use_jujutsu (lignes 50-53)
  NEXT_STEPS.md → use_jujutsu (lignes 10-22)
  README.md → include_environment_secrets (lignes 34-48)
  .mise.toml → include_environment_secrets (ligne 7)
  .mise.toml → include_gopass_setup_secret (lignes 56-59)

Fichiers conditionnels :
  scripts/generate-secret.sh → include_gopass_setup_secret
```

L'agent demande (use question tool) :

> *« Confirmez-vous ce récapitulatif ? »*

- Si **oui** → passer à la phase 2.
- Si **non** → corriger avec l'utilisateur.

---

## Phase 2 — Génération du dossier template/

**Objectif** : créer le dossier `template/` contenant les `.jinja` et les
fichiers statiques.

### 2.1 Sanitization préalable

Avant copie, l'agent doit exclure :

- `node_modules/`
- `.git/`, `.jj/`
- `pnpm-lock.yaml`, `package-lock.json`
- Fichiers binaires (images, archives)
- `.secret` (s'il existe — contient des secrets)
- Tout fichier que l'utilisateur demande explicitement d'exclure

### 2.2 Copie de la structure

Pour chaque fichier du projet source (excluant la liste ci-dessus) :

1. **Si le fichier contient une variable identifiée en phase 1** →
   créer `template/<chemin>.jinja` avec les valeurs substituées par `{{ var_name }}`.

   **Règle de substitution** : remplacer chaque occurrence de la valeur par
   `{{ var_name }}`. Si plusieurs variables ont la même valeur, l'agent doit
   utiliser le contexte (fichier, position) pour déterminer la bonne variable.

   Exemple : dans `package.json`, `"gestion-de-contacts"` → `"{{ project_name }}"`,
   tandis que dans `.envrc`, `gestion-de-contacts` → `{{ project_slug }}`.

2. **Si le fichier ne contient aucune variable** →
   copier tel quel dans `template/` (fichier statique).

3. **Si le fichier contient un bloc conditionnel** →
   créer `template/<chemin>.jinja` et entourer le bloc de
   `{% if var_name %}`...`{% endif %}`.

   Si le bloc conditionnel est mutuellement exclusif (ex: Jujutsu vs Git),
   utiliser `{% if var_name %}`...`{% else %}`...`{% endif %}`.

4. **Si le fichier est conditionnel** (inclusion/exclusion) →
   créer `template/<chemin>.jinja` avec le contenu tel quel (pas de
   substitution, le fichier entier est conditionné par une variable booléenne
   gérée dans `generate.sh`).

### 2.3 Vérification

Après génération, l'agent liste les fichiers créés dans `template/` avec leur
type (Jinja ou statique) et demande confirmation.

> *« Le dossier template contient N fichiers (X Jinja, Y statiques).
> Voulez-vous vérifier quelque chose avant de continuer ? »*

---

## Phase 3 — Génération du vars-example.yaml

**Objectif** : créer un fichier `vars-example.yaml` de référence.

### 3.1 Structure

```yaml
# Auteur (par défaut)
author_name: Stéphane Klein

# Nom du projet (utilisé dans package.json, README, etc.)
project_name:

# Nom du repository GitHub (minuscules, sans espaces, tirets acceptés)
project_slug:

# Courte description du projet (1-2 phrases, en anglais)
project_short_description:

# --- Variables supplémentaires ---

# <description>
<var_name>: <valeur_par_défaut>

# --- Flags conditionnels ---

# <description>
<var_bool>: <false>
```

### 3.2 Règles

- Les 4 variables de base sont toujours en tête, avec un commentaire
  descriptif au-dessus.
- Les variables supplémentaires sont groupées sous un commentaire
  `# --- Variables supplémentaires ---`.
- Les variables booléennes sont groupées sous
  `# --- Flags conditionnels ---`.
- Chaque variable a un commentaire descriptif (une ligne) au-dessus.
- Les variables sans valeur par défaut évidente sont laissées vides
  (ex: `project_name:`).
- Les variables avec une valeur par défaut connue sont pré-remplies
  (ex: `author_name: Stéphane Klein`, `last_node_lts_version: 24.15.0`).
- Les booléens sont initialisés à `false`.
- Les commentaires ne contiennent pas la valeur actuelle du projet source
  (le vars-example.yaml est générique, pas lié au projet source).

### 3.3 Sauvegarde

Écrire le fichier `vars-example.yaml` à la racine du dossier template.

---

## Phase 4 — Génération du script generate.sh

**Objectif** : créer un script bash + minijinja-cli qui liste explicitement
chaque fichier à générer.

### 4.1 Structure du script

```bash
#!/bin/bash
set -euo pipefail

template_dir="${1%/}"
vars_file="$2"
target_dir="${3%/}"

# Extraction des variables booléennes (si applicable)
<var_bool>=$(yq '.<var_bool>' "$vars_file")

mkdir -p "$target_dir"

# --- Fichiers statiques ---

mkdir -p "$target_dir/<sous-dossier>"
cp "$template_dir/<chemin>" "$target_dir/<chemin>"

# --- Fichiers Jinja ---

minijinja-cli "$template_dir/<chemin>.jinja" "$vars_file" > "$target_dir/<chemin>"

# --- Fichiers conditionnels ---

if [ "$<var_bool>" = "true" ]; then
  mkdir -p "$target_dir/<sous-dossier>"
  minijinja-cli "$template_dir/<chemin>.jinja" "$vars_file" > "$target_dir/<chemin>"
fi
```

### 4.2 Règles

1. **Header fixe** : `#!/bin/bash`, `set -euo pipefail`, trois arguments.

2. **Extraction des booléens** : pour chaque variable booléenne utilisée dans
   un bloc conditionnel de fichier (`{% if %}`) ou comme condition d'inclusion,
   ajouter une ligne `var=$(yq '.var' "$vars_file")` après les arguments.

3. **Trier alphabétiquement** tous les fichiers.

4. **Dédoublonner les `mkdir -p`** : un seul `mkdir -p` par sous-dossier,
   avant les `cp`/`minijinja-cli` qui y écrivent.

5. **Fichiers statiques** : `cp` pour chaque fichier sans `.jinja` dans
   le template.

6. **Fichiers Jinja** : `minijinja-cli` pour chaque `.jinja`, le nom de sortie
   est obtenu en retirant `.jinja`.

7. **Fichiers conditionnels** : entourer le `minijinja-cli` d'un
   `if [ "$var" = "true" ]`.

8. **Ignorer** `vars-example.yaml` et `generate.sh` lui-même (ne pas les
   référencer dans le script).

### 4.3 Exécution

Une fois le script écrit :

```bash
chmod +x <template_dir>/generate.sh
```

### 4.4 Vérification

L'agent affiche le contenu de `generate.sh` et les fichiers pris en compte.

> *« Le script generate.sh gère N fichiers statiques, M fichiers Jinja,
> P fichiers conditionnels. Est-ce correct ? »*

---

## Phase 5 — Validation par reconstruction

**Objectif** : vérifier que le template permet de régénérer le projet source
à l'identique.

### 5.1 Création du vars de validation

Créer `/tmp/opencode/vars-validation.yaml` avec les valeurs extraites du
projet source en phase 1 :

```yaml
author_name: Stéphane Klein
project_name: "{{valeur_source}}"
project_slug: "{{valeur_source}}"
project_short_description: "{{valeur_source}}"
<var>: "<valeur_source>"
<var_bool>: true  # ou false selon le projet source
```

Toutes les variables identifiées en phase 1 doivent être présentes avec
leur valeur réelle du projet source.

### 5.2 Exécution de generate.sh

```bash
<TEMPLATE_DIR>/generate.sh \
  <TEMPLATE_DIR> \
  /tmp/opencode/vars-validation.yaml \
  /tmp/opencode/test-output
```

Si le script échoue (code retour ≠ 0) → analyser l'erreur, corriger
`generate.sh`, réessayer.

### 5.3 Comparaison avec diff

```bash
diff -r \
  --exclude='node_modules' \
  --exclude='.git' \
  --exclude='.jj' \
  --exclude='pnpm-lock.yaml' \
  --exclude='package-lock.json' \
  /tmp/opencode/test-output/ \
  <PROJET_SOURCE>/
```

**Interprétation** :

- **Aucune sortie** (diff vide) → le template est correct. Passer à la phase 6.
- **Différences sur des fichiers `.jinja`** → normal (le template a `.jinja`,
  pas la source). Pour les fichiers conditionnels avec `.jinja`, le diff peut
  apparaître si le fichier n'existe pas dans test-output. Vérifier que la
  condition booléenne était bien à `true` dans vars-validation.yaml.
- **Différences sur d'autres fichiers** → anomalie. Analyser chaque diff,
  identifier la cause (variable manquante, substitution incorrecte, bloc
  conditionnel mal délimité), corriger le template ou `generate.sh`,
  réessayer.

### 5.4 Boucle de correction

Maximum **3 itérations**. À chaque itération :

1. Afficher le diff à l'utilisateur.
2. Proposer une correction.
3. Demander confirmation (use question tool).
4. Appliquer la correction.
5. Relancer `generate.sh` + `diff`.

Après 3 itérations sans succès → signaler à l'utilisateur les diffs restants
et demander comment procéder.

### 5.5 Succès

Quand le diff est vide (hors `.jinja`), l'agent annonce :

> *« Validation réussie : le template régénère le projet source à
> l'identique. »*

---

## Phase 6 — Génération du SKILL.md

**Objectif** : produire le skill consommateur qui permettra de créer de
nouveaux projets à partir du template.

### 6.1 Structure obligatoire

Le SKILL.md doit suivre la structure de `sklein-create-node-pg-project/SKILL.md` :

1. **Frontmatter** (`name`, `description`)
2. **Titre et description** du skill
3. **Déclencheur** — quand activer ce skill
4. **Collecte des informations** — questions à poser à l'utilisateur
5. **Paramètres** — variables attendues
6. **Récupération automatique** (si applicable)
7. **Génération des fichiers via generate.sh** — instructions d'exécution
8. **Arrêt strict après initialisation**
9. **Confirmation finale**

### 6.2 Génération des sections

#### Déclencheur

L'agent rédige des exemples de phrases déclencheuses adaptées au type de
projet. Exemple pour un projet Node.js + PostgreSQL :

> - "crée un projet node avec PostgreSQL"
> - "crée un projet node + pg"

#### Collecte des informations

Pour chaque variable identifiée en phase 1 (hors variables de base), l'agent
génère une question conditionnelle.

Exemple pour `use_jujutsu` :

> ### Question sur Jujutsu
>
> L'agent doit demander à l'utilisateur (use question tool) :
>
> > *« Utiliserez-vous Jujutsu (jj) pour ce projet ? (Oui/Non) »*
>
> - Si **Oui** : `USE_JUJUTSU = true`
> - Si **Non** : `USE_JUJUTSU = false`

Pour les variables de version récupérées dynamiquement, l'agent doit demander
à l'utilisateur la méthode de récupération (use question tool) :

> *« Comment récupérer `last_node_lts_version` à l'avenir ? »*
> Options proposées :
> - "API nodejs.org (dernière LTS)"
> - "Valeur fixe fournie par l'utilisateur"
> - "Autre (à décrire)"

Si l'utilisateur choisit une API, l'agent génère les instructions `curl`/`jq`
correspondantes.

Si l'utilisateur ne sait pas ou choisit "Valeur fixe", le SKILL.md demandera
simplement la valeur à l'utilisateur lors de la création de projet.

#### Paramètres

Lister toutes les variables avec leur description et si elles sont requises
ou optionnelles.

#### Récupération automatique

Si des variables de version ont une méthode de récupération API documentée,
l'inclure ici avec les commandes exactes.

#### Génération via generate.sh

```markdown
## Génération des fichiers via generate.sh

1. **Créer un fichier YAML temporaire** `/tmp/opencode/vars.yaml` :
   ```yaml
   author_name: Stéphane Klein
   project_name: "{{PROJECT_NAME}}"
   ...
   ```

2. **Exécuter generate.sh** :
   ```bash
   <PATH_TO_TEMPLATE>/generate.sh \
     <PATH_TO_TEMPLATE> \
     /tmp/opencode/vars.yaml \
     "{{TARGET_DIR}}"
   ```

3. **Supprimer** le fichier temporaire après exécution.
```

Adapter les chemins et les variables.

#### Arrêt strict

Inclure la section standard :

```markdown
## Arrêt strict après initialisation

**Ce skill a un périmètre strict : initialiser le projet et rien d'autre.**
...
```

### 6.3 Sauvegarde

Écrire le SKILL.md dans le dossier du template (à côté de `generate.sh` et
`vars-example.yaml`).

### 6.4 Vérification

L'agent affiche le contenu du SKILL.md généré et demande :

> *« Le SKILL.md vous convient-il ? Voulez-vous modifier quelque chose ? »*

---

## Récapitulatif final

À la fin des 6 phases, le dossier template contient :

```
<template_dir>/
├── .jinja/                    # Fichiers templatisés
│   ├── package.json.jinja
│   ├── README.md.jinja
│   └── ...
├── <fichiers statiques>       # Fichiers copiés tels quels
│   ├── compose.yaml
│   ├── Containerfile
│   └── ...
├── generate.sh                # Script de génération
├── vars-example.yaml          # Exemple de variables
└── SKILL.md                   # Skill consommateur
```

L'agent confirme le succès à l'utilisateur en listant tous les fichiers créés
et leur emplacement.

## Règles générales

- **Ne jamais sauter de phase** — chaque phase produit un résultat vérifiable.
- **Confirmation utilisateur entre chaque phase** — ne pas enchaîner sans
  accord explicite.
- **Maximum 3 itérations** pour la boucle de correction en phase 5.
- **Tous les fichiers générés** (`generate.sh`, `vars-example.yaml`,
  `SKILL.md`) sont écrits par l'agent (pas par un script externe).
- Les fichiers `.jinja` utilisent la syntaxe Jinja2 standard
  (`{{ var }}`, `{% if var %}`, `{% endif %}`).
- Les noms de variables sont en `snake_case`.
