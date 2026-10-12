---
name: sklein-compare-oss-projects
description: >
  Compare plusieurs projets open source d'un même écosystème sur 4 axes :
  âge, stack technique, popularité (stars GitHub), et modèle économique
  (community / VC-backed / open core / AGPL). Commence par une phase de
  découverte multi-sources (GitHub search, awesome lists, HN Algolia, web)
  pour identifier les projets pertinents, collecte les métriques via un
  script shell utilisant l'API GitHub, analyse le modèle économique de chaque
  projet via inspection de la licence, du README, du site web et de
  Crunchbase, puis produit un tableau comparatif Markdown.
  Déclencher sur : "compare", "comparer", "choisir entre", "quel projet
  open source", "écosystème", ou toute demande d'évaluation d'alternatives
  open source.
---

# sklein-compare-oss-projects

## Workflow

### Phase 0 — Discovery

Identifier les projets d'un écosystème donné :

1. **GitHub search**
   - `gh search repos "<topic>" --stars:>1000 --limit 20`
   - Recherche par topic : `gh search repos "topic:<topic>"`
   - Trier par stars pour identifier les leaders
2. **Awesome lists**
   - Chercher les repos "awesome-<topic>" sur GitHub
   - Lire leur README et extraire la liste de projets
3. **HN Algolia** (via `fetch` web)
   - Rechercher `alternatives to <topic>`, `best <topic>`, `<topic> vs`
   - Utiliser le format : `https://hn.algolia.com/?q=alternatives+to+<topic>`
4. **Web fetch**
   - Sites de comparaison, AlternativeTo, libhunt
   - "comparison", "<topic> open source projects"

**Livrable** : shortlist de 3 à 8 projets proposée à l'utilisateur. Attendre validation avant de passer à la phase 1.

### Phase 1 — Collecte des métriques

```bash
scripts/gather-metrics.sh owner/repo1 owner/repo2 owner/repo3 ...
```

Produit un JSON avec les métriques brutes par projet :
`repo`, `stars`, `created_at`, `language`, `topics`, `license`, `pushed_at`, `forks`, `description`.

### Phase 2 — Analyse du modèle économique

Pour chaque projet validé, inspecter ces sources dans l'ordre :

1. **Fichier LICENSE** — lire son contenu pour identifier la licence exacte
   - Lire le fichier via l'URL brute GitHub : `https://raw.githubusercontent.com/{owner}/{repo}/main/LICENSE`
2. **GitHub funding** — `gh api repos/{owner}/{repo} --jq '.funding'` ou vérifier le champ `Funding` dans l'UI
3. **README** — chercher les mentions de : "Enterprise", "Pro", "Cloud", "Premium", "Pricing", "Get a quote", "Commercial"
4. **Site web** (si présent dans la description du repo) — y a-t-il une page "Pricing" ?
5. **Crunchbase** — `https://www.crunchbase.com/organization/{company-name}` rechercher les levées de fonds
6. **GitHub contributors graph** — `https://github.com/{owner}/{repo}/graphs/contributors` pour voir si les commits viennent d'une entreprise

Utiliser la grille [REFERENCE.md](REFERENCE.md) pour déterminer le modèle.

### Phase 3 — Production du tableau

Générer un tableau Markdown :

| Projet | Âge | Stars | Stack | Licence | Modèle éco | Signaux |
|--------|-----|-------|-------|---------|-----------|---------|
| `expressjs/express` | 15 ans | 65k+ | JavaScript | MIT | Community | ... |

Ajouter 2-3 phrases de synthèse par projet expliquant le classement.

Le tableau peut être suivi d'une section **Verdict** qui résume les forces et faiblesses relatives de chaque projet.

## Script de collecte

Voir [scripts/gather-metrics.sh](scripts/gather-metrics.sh).

Dépendances : `jq` + `gh` (recommandé) ou `curl`.

## Notes

- L'API GitHub non authentifiée est limitée à 60 requêtes/heure. Utiliser `gh` (authentifié via `gh auth login`) pour monter à 5000 requêtes/heure.
- `gather-metrics.sh` gère les deux modes : `gh` si dispo, fallback sur `curl`.
