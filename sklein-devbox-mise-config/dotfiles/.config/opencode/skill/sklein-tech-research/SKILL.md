---
name: sklein-tech-research
description: "Méthode de recherche de fond sur une techno, un terme ou une tendance IT/startup via HackerNews Algolia et l'historique GitHub Contributors."
---

# sklein-tech-research

Méthode de recherche de fond sur une techno, un terme ou une tendance dans l'écosystème IT, startup et tech.

## Principe

Pour comprendre l'origine, l'adoption et la propagation d'un terme, d'un outil ou d'une tendance tech :

1. **HackerNews (HN) via Algolia** — retours terrain, fréquence, chronologie
2. **GitHub Contributors** — vitalité du projet, adoption par les développeurs
3. **Reddit** — source secondaire, parfois plus difficile à cibler

HackerNews est la source privilégiée car il s'agit d'une communauté tech dense avec une mémoire longue et des discussions souvent techniques et argumentées.

## Phase 1 : Recherche sur HackerNews Algolia

### URLs et paramètres

- **Recherche générale** (stories + comments, par pertinence) :
  `https://hn.algolia.com/?q={TERM}`
- **Chronologie complète** (tous les résultats, tri par date) :
  `https://hn.algolia.com/?dateRange=all&page=0&prefix=false&query={TERM}&sort=byDate&type=comment`

### Analyse à mener

- **Volume** : combien de mentions au fil du temps ?
- **Dates clés** : première apparition significative, pics de discussion
- **Fréquence** : stories vs. comments (les stories annoncent, les comments adoptent ou critiquent)
- **Sentiment** : nature des commentaires — questions, critiques, retours d'expérience, adoption en production
- **Acteurs** : quels comptes ou entreprises poussent le terme ?

## Phase 2 : Analyse GitHub Contributors

- Ouvrir la page **Contributors** du projet concerné : `https://github.com/{OWNER}/{REPO}/graphs/contributors`
- Observer :
  - **Date du premier commit significatif** — quand le projet a-t-il démarré ?
  - **Courbe de contributions** — croissance continue, plateau, déclin soudain ?
  - **Diversité** — contributions individuelles vs. corporate (employés d'une même entreprise)
  - **Rythme récent** — le projet est-il encore actif ou en maintenance seule ?

## Phase 3 : Reddit (source secondaire)

- Identifier les subreddits pertinents (`r/programming`, `r/devops`, `r/webdev`, `r/rust`, `r/golang`, etc.)
- Comparer les discussions avec celles de HN (souvent plus bruyantes, moins techniques)
- **Note** : Reddit est souvent moins direct pour remonter à l'origine d'une tendance, mais utile pour capter l'adoption grand public ou les frustrations utilisateurs

## Formats de synthèse possibles

Produire l'un des trois rendus suivants, ou une combinaison, selon la demande :

### 1. Notes brutes

Extraits clés des commentaires HN les plus pertinents + observations GitHub + liens directs.

### 2. Chronologie

Frise temporelle structurée :

- **Première mention HN** : date, contexte
- **Premiers commits GitHub** : date, auteur(s)
- **Pic d'adoption** : date, événement déclencheur si identifiable
- **État actuel** : hype déclinante, adoption stable, ou émergence récente ?

### 3. Tableau comparatif

| Source | Volume | Sentiment | Adoption concrète | Fiabilité |
|--------|--------|-----------|-------------------|-----------|
| HN Algolia | Élevé / Moyen / Faible | Positif / Mitigé / Critique | Oui / Partielle / Non | Élevée |
| GitHub Contributors | Actif / Stable / En déclin | — | Nombreux contributeurs / Concentré / Abandonné | Élevée |
| Reddit | Élevé / Moyen / Faible | Enthousiaste / Moqueur / Neutre | Anecdotique / Institutionnelle | Moyenne |

## Exemples de cas d'usage

| Cas | Terme / Projet | Objectif |
|-----|---------------|----------|
| **Origine d'un outil** | `harness` | Remonter à la création et comprendre le problème résolu |
| **Validation d'un buzzword** | `platform engineering` | Vérifier si le terme est soutenu par de l'adoption concrète ou s'il reste du marketing |
| **Propagation d'une techno** | `bun` | Observer la vitesse d'adoption, les freins mentionnés et le sentiment à long terme |
| **Tendance émergente** | `local-first` | Identifier si le concept gagne du terrain ou reste de niche |

## Instructions pour l'agent

Quand l'utilisateur demande une recherche sur un terme, un outil ou une tendance tech :

1. **Construire les URLs Algolia** avec le terme encodé pour l'espace (`+` ou `%20`)
2. **Récupérer et analyser** les résultats en pertinence puis par date
3. **Identifier le dépôt GitHub** associé si le terme correspond à un projet open source
4. **Analyser la page Contributors** du projet pour évaluer sa vitalité
5. **Proposer une synthèse** dans l'un des trois formats (notes brutes, chronologie, tableau comparatif) ou demander quel format est préféré
6. **Citer les sources** : toujours inclure les liens directs vers les discussions HN et la page GitHub analysée
