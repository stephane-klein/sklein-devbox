# Pourquoi Debian plutôt qu'Alpine pour PostgreSQL ?

## Constat

Je n'ai personnellement jamais rencontré de problème avec les images Alpine
de PostgreSQL. Mon choix du Debian n'est pas une réaction à un incident vécu.

C'est un choix préventif, basé sur l'observation de l'écosystème.

## Rationnel

- **L'image officielle `postgres` est basée Debian.** C'est le chemin de
  moindre résistance et celui qui est le plus massivement testé par la
  communauté.
- **Les extensions PostgreSQL (PostGIS, pgvector, TimescaleDB…) sont
  buildées et testées sur glibc.** Sur Alpine (musl), des bugs subtils
  peuvent apparaître — notamment sur les locales, le tri Unicode, et les
  expressions régulières.
- **CloudNativePG** (l'opérateur PostgreSQL de référence sur Kubernetes)
  utilise des images Debian par défaut. C'est un signal fort sur ce qui
  est considéré comme le standard de production.
- **Les outils de debug et de profiling** (strace, perf, eBPF) sont mieux
  supportés sur glibc.

## Taille d'image

J'ai bien conscience que Alpine est significativement plus légère
(~50-60 Mo contre ~150-200 Mo pour Debian).

## Quand déroger

Si un projet dont je ne suis pas l'auteur impose Alpine, je suis la
convention du projet sans discussion.
