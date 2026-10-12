# sklein-generate-project-template SKILL

Méta-outil de génération de templates de projet à partir d'un code source
existant. Produit automatiquement un dossier `template/`, un script
`generate.sh`, un `vars-example.yaml` et le SKILL qui permet ensuite de générer des projets à partir du template.

Le script `generate.sh` généré suit l'approche décrite dans
[`sklein-raw-template-script`](https://github.com/stephane-klein/sklein-devbox-chezmoi/tree/main/dot_config/opencode/skill/sklein-raw-template-script)
(script shell brut + minijinja-cli, sans framework complexe).

Le workflow complet est documenté dans [`SKILL.md`](SKILL.md).

## Exemples de templates générés

- [`sklein-create-node-project`](https://github.com/stephane-klein/sklein-devbox-chezmoi/tree/main/dot_config/opencode/skill/sklein-create-node-project)
- [`sklein-create-node-pg-project`](https://github.com/stephane-klein/sklein-devbox-chezmoi/tree/main/dot_config/opencode/skill/sklein-create-node-pg-project)

## Prérequis

- [opencode](https://opencode.ai)
- `minijinja-cli` et `yq` — disponibles via `mise install` (cf. [`.mise.toml`](.mise.toml))

## Utilisation

```bash
$ ./generate-template-from.sh <chemin_du_projet_source> [chemin_de_sortie_du_template]
```

Exemple :

```bash
$ ./generate-template-from.sh ./source ./target/
```

Le script lance OpenCode en mode TUI avec la SKILL, qui guide à travers
6 phases : analyse → génération du template → vars → generate.sh →
validation → SKILL.md.

## Structure produite

```
<template_dir>/
├── template/              # Fichiers Jinja et statiques
├── generate.sh            # Script bash de génération
├── vars-example.yaml      # Exemple de variables
└── SKILL.md               # Skill de génération de projet
```
