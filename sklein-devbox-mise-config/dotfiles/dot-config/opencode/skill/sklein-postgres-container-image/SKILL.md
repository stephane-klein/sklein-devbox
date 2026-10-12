---
name: sklein-postgres-container-image
description: >
  Stéphane préfère les images PostgreSQL basées **Debian** aux images Alpine,
  sauf contrainte explicite d'un projet dont il n'est pas l'auteur.
---

# sklein-postgres-container-image

## Règle

Par défaut, utiliser l'image officielle `postgres` (Debian) pour tout
conteneur PostgreSQL.

Ne déroger que si le projet concerné impose Alpine (Dockerfile existant,
contrainte de taille d'image documentée, politique d'équipe) et que
Stéphane n'en est pas l'auteur.

## Justification

- **glibc vs musl** — PostgreSQL est développé et testé sur glibc. musl
  peut causer des bugs subtils (locales, regex, tri Unicode).
- **Extensions** — PostGIS, pgvector, TimescaleDB sont buildées/testées
  sur glibc. Sur Alpine, compilation manuelle et résultats incertains.
- **Outils de debug** — Debian embarque bash, procps, strace, perf, eBPF.
- **Sécurité** — Debian a un processus de sécurité éprouvé et réactif.

## Quand déroger

- Projet dont Stéphane n'est pas l'auteur et qui utilise Alpine → suivre
  la convention du projet.
- Contrainte de taille d'image critique et documentée → Alpine peut se
  justifier, mais c'est l'exception.

## Références

- Image officielle `postgres` sur Docker Hub : basée Debian par défaut.
- https://wiki.postgresql.org/ — recommandations officielles.
