# sklein-named-volume-doctrine — Référence

## Contexte historique

Stéphane a utilisé des *volume mounts* (bind mounts) de 2015 à 2024 pour éviter les collisions de noms :

```yaml
volumes:
  - ./volumes/postgres/:/var/lib/postgresql/data/
```

**Avantages** : pas de collision, suppression avec `rm -rf`, inspection directe.

**Inconvénients** : permissions root sous Linux, `docker compose down -v` ne les détruit pas, non mainstream.

En décembre 2024, il adopte les *named volumes* avec une convention de nommage anti-collision, décrite sur [notes.sklein.xyz](https://notes.sklein.xyz/2024-12-09_1550/zen/) et testée dans [docker-named-volume-playground](https://github.com/stephane-klein/docker-named-volume-playground).

## Compatibilité Docker / Podman

La convention est identique pour Docker et Podman. La seule différence :

- Docker : `docker compose up -d`
- Podman : `podman compose up -d` (ou `podman-compose`)

Le fichier `compose.yaml` et `mise.toml` sont interchangeables.

## Pourquoi Mise plutôt que direnv

| Aspect | direnv (.envrc) | Mise (mise.toml) |
|--------|-----------------|-------------------|
| Évaluation | script shell exécuté à chaque `cd` | templates Tera avec `hash` filter |
| INSTANCE_ID | `$(pwd | sha1sum \| awk '{print $1}' \| cut -c 1-12)` | `{{ cwd \| hash(algorithm='sha256', len=12) }}` |
| Dépendance | `sha1sum` (GNU coreutils) ou `shasum` (Perl) | Aucune (filter natif Mise) |
| Algo de hash | SHA-1 | SHA-256 (ou BLAKE3) |
| Portable | Oui (mais commande différente selon OS) | Oui (Mise gère l'abstraction) |

## Exemples par service

### PostgreSQL

```yaml
services:
  postgres:
    image: postgres:17
    volumes:
      - postgres:/var/lib/postgresql/data/

volumes:
  postgres:
    name: ${COMPOSE_PROJECT_NAME}_postgres
```

### Redis

```yaml
services:
  redis:
    image: redis:7
    volumes:
      - redis:/data/

volumes:
  redis:
    name: ${COMPOSE_PROJECT_NAME}_redis
```

### MinIO

```yaml
services:
  minio:
    image: minio/minio
    volumes:
      - minio:/data/

volumes:
  minio:
    name: ${COMPOSE_PROJECT_NAME}_minio
```

## Migration : `.envrc` → `mise.toml`

### Avant (direnv)

```bash
# .envrc
export PROJECT_NAME="mon-projet"
export INSTANCE_ID=$(pwd | sha1sum | awk '{print $1}' | cut -c 1-12)
export COMPOSE_PROJECT_NAME=${PROJECT_NAME}_${INSTANCE_ID}
```

### Après (Mise)

```toml
# mise.toml
[env]
PROJECT_NAME = "mon-projet"
INSTANCE_ID = "{{ cwd | hash(algorithm='sha256', len=12) }}"
COMPOSE_PROJECT_NAME = "{{ env.PROJECT_NAME }}_{{ env.INSTANCE_ID }}"
```

### Vérification

```bash
$ mise env | grep -E '(PROJECT_NAME|INSTANCE_ID|COMPOSE_PROJECT_NAME)'
```

## Intégration avec les autres skills

Le template existant dans `sklein-create-node-pg-project` utilise déjà cette convention (via `.envrc.jinja`). À terme, ces templates devraient être migrés vers Mise — mais ce skill est générique et s'applique à tout projet, pas seulement Node.js.
