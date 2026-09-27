---
name: sklein-raw-template-script
description: Génère un script generate.sh en shell brut + minijinja (sans framework complexe type Cookiecutter) à partir d'un dossier template contenant des fichiers .jinja, des fichiers statiques et un vars-example.yaml. Use when user wants to create a generate.sh script from a template directory with .jinja files, static files, and vars-example.yaml.
---

# sklein-raw-template-script

Génère un script `generate.sh` dans un dossier template.

## Déclencheur

Ce skill est activé lorsque l'utilisateur demande de générer un `generate.sh` à partir d'un dossier template contenant des `.jinja`, par exemple :

- « génère le generate.sh à partir de ce template »
- « crée un script de génération pour ce dossier template »

## Workflow

1. **Demander le chemin du dossier template** à l'utilisateur (chemin absolu).
2. **Scanner le dossier** récursivement :
   - Lister tous les fichiers `.jinja`
   - Lister tous les fichiers sans `.jinja` (exclure `vars-example.yaml`)
3. **Vérifier la présence de `.jinja`** :
   - Si **aucun** fichier `.jinja` n'est trouvé → afficher un **warning** et s'arrêter.
4. **Générer `generate.sh`** dans le dossier template avec :

   ```bash
   #!/bin/bash
   set -euo pipefail

   template_dir="${1%/}"
   vars_file="$2"
   target_dir="${3%/}"

   mkdir -p "$target_dir"
   ```

   Puis pour chaque fichier **statique** (trié alphabétiquement) :

   ```bash

   mkdir -p "$target_dir/<sous-dossier>"  # si nécessaire
   cp "$template_dir/<chemin>" "$target_dir/<chemin>"
   ```

   Puis pour chaque fichier **`.jinja`** (trié alphabétiquement) :

   ```bash
   mkdir -p "$target_dir/<sous-dossier>"  # si nécessaire
   minijinja-cli "$template_dir/<chemin>.jinja" "$vars_file" > "$target_dir/<chemin>"
   ```

   Puis un bloc **commenté** d'exemple conditionnel :

   ```bash
   # Example of conditional template rendering:
   # include_gopass_setup_secret=$(yq '.include_gopass_setup_secret' "$vars_file")
   # if [ "$include_gopass_setup_secret" = "true" ]; then
   #   mkdir -p "$target_dir/scripts"
   #   minijinja-cli "$template_dir/scripts/generate-secret.sh.jinja" "$vars_file" > "$target_dir/scripts/generate-secret.sh"
   # fi
   ```

5. **Rendre `generate.sh` exécutable** : `chmod +x generate.sh`.
6. **Confirmer** les fichiers pris en compte (`.jinja` et statiques).

## Règles

- Trier les fichiers alphabétiquement dans `generate.sh`.
- Le nom du fichier de sortie d'un `.jinja` est obtenu en **retirant** l'extension `.jinja` (ex: `package.json.jinja` → `package.json`).
- Ignorer `vars-example.yaml` dans le listing (ni copié, ni templatisé).
- Les `mkdir -p` sont dédoublonnés : un seul `mkdir -p` par sous-dossier, avant les `cp`/`minijinja-cli` qui y écrivent.
