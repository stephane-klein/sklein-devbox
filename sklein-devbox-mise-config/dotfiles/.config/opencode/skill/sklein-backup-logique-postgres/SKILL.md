---
name: sklein-backup-logique-postgres
description: Backup logique PostgreSQL avec pg_back-docker-sidecar — pg_dump -Fc vers S3 avec chiffrement age, rétention configurable et scheduling cron. Utiliser quand l'utilisateur demande à mettre en place un backup logique PostgreSQL, une sauvegarde pg_dump vers S3/Object Storage, ou déployer pg_back.
---

# sklein-backup-logique-postgres

Backup logique PostgreSQL avec [`pg_back`](https://github.com/orgrim/pg_back/) via l'image [`stephaneklein/pg_back-docker-sidecar`](https://github.com/stephane-klein/pg_back-docker-sidecar).

## Principes

- **Format** : `pg_dump -Fc` (custom, compressé) — compatible `pg_restore`
- **Chiffrement** : optionnel avec [age](https://age-encryption.org/)
- **Stockage** : S3-compatible (Scaleway, MinIO, AWS…)
- **Scheduling** : supercronic intégré dans l'image
- **Rétention** : purge automatique locale et distante (`purge_older_than`, `purge_min_keep`)
- **Nettoyage** : suppression des fichiers locaux après upload (`--delete-local-file-after-upload`)

## Image

```
stephaneklein/pg_back-docker-sidecar
```

Disponible sur [Docker Hub](https://hub.docker.com/repository/docker/stephaneklein/pg_back-docker-sidecar/general).

### Versions PostgreSQL supportées

La variable `POSTGRES_VERSION` sélectionne le binaire pg_dump :

| POSTGRES_VERSION | Image pg_dump utilisée |
|---|---|
| `15` | postgres:15 |
| `16` | postgres:16 |
| `17` | postgres:17 |

### Tags de l'image

| Tag | Description |
|---|---|
| `latest` | Dernière version postgres:17 |
| `2.5.0-delete-local-file-after-upload` | Version stable avec suppression fichiers locaux après upload |

## Variables d'environnement

### Connexion PostgreSQL

| Variable | Défaut | Description |
|---|---|---|
| `POSTGRES_VERSION` | `17` | Version du binaire pg_dump |
| `POSTGRES_HOST` | — | Hôte PostgreSQL |
| `POSTGRES_PORT` | — | Port PostgreSQL |
| `POSTGRES_USER` | — | Utilisateur |
| `POSTGRES_PASSWORD` | — | Mot de passe |
| `POSTGRES_DB` | valeur de `POSTGRES_DBNAME` | Base de données à dumper |

### Backup

| Variable | Défaut | Description |
|---|---|---|
| `BACKUP_CRON` | — | Expression cron pour supercronic (ex: `0 3 * * *`) |
| `BACKUP_DIRECTORY` | `/var/backups/postgresql` | Répertoire des archives locales |
| `PG_DUMP_FORMAT` | `custom` | Format pg_dump (custom, plain, tar, directory) |
| `PG_DUMP_COMPRESS_LEVEL` | `-1` | Niveau de compression (0-9, -1 = défaut) |
| `INCLUDE_DBS` | `""` | Bases à inclure (séparateur virgule) |
| `EXCLUDE_DBS` | `""` | Bases à exclure (séparateur virgule) |
| `DUMP_ONLY` | `false` | Dumper uniquement les bases (sans globals/config) |

### Upload S3

| Variable | Défaut | Description |
|---|---|---|
| `UPLOAD` | `none` | Mode upload : `none`, `s3`, `sftp`, `gcs` |
| `UPLOAD_PREFIX` | `""` | Préfixe (dossier) dans le bucket |
| `S3_KEY_ID` | — | Access Key ID |
| `S3_SECRET` | — | Secret Access Key |
| `S3_ENDPOINT` | — | Endpoint S3 (ex: `https://s3.fr-par.scw.cloud`) |
| `S3_REGION` | — | Région (ex: `fr-par`) |
| `S3_BUCKET` | — | Nom du bucket |
| `S3_FORCE_PATH` | `false` | Forcer le path-style |
| `S3_TLS` | `true` | Activer TLS |

### Chiffrement (age)

| Variable | Défaut | Description |
|---|---|---|
| `ENCRYPT` | `false` | Activer le chiffrement avec age |
| `AGE_CIPHER_PUBLIC_KEY` | — | Clé publique age (format `age1...`) |
| `AGE_CIPHER_PRIVATE_KEY` | — | Clé privée age (format `AGE-SECRET-KEY-1...`) |

### Rétention et purge

| Variable | Défaut | Description |
|---|---|---|
| `PURGE_OLDER_THAN` | `30` | Supprimer les dumps plus vieux que (jours, heures, minutes…) |
| `PURGE_MIN_KEEP` | `0` | Nombre minimum de dumps à toujours conserver |
| `PURGE_REMOTE` | `false` | Purger aussi les fichiers distants S3 |

### Divers

| Variable | Défaut | Description |
|---|---|---|
| `DISABLE_CRON` | `false` | Désactiver supercronic (utile pour restore uniquement) |
| `JOBS` | `1` | Nombre de pg_dump concurrents |

## Référence

Toutes les variables sont documentées dans le template de configuration :
[`pg_back.conf.tmpl`](https://github.com/stephane-klein/pg_back-docker-sidecar/blob/main/pg_back.conf.tmpl)

Note de contexte : https://notes.sklein.xyz/2025-04-14_1737/zen/

## Workflows

### Déploiement Docker Compose

```yaml
services:
  pg_back:
    image: stephaneklein/pg_back-docker-sidecar
    restart: no
    environment:
      POSTGRES_VERSION: "18"
      POSTGRES_HOST: postgres1
      POSTGRES_PORT: 5432
      POSTGRES_USER: hindsight
      POSTGRES_DB: hindsight
      POSTGRES_PASSWORD: "${POSTGRES_PASSWORD}"

      BACKUP_CRON: "0 0 * * *"
      UPLOAD: "s3"
      UPLOAD_PREFIX: "hindsight"

      S3_KEY_ID: "${S3_KEY_ID}"
      S3_SECRET: "${S3_SECRET}"
      S3_ENDPOINT: "https://s3.fr-par.scw.cloud"
      S3_REGION: "fr-par"
      S3_BUCKET: "homelab-cnpg-backups"
      S3_FORCE_PATH: "false"
      S3_TLS: "true"

      PURGE_OLDER_THAN: "7"
      PURGE_REMOTE: "true"

      ENCRYPT: "true"
      AGE_CIPHER_PUBLIC_KEY: "${AGE_PUBLIC_KEY}"
      AGE_CIPHER_PRIVATE_KEY: "${AGE_PRIVATE_KEY}"
```

### Déploiement Kubernetes (CronJob)

Pour utiliser l'image dans un CronJob Kubernetes :

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: hindsight-logical-backup
  namespace: hindsight
spec:
  schedule: "0 0 * * *"
  jobTemplate:
    spec:
      template:
        spec:
          restartPolicy: OnFailure
          containers:
            - name: pg-back
              image: stephaneklein/pg_back-docker-sidecar
              env:
                - name: POSTGRES_HOST
                  value: "hindsight-cnpg-rw.hindsight.svc.cluster.local"
                - name: POSTGRES_PORT
                  value: "5432"
                - name: POSTGRES_USER
                  value: "hindsight"
                - name: POSTGRES_DB
                  value: "hindsight"
                - name: POSTGRES_PASSWORD
                  valueFrom:
                    secretKeyRef:
                      name: hindsight-cnpg-cluster-app
                      key: password
                - name: BACKUP_CRON
                  value: "0 0 * * *"
                - name: UPLOAD
                  value: "s3"
                - name: UPLOAD_PREFIX
                  value: "hindsight"
                - name: S3_ENDPOINT
                  value: "https://s3.fr-par.scw.cloud"
                - name: S3_REGION
                  value: "fr-par"
                - name: S3_BUCKET
                  value: "homelab-cnpg-backups"
                - name: S3_FORCE_PATH
                  value: "false"
                - name: S3_TLS
                  value: "true"
                - name: PURGE_OLDER_THAN
                  value: "7"
                - name: PURGE_REMOTE
                  value: "true"
                - name: DISABLE_CRON
                  value: "true"
                - name: S3_KEY_ID
                  valueFrom:
                    secretKeyRef:
                      name: cnpg-backup-credentials
                      key: accessKey
                - name: S3_SECRET
                  valueFrom:
                    secretKeyRef:
                      name: cnpg-backup-credentials
                      key: secretKey
```

> **Note** : `DISABLE_CRON=true` car CronJob gère le scheduling. Chaque exécution du CronJob lance un dump unique sans supercronic.

### Restauration

Télécharger une archive depuis S3 et la restaurer :

```bash
# Lister les snapshots distants
pg_back --list-remote s3

# Restaurer via pg_back (télécharge, déchiffre, importe)
pg_back --restore s3://bucket/prefix/TIMESTAMP

# Ou manuellement
aws s3 cp s3://bucket/prefix/postgres_TIMESTAMP.dump.age .
age --decrypt -i key.txt -o postgres_TIMESTAMP.dump postgres_TIMESTAMP.dump.age
pg_restore -h target-host -U user -d target-db --no-owner postgres_TIMESTAMP.dump
```

### Rétention

La purge est configurée par `PURGE_OLDER_THAN` :

| Valeur | Effet |
|---|---|
| `7` | Garder les dumps de moins de 7 jours |
| `30` | Garder les dumps de moins de 30 jours |
| `14d` | 14 jours (format avec unité) |
| `48h` | 48 heures |

Combiner avec `PURGE_MIN_KEEP` pour toujours garder au moins N dumps, même s'ils sont plus vieux que `PURGE_OLDER_THAN`.

Activer `PURGE_REMOTE: "true"` pour purger aussi les fichiers distants sur S3.

## Références

- [pg_back](https://github.com/orgrim/pg_back/) — outil de backup PostgreSQL
- [pg_back-docker-sidecar](https://github.com/stephane-klein/pg_back-docker-sidecar) — image Docker et tutoriel
- [Note de contexte](https://notes.sklein.xyz/2025-04-14_1737/zen/)
- [Homelab.sklein.xyz](https://github.com/stephane-klein/homelab.sklein.xyz) — exemple d'intégration
