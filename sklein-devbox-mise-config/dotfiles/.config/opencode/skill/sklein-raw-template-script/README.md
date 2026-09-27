# Rationnel : bash + minijinja-cli pour la génération de projet depuis un template

## Contexte

L'objectif est de générer des projets depuis des templates, de manière non-interactive, en passant les variables via un fichier YAML.

## Pourquoi pas Copier

[Copier](https://copier.readthedocs.io) est l'outil le plus abouti dans la catégorie scaffolding avec cycle de vie. Son algorithme de 3-way merge pour les mises à jour de projets existants est unique dans l'écosystème.

Mais sa gestion de la conditionnalité des fichiers ne me convient pas. Elle passe par le nom de fichier lui-même :

```
{% if use_typescript %}tsconfig.json{% endif %}
```

Je trouve cette syntaxe illisible dans un listing de répertoire et difficile à maintenir. Ce n'est pas un détail contournable — c'est constitutif du design de Copier.

## Pourquoi pas un outil existant

J'ai exploré les écosystèmes Python, Rust et Go sans trouver d'outil qui me convienne pleinement.

En Python, Copier est le plus abouti mais éliminé pour la raison évoquée ci-dessus. Cookiecutter n'a pas de conditionnalité de fichiers propre. Cruft est un wrapper au-dessus de cookiecutter qui hérite de ses limitations.

En Rust, les outils se répartissent en deux catégories qui ne couvrent pas le besoin : des renderers fichier par fichier sans logique de scaffolding (minijinja-cli, shinkansen), ou des scaffolders sans templating Jinja2 fidèle (skeletor, cargo-generate, kickstart).

En Go, les outils de scaffolding existants sont généralement couplés à un framework ou à un écosystème spécifique, pas à un usage généraliste.

## Choix retenu : bash + minijinja-cli

Un script bash gère la structure (quels fichiers générer, dans quels dossiers, conditionnalité explicite). `minijinja-cli` gère le rendu de chaque fichier template. Les variables multiline passent naturellement via YAML. `minijinja-cli` est un binaire Rust autonome, du même auteur que Jinja2 (mitsuhiko), avec une fidélité maximale à la syntaxe.

Voici un exemple représentatif :

```bash
#!/bin/bash
set -euo pipefail

template_dir="${1%/}"
vars_file="$2"
target_dir="${3%/}"

mkdir -p "$target_dir"

include_gopass_setup_secret=$(yq '.include_gopass_setup_secret' "$vars_file")

cp "$template_dir/.gitignore" "$target_dir/.gitignore"

cp "$template_dir/.secret.example" "$target_dir/.secret.example"

minijinja-cli "$template_dir/.mise.toml.jinja" "$vars_file" > "$target_dir/.mise.toml"
minijinja-cli "$template_dir/AGENTS.md.jinja" "$vars_file" > "$target_dir/AGENTS.md"
minijinja-cli "$template_dir/NEXT_STEPS.md.jinja" "$vars_file" > "$target_dir/NEXT_STEPS.md"
minijinja-cli "$template_dir/README.md.jinja" "$vars_file" > "$target_dir/README.md"
minijinja-cli "$template_dir/package.json.jinja" "$vars_file" > "$target_dir/package.json"

if [ "$include_gopass_setup_secret" = "true" ]; then
  mkdir -p "$target_dir/scripts"
  minijinja-cli "$template_dir/scripts/generate-secret.sh.jinja" "$vars_file" > "$target_dir/scripts/generate-secret.sh"
fi
```

Le script est volontairement verbeux : chaque fichier est listé explicitement, sans `find` ni traversée automatique de répertoire. C'est un choix fort pour la lisibilité et la simplicité — on voit d'un coup d'œil ce que le script génère. `find` resterait une option si le nombre de fichiers devenait vraiment important, mais les templates que je souhaite gérer restent petits par nature.
