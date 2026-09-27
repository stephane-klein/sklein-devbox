---
name: sklein-sql-generation
description: Génération de SQL pour PostgreSQL selon le style "river" et les conventions de Stéphane Klein.
---

# sklein-sql-generation

Génération de SQL pour PostgreSQL selon le style "river" et les conventions de Stéphane Klein.

## Déclencheur

Ce skill est activé lorsque l'utilisateur demande de :

- Générer du SQL
- Écrire une requête SQL
- Créer une table ou un schéma PostgreSQL
- Discuter de migration ou de structure de base de données

## Référence

- Style Guide : [https://www.sqlstyle.guide/](https://www.sqlstyle.guide/) — *"SQL Style Guide"* par Simon Holywell

## Règles

### Règle 1 : Noms de tables au pluriel

- Ex: `users`, `orders`, `invoice_items`
- Exception : noms collectifs naturels (ex: `staff`)

### Règle 2 : Style "River"

Alignement des mots-clés SQL à droite, valeurs à gauche, créant une "rivière" verticale (cf. [White space - SQL Style Guide](https://www.sqlstyle.guide/#white-space)).

```sql
SELECT u.id,
       u.first_name,
       u.created_at
  FROM users AS u
 WHERE u.email = 'test@example.com';
```

- Mots-clés (`SELECT`, `FROM`, `WHERE`, `AND`, `JOIN`) alignés à droite
- Colonnes et valeurs alignées à gauche
- Espaces avant/après `=`, après virgules
- `AS` pour les alias
- Indentation 2 espaces pour les clauses JOIN

### Règle 3 : Conventions de nommage PostgreSQL

| Élément | Convention | Exemple |
|---------|-----------|---------|
| Table | pluriel, snake_case | `users`, `invoice_items` |
| Colonne | singulier, snake_case | `email`, `created_at` |
| Clé primaire | `{table_singular}_id` | `user_id` |
| Clé étrangère | `{referenced_table_singular}_id` | `order_id` |
| Index | `idx_{table}_{column(s)}` | `idx_users_email` |
| Contrainte FK | `fk_{table}_{referenced_table}` | `fk_orders_users` |
| Contrainte UNIQUE | `uq_{table}_{column}` | `uq_users_email` |
| Contrainte CHECK | `chk_{table}_{description}` | `chk_users_age_positive` |

Ne pas utiliser de préfixes (`tbl_`, `sp_`, etc.).

### Règle 4 : Syntaxe PostgreSQL recommandée

- Utiliser `RETURNING` pour les `INSERT/UPDATE/DELETE` afin de récupérer les données modifiées.
- Utiliser `ON CONFLICT ... DO UPDATE` pour les opérations upsert.
- Préférer les CTE (`WITH`) pour les requêtes complexes.
- Dates au format ISO 8601 : `YYYY-MM-DDTHH:MM:SS.SSSSS+00`.

### Règle 5 : Reserved words

Toujours UPPERCASE pour les mots-clés SQL (`SELECT`, `WHERE`, `JOIN`, etc.).

### Règle 6 : Choix des primary keys

#### Principe général : séparer la PK interne de l'identifiant public

Ne jamais exposer la PK interne dans les URLs, APIs ou interfaces utilisateur.
Utiliser à la place un identifiant public dédié (slug sémantique ou NanoID).

#### PK interne : `INTEGER` ou `BIGINT` avec séquence

Par défaut, utiliser `INTEGER GENERATED ALWAYS AS IDENTITY` (ou `BIGINT` si la table est susceptible de dépasser ~2 milliards de lignes).

```sql
CREATE TABLE users (
    user_id   INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nanoid    VARCHAR(6)   NOT NULL UNIQUE,
    email     VARCHAR(255) NOT NULL UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

Raisons : les indexes B-Tree sur des valeurs séquentielles sont ~300× plus efficaces que sur UUID v4 (insertions en feuille droite, pas de page splits, taux de remplissage ~98% vs ~79%, WAL réduit).

#### Identifiant public : slug sémantique ou NanoID

Par ordre de préférence :

1. **Slug sémantique** quand c'est possible — ex: `/users/stephane-klein/` — meilleur pour l'UX et le SEO.
2. **NanoID `VARCHAR(6)`** alphanumérique lowercase quand il faut un identifiant court non-devinable.
3. **UUID v7** si le contexte distribué (multi-sources, génération côté client sans coordination) l'exige — disponible nativement en PostgreSQL 18, sinon via l'extension `pg_uuidv7`.

```sql
-- Exemple avec NanoID comme identifiant public
ALTER TABLE users ADD COLUMN nanoid VARCHAR(6) NOT NULL UNIQUE;
CREATE INDEX idx_users_nanoid ON users (nanoid);
```

#### À ne jamais faire

- **UUID v4 comme PK** : aléatoire pur, cause fragmentation B-Tree sévère, ~40% de pages supplémentaires vs `BIGINT`, dégradation du buffer cache.
- **Encoder des données métier dans la PK** (date, genre, statut…) : toute donnée changeante dans une PK deviendra un problème.
- **XOR ou RC4 pour obfusquer des integers** : équivalent cryptographiquement nul. Préférer NanoID ou, si une obfuscation forte est nécessaire, un block cipher (AES-128 en ECB sur l'integer).

#### Exception : contexte distribué

Dans une architecture multi-bases ou avec génération d'IDs côté client (offline-first, microservices sans coordination), UUID v7 comme PK est légitime. Les jointures internes restent inefficaces comparées à `BIGINT`, mais le besoin fonctionnel prime.

## Comportement de l'agent

- Lorsque l'utilisateur demande de générer du SQL, appliquer automatiquement les règles ci-dessus.
- Pour toute création de table, proposer par défaut `INTEGER GENERATED ALWAYS AS IDENTITY` comme PK et suggérer un champ `nanoid` ou `slug` si la table est destinée à être exposée.
- Proposer des améliorations (index, contraintes, optimisation) si pertinent.
- Signaler explicitement si une demande utilise UUID v4 comme PK et expliquer les alternatives.
