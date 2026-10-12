# sklein-http-api

## Parcours personnel

J'ai commencé à concevoir des API REST en **2008**, puis les SPAs en **2011**.
De **2019 à 2023**, j'ai utilisé GraphQL avec Postgraphile en production.
J'ai ensuite adopté le **SSR avec SvelteKit** et complètement abandonné GraphQL
pour les apps web — le SSR rend l'API REST superflue pour ce cas.

Aujourd'hui, je ne crée d'API HTTP que quand c'est nécessaire :
API publique, client mobile, B2B, contribution à un projet existant.

Les conventions de ce skill sont le fruit de cette expérience.

## Doctrine

Ces deux articles ne définissent pas *comment* je conçois mes API,
mais *quand* j'en crée une et *quoi* j'expose :

- [Server-Informed UI](https://max.engineer/server-informed-ui) — Max Chernyak (2021)
- [Server-Informed UI — 4 years later](https://max.engineer/server-informed-ui-p2) (2025)

Le principe s'applique à deux niveaux :

- **App web (SSR ou SPA)** — backend et frontend font partie du même projet.
  Les données sont chargées côté serveur ou servies par des endpoints
  conçus pour les besoins d'affichage, pas pour un client générique
  (Server-Informed UI).
- **General Purpose API** — API exposée à des clients externes :
  API publique, mobile, scripts/outils, B2B. Les conventions du SKILL.md
  s'appliquent dans ce cas.

Depuis 2022, je suis en SSR avec SvelteKit pour mes apps.
Le cas General Purpose API reste valide dès qu'un outil ou un client
externe accède aux données.

## Approche

Les conventions du SKILL.md suivent un style **REST pragmatique** :

- Pas de purisme : HATEOAS partiel (juste `_links` utiles),
  pas de JSON:API strict (pas de bloc `included` séparé, pas de
  namespace `filter[...]`).
- Standards choisis : RFC 9457 pour les erreurs, OpenAPI obligatoire,
  cursor-based pagination, ISO 8601 avec timezone.
- Simplicité d'abord : pas de sur-engineering, upload direct multipart,
  actions non-CRUD en `POST /{id}/{action}`.
