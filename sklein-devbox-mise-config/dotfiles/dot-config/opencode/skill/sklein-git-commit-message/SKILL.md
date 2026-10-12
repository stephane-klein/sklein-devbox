---
name: sklein-git-commit-message
description: "Guidelines for proposing git commit messages for Stéphane Klein's projects. English by default, no conventional commit prefixes unless the project explicitly defines them."
---

# sklein-git-commit-message

Guidelines for proposing git commit messages.

## Portée

- Ces conventions s'appliquent aux **projets de Stéphane Klein** par défaut.
- Si un projet possède déjà ses propres guidelines de commit message définies par un autre auteur (ex: `CONTRIBUTING.md`, `.gitmessage`, hooks, convention de l'équipe), **suivre strictement les guidelines du projet** et ignorer celles-ci.

## Langue

- **Par défaut**, rédiger tous les messages de commit en **anglais**.
- Ne passer en **français** que si l'utilisateur le demande **explicitement**.

## Rejet des formats à préfixes

- Ne **jamais** utiliser de préfixes type `fix:`, `feat:`, `docs:`, `chore:`, `refactor:`, etc. par défaut.
- Ce rejet s'applique aux styles Angular, Conventional Commits, Commitizen, et similaires.
- **Exception** : si le projet possède déjà une convention de commit message définie (ex: un `CONTRIBUTING.md`, un `.gitmessage`, ou un hook), s'y conformer strictement.

## Structure du message

Le message de commit comporte deux parties : une ligne de résumé (summary/subject) et un corps de description optionnel (body).

### Ligne de résumé (Summary line)

- **Verbe impératif**, présent, actif, en anglais. Exemples : `Add`, `Drop`, `Fix`, `Refactor`, `Optimize`, `Document`, `Update`, `Make`, `Start`, `Stop`, `Rearrange`, `Reword`.
- **Capitaliser** la première lettre. Exemple : `Add feature` (pas `add feature`).
- **Ne pas terminer par un point** (`.`) à la fin de la ligne de résumé.
- Exception : si le résumé se termine par une abréviation contenant un point (ex: `U.S.A.`), conserver le point.

### Corps de description (Body)

- Séparer le résumé du corps par une **ligne vide**.
- Le corps est optionnel ; l'utiliser pour expliquer le *pourquoi* du changement, pas seulement le *quoi*.
- Conserver les lignes longues telles quelles pour le texte atypique (URLs, sorties terminal, messages formatés, etc.).

## Verbes recommandés pour le résumé

Privilégier les verbes suivants, car ils sont courts, clairs et utilisent le mode impératif :

- `Add` — Créer une capacité (feature, test, dépendance).
- `Drop` — Supprimer une capacité.
- `Fix` — Corriger un problème (bug, typo, accident).
- `Bump` — Augmenter la version d'une dépendance.
- `Make` — Modifier le processus de build, les outils, l'infrastructure.
- `Start` — Commencer quelque chose (activer un feature flag).
- `Stop` — Arrêter quelque chose (désactiver un feature flag).
- `Optimize` — Améliorer les performances (vitesse, mémoire).
- `Document` — Modifier uniquement la documentation.
- `Refactor` — Refactoring pur, sans changement de comportement.
- `Reformat` — Changement de formatage uniquement (espaces, indentation).
- `Rearrange` — Changement de disposition uniquement.
- `Redraw` — Changement de graphique, image, icône.
- `Reword` — Modification de formulation (commentaire, label, doc).
- `Update` — Mise à jour générale.
- `Revise` — Révision, correction, altération.
- `Refit` / `Refresh` / `Renew` / `Reload` — Mise à jour de données de test, clés API, etc.

## Exemples de résumés corrects

```
Add user authentication flow
Fix race condition in cache cleanup
Refactor database connection pooling
Update README with new install steps
Drop legacy CSV export feature
Optimize image resizing pipeline
Document environment variable requirements
```

## Exemples de résumés incorrects

```
add user authentication flow          # pas capitalisé
Added user authentication flow        # passé, pas impératif
Adding user authentication flow       # gérondif, pas un verbe
User authentication flow added        # voix passive
fix: race condition in cache cleanup  # préfixe interdit par défaut
Fix race condition in cache cleanup.  # point final interdit
```

## Informations optionnelles dans le corps

- **Liens de tracking** : utiliser des URLs complètes, une par ligne, préférablement avec `See: https://...`.
- **Références** : éviter les IDs de tickets bruts dans le résumé ; les placer dans le corps avec une URL complète.

## Comportement de l'agent

- **Ne jamais demander** à l'utilisateur s'il souhaite le message de commit en français. Utiliser l'anglais par défaut sans sollicitation.
- **Être minimaliste** dans les commentaires et interactions en dehors de la proposition du message de commit. Ne pas ajouter de texte superflu.

## Source d'inspiration

Ces conventions s'inspirent largement de la guideline [git-commit-message](https://github.com/joelparkerhenderson/git-commit-message/) de Joel Parker Henderson.
