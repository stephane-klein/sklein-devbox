# Grille d'analyse des modèles économiques

## Tableau des signaux

| Signal | Community | VC-backed | Open Core | AGPL / Dual License |
|--------|-----------|-----------|-----------|---------------------|
| **Licence du repo** | MIT, Apache 2.0, BSD, GPL | MIT, Apache 2.0 | MIT, Apache 2.0, AGPL | AGPL-3.0, SSPL, BUSL |
| **Entité légale** | Aucune ou fondation | Société (SAS, Inc.) | Société (SAS, Inc.) | Société ou individu |
| **Offre payante** | Aucune | SaaS/Cloud (même produit) | Enterprise Edition (features privatives) | Commercial license (même code) |
| **README mentions** | — | "Get started", "Sign up" | "Enterprise", "Pro", "Pricing" | "Commercial license", "Contact us" |
| **Crunchbase** | Aucun | Funding rounds (Seed → Series A/B/C) | Parfois (si société) | Parfois |
| **Gouvernance** | BDFL, maintainers | Company-led | Company-led | Company-led |
| **GitHub Sponsors** | Parfois | Non (sauf pour le projet chez l'employeur) | Parfois l'OSS core seulement | Rarement |
| **Fondation** | Linux Foundation, CNCF, Apache, Eclipse | Non (sauf après donation) | Non | Non |

## Modèles détaillés

### Community

Projet maintenu par des bénévoles ou une fondation.

Pas d'entité commerciale derrière. Pas de version payante.

Exemples : Express.js, curl, FFmpeg, Lua, Redis (avant 2018).

Signaux forts :
- Aucune page "Pricing" sur le site
- LICENSE permissive ou GPL standard
- Governance dans une fondation (Apache, CNCF, Linux Foundation)
- Commits d'individus variés, pas d'une seule entreprise

### VC-backed

Projet porté par une startup qui a levé des fonds.

Le produit OSS est souvent **le produit principal** de la société.

Exemples : Docker, GitLab, Grafana, Vercel (Next.js).

Signaux forts :
- Crunchbase : 1+ rounds identifiés (Seed, Series A/B/C)
- Site web : page "About" avec investisseurs listés
- LICENSE permissive (pour maximiser l'adoption)
- Produit SaaS/Cloud basé sur le même logiciel

Indice complémentaire : regarder la page Crunchbase. Si la société apparaît avec des investisseurs institutionnels (Sequoia, a16z, Accel, Index, etc.), c'est VC-backed.

### Open Core

Le cœur du logiciel est OSS mais les fonctionnalités avancées sont propriétaires (payantes).

La séparation est explicite : "Community Edition" vs "Enterprise Edition".

Exemples : GitLab CE/EE, Mattermost, Nginx, Sidekiq, Temporal.

Signaux forts :
- README : tableau comparatif CE vs EE
- Site web : grille de prix claire avec "Community" / "Enterprise" / "Ultimate"
- LICENSE mitigée : le core peut être MIT mais des plugins/modules sont propriétaires
- "source-available" ≠ open source (attention à BUSL, Elastic License)

### AGPL / Dual License

Stratégie : licence AGPL très contraignante + vente de licence commerciale pour les entreprises qui ne veulent pas ouvrir leur code modifié.

Ou bien : licence non-OSS (SSPL, BUSL, Elastic License 2.0) présentée comme "open source".

Exemples : MongoDB (SSPL), MinIO (AGPL), SuiteCRM (AGPL), MySQL (dual GPL/commercial), Redis Modules (RSAL).

Signaux forts :
- LICENSE mentionne AGPL-3.0, SSPL, BUSL, ou Elastic License 2.0
- Site web : "Commercial License" ou "License for OEM/ISV"
- Souvent utilisé pour vendre une version managée (DBaaS)
- Attention : SSPL et BUSL ne sont pas considérées OSS par l'OSI / Debian / Fedora

## Cas particuliers

| Cas | Description | Classification |
|-----|-------------|---------------|
| **Foundation after VC** | Projet donné à une fondation après rachat ou abandon (ex: Chef, Docker → CNCF) | Community (ex-VC-backed) |
| **Bounty-driven** | Financement par bounties/grants (ex: Telegraf) | Community |
| **SaaS + OSS** | Projet OSS + version SaaS hébergée par la même société | Open Core |
| **AGPL + SaaS** | AGPL + version SaaS propriétaire (ex: MinIO) | AGPL / Open Core |
| **Source-available** | Licence type BSL, Elastic License 2.0 | Ni OSS ni propriétaire — à mentionner comme "source-available" |

## Comment vérifier chaque source

### LICENSE
```
curl -s https://raw.githubusercontent.com/{owner}/{repo}/main/LICENSE | head -20
```

### Crunchbase
```
https://www.crunchbase.com/organization/{company-name}
```
Chercher le nom de la société sur la page d'accueil ou "About" du projet.

### GitHub funding
```
gh api repos/{owner}/{repo} --jq '.funding'
```

### GitHub contributors
```
https://github.com/{owner}/{repo}/graphs/contributors
```
Si > 50% des commits viennent d'employés d'une même entreprise, le projet est company-driven.
