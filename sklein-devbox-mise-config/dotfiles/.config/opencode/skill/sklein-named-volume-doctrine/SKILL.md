---
name: sklein-named-volume-doctrine
description: >
  Convention de nommage des volumes nommés Docker/Podman pour éviter
  les collisions entre projets et instances via un hash du chemin absolu
  dans Mise. Utiliser lors de toute création ou audit de projet avec
  compose.yaml et volumes nommés.
---

# sklein-named-volume-doctrine

## Déclencheurs

- "ajoute un volume nommé"
- "configure les named volumes"
- "migre les bind mounts vers des named volumes"
- "applique la doctrine de nommage des volumes"
- tout projet contenant un `compose.yaml` avec des volumes nommés

## La convention

Deux fichiers à créer ou patcher :

### `mise.toml`

```toml
[env]
PROJECT_NAME = "<project_slug>"
INSTANCE_ID = "{{ cwd | hash(algorithm='sha256', len=12) }}"
COMPOSE_PROJECT_NAME = "{{ env.PROJECT_NAME }}_{{ env.INSTANCE_ID }}"
```

`PROJECT_NAME` est une valeur fixe (ex: `"mon-projet"`).
Alternative possible : `"{{ cwd | basename }}"` si le nom du dossier correspond au nom du projet.

### `compose.yaml`

```yaml
volumes:
  <service_name>:
    name: ${COMPOSE_PROJECT_NAME}_<service_name>
```

Répéter pour chaque service qui nécessite un volume persistant (postgres, redis, minio, etc.).

## Modes

### EXPLAIN

L'agent explique la doctrine sans modifier les fichiers :

1. Le problème : les collisions de noms de volumes entre projets/instances
2. La solution : `INSTANCE_ID` = hash SHA-256 du chemin absolu (12 chars) + `COMPOSE_PROJECT_NAME` = `<projet>_<hash>`
3. Le volume est nommé `${COMPOSE_PROJECT_NAME}_<service>`, garantissant l'unicité
4. Mise évalue les templates Tera à chaque `cd`, donc `INSTANCE_ID` est recalculé automatiquement

### APPLY

L'agent crée ou patch les fichiers du projet courant.

Si `mise.toml` n'existe pas :

1. Créer `mise.toml` avec la section `[env]` ci-dessus
2. Remplacer `<project_slug>` par le nom du projet (demander à l'utilisateur si ambigu)

Si `mise.toml` existe mais sans `[env]` :

1. Ajouter la section `[env]` à la fin du fichier

Si `compose.yaml` n'existe pas :

1. Prévenir l'utilisateur et s'arrêter (hors périmètre)

Si `compose.yaml` existe :

1. Pour chaque service avec volume, ajouter `name: ${COMPOSE_PROJECT_NAME}_<service>` dans la section `volumes:`
2. Si la section `volumes:` n'existe pas, la créer

### VÉRIFIER (audit)

L'agent analyse un projet existant :

1. `mise.toml` contient-il `INSTANCE_ID`, `PROJECT_NAME`, `COMPOSE_PROJECT_NAME` ?
2. `compose.yaml` utilise-t-il `name: ${COMPOSE_PROJECT_NAME}_<service>` pour chaque volume nommé ?
3. Signaler les écarts sans modifier les fichiers

## Migration depuis direnv / `.envrc`

Si le projet a un `.envrc` mais pas de `mise.toml` :

1. Créer `mise.toml` avec la convention
2. Laisser l'utilisateur décider de supprimer `.envrc` et `direnv`

## Références

- [Billet d'origine sur notes.sklein.xyz](https://notes.sklein.xyz/2024-12-09_1550/zen/)
- [Repository docker-named-volume-playground](https://github.com/stephane-klein/docker-named-volume-playground)
- [Template existant dans sklein-create-node-pg-project](file:///home/sklein/.config/opencode/skill/sklein-create-node-pg-project/template/)
