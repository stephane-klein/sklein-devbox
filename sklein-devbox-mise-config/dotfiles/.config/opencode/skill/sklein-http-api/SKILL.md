---
name: sklein-http-api
description: Conventions HTTP API de Stéphane Klein — nommage, verbes, codes, pagination, erreurs, versioning, HATEOAS, filtres, embedding, upload, OpenAPI. Utiliser lors de la création, modification ou review d'une API HTTP.
---

# sklein-http-api

## Déclencheur

Ce skill est activé lorsque l'utilisateur travaille sur une API HTTP :

- Créer une nouvelle API HTTP
- Ajouter ou modifier un endpoint
- Review de code d'une API HTTP
- Discuter de design d'API (pagination, erreurs, versioning, nommage)

## Paradigme

Stéphane distingue trois contextes :

**1. App web en SSR (SvelteKit)** — pas d'API REST.
Les données sont chargées côté serveur (`load` functions, `+page.server.ts`).

**2. SPA avec backend dédié** — API [Server-Informed UI](https://max.engineer/server-informed-ui).
Les endpoints sont conçus par page/screen, pas par ressource CRUD abstraite.
Le backend prépare et sert les données nécessaires à l'affichage.
Ce n'est pas une General Purpose API.

**3. General Purpose API** — API exposée à des clients externes
(API publique, client mobile, scripts/outils, B2B,
contribution à un projet existant).
**Les règles ci-dessous s'appliquent dans ce contexte uniquement.**

Depuis 2022, Stéphane utilise le SSR (cas 1) pour ses apps web.
Le cas 3 reste valide dès qu'un outil ou un client externe
a besoin d'accéder aux données.

## Règles

### Règle 1 : Nommage des ressources

- URLs en **kebab-case** et **pluriel** : `/api/v1/articles`, `/api/v1/articles/123/comments`
- Paramètres de requête en **snake_case** : `?page_size=20&sort_by=created_at`
- Champs JSON dans le body en **snake_case** : `{"user_id": 42, "created_at": "…"}`
- Identifiants de ressources : utiliser l'identifiant public exposé (NanoID ou slug), jamais la PK interne (cf. [`sklein-sql-generation`](../sklein-sql-generation/) règle 6).

### Règle 2 : Méthodes HTTP

| Ressource | GET | POST | PUT | PATCH | DELETE |
|---|---|---|---|---|---|
| `/articles` | Liste paginée | Création | — | — | — |
| `/articles/{id}` | Lecture | — | Remplacement total | Modification partielle | Suppression |

- `PUT` = remplacement complet de la ressource. Tous les champs obligatoires doivent être fournis.
- `PATCH` = mise à jour partielle. Seuls les champs modifiés sont envoyés.
- `POST` sur une collection = création. Sur un endpoint d'action = opération non-CRUD (`/articles/{id}/publish`).
- Pas de verbe dans l'URL. Utiliser la méthode HTTP.

### Règle 3 : Codes HTTP

| Situation | Code |
|---|---|
| GET / PUT — succès | `200 OK` |
| POST — création | `201 Created` (+ header `Location`) |
| DELETE — succès | `204 No Content` |
| Requête malformée | `400 Bad Request` |
| Authentification absante/invalide | `401 Unauthorized` |
| Action interdite (même authentifié) | `403 Forbidden` |
| Ressource introuvable | `404 Not Found` |
| Conflit (doublon, version) | `409 Conflict` |
| Validation métier | `422 Unprocessable Entity` |
| Erreur serveur inattendue | `500 Internal Server Error` |

### Règle 4 : Format d'erreur

Toutes les erreurs suivent [RFC 9457](https://www.rfc-editor.org/rfc/rfc9457) (`application/problem+json`) :

```json
{
  "type": "https://api.example.com/errors/validation-error",
  "title": "Validation Error",
  "status": 422,
  "detail": "Le champ email est requis",
  "instance": "/api/v1/users",
  "errors": [
    {
      "field": "email",
      "message": "doit être une adresse email valide"
    }
  ]
}
```

- `type` : URI vers la documentation de l'erreur (ou `about:blank` si pas de doc).
- `errors` : tableau optionnel pour les erreurs par champ (validation).

### Règle 5 : Versioning

- Version dans l'URL : `/api/v1/`, `/api/v2/`
- Incrémenter la version pour tout changement **breaking** (renommage/suppression de champ, changement de type, modification de comportement).
- Les ajouts non-breaking (nouveau endpoint, nouveau champ optionnel) ne nécessitent pas de nouvelle version.

### Règle 6 : Pagination

- Pagination **cursor-based** (pas offset/limit).
- Le curseur est un identifiant opaque (ex. encodage base64 d'un timestamp + ID).
- La réponse inclut un champ `cursor` pour la page suivante, `null` si dernière page.

Requête :
```
GET /api/v1/articles?cursor=eyJpZCI6IDQyLCAiY3JlYXRlZF9hdCI6ICIuLi4ifQ==&page_size=20
```

Réponse :
```json
{
  "data": [...],
  "next_cursor": "eyJpZCI6IDg0LCAiY3JlYXRlZF9hdCI6ICIuLi4ifQ=="
}
```

- `page_size` optionnel avec défaut (20) et maximum (100).
- `next_cursor` = `null` si dernière page.

### Règle 7 : Authentification

- Préférer **API keys** via header `Authorization: Bearer <token>` pour l'authentification machine-to-machine.
- Pour les API utilisateur, utiliser **OAuth 2.0** (Authorization Code Flow) ou des JWT signés.
- Ne pas exposer les tokens dans l'URL.

### Règle 8 : HATEOAS partiel (liens)

Chaque réponse inclut un bloc `_links` avec les liens navigables utiles :

- `self` — lien vers la ressource elle-même
- Relations directes — `author`, `comments`, `parent`, etc.
- Pagination — `next` (et `prev` si applicable)

```json
{
  "data": { "id": "abc123", "title": "..." },
  "_links": {
    "self": { "href": "/api/v1/articles/abc123" },
    "author": { "href": "/api/v1/users/xyz789" },
    "comments": { "href": "/api/v1/articles/abc123/comments" }
  }
}
```

Ne pas inclure les liens d'action (`edit`, `delete`, `publish`). Le client détermine les actions possibles via OpenAPI et les méthodes HTTP.

### Règle 9 : Filtres et recherche

Les paramètres de filtrage et tri sont passés **directement** en query params, sans namespace `filter[...]` :

```
GET /api/v1/articles?status=active&author_id=xyz789&sort=-created_at
```

- `sort` préfixé par `-` pour descendant, `+` ou pas de préfixe pour ascendant.
- Plusieurs tris : `sort=-created_at,title`.

### Règle 10 : Embedding de relations

Le client peut inclure les relations liées via `?include=author,comments` :

```json
{
  "data": {
    "id": "abc123",
    "title": "Mon article",
    "author": { "id": "xyz789", "name": "Stéphane" },
    "author_id": "xyz789"
  },
  "_links": {
    "self": { "href": "/api/v1/articles/abc123" }
  }
}
```

- Les relations sont imbriquées directement dans `data` (pas de bloc `included` séparé).
- L'ID de relation (`author_id`) est conservé même quand l'objet est embarqué.
- Valeurs acceptées : noms de relations séparés par des virgules. Utiliser `_links` pour les relations non incluses.

### Règle 11 : Actions non-CRUD

- `POST /api/v1/{ressource}/{id}/{action}` — action sur une ressource existante, verbe en kebab-case.
- `POST /api/v1/{action}` — action globale.
- Paramètres dans le body (JSON), jamais dans l'URL.

```
POST /api/v1/articles/abc123/publish
POST /api/v1/send-newsletter
```

### Règle 12 : Format des dates

Toutes les dates dans les réponses JSON sont en **ISO 8601 avec timezone** :

```json
"2025-07-11T16:30:00+02:00"
```

### Règle 13 : File upload

- Envoi en `multipart/form-data`, directement sur la ressource cible :

```
POST /api/v1/users
Content-Type: multipart/form-data

{
  "name": "Stéphane",
  "avatar": <fichier>
}
```

- La réponse est la ressource créée avec l'URL du fichier incluse :

```json
{
  "id": "abc123",
  "name": "Stéphane",
  "avatar_url": "https://..."
}
```

### Règle 14 : Documentation interactive

- Endpoint `GET /api/v1/openapi.json` servant la spec OpenAPI 3.x dynamiquement.
- Interface **Scalar** exposée sur `/docs` en production (intégration SvelteKit officielle via `@scalar/sveltekit`), protégée par l'authentification de l'API.
- Nota bene : Scalar est une **startup VC-backed** ; l'interface open-source est gratuite, mais l'outil met fortement en avant ses services cloud (Pro $72/mois). Si cela devient gênant, migrer vers un autre renderer OpenAPI est possible sans changer la spec.
- La spec OpenAPI est obligatoire. Pas d'opération sans endpoint documenté.

## Références

- [OpenAPI Specification 3.x](https://spec.openapis.org/oas/latest.html)
- [RFC 9457 — Problem Details for HTTP APIs](https://www.rfc-editor.org/rfc/rfc9457)
- [RFC 3986 — URI Syntax](https://www.rfc-editor.org/rfc/rfc3986)

## Comportement de l'agent

- Lors de la création ou modification d'endpoints, appliquer les règles ci-dessus automatiquement.
- Signaler les violations : verbe dans l'URL, camelCase dans les champs JSON, pagination par offset, absence de `Location` header sur un `201 Created`, format d'erreur non conforme.
- Proposer une structure d'erreur RFC 9457 cohérente à la création d'une API.
