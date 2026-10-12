---
name: sklein-note-ai-provenance
description: Gère le frontmatter de provenance IA (ai_origin, ai_model, date, ai_note, reviewed_at) sur les notes Markdown personnelles (PKM, brouillons, réflexions). À consulter chaque fois qu'un fichier Markdown est généré, complété ou retravaillé à partir d'un thread de conversation avec un agent IA — même sans demande explicite de l'utilisateur — pour déterminer le bon niveau de paternité (human / human-edited / collab / ai-drafted / ai-generated) et tenir le frontmatter à jour au fil des éditions.
---

# Provenance IA dans le frontmatter des notes Markdown

## Domaine d'application

**Inclus** — toutes les notes personnelles, en particulier celles du PKM
(`notes.sklein.xyz`), les brouillons, les réflexions, la documentation
personnelle.

**Exclus** — ne pas ajouter ce frontmatter dans les fichiers suivants,
qui appartiennent à des projets de développement :

- `README.md`
- `AGENTS.md` / `CLAUDE.md`
- `CHANGELOG.md`
- `CONTRIBUTING.md`
- tout fichier Markdown dont le rôle est technique ou documente le projet
  (sauf s'il s'agit délibérément d'une note personnelle rangée dans un
  dossier de projet — dans ce cas, appliquer la provenance normalement).

## Objectif

Toute note personnelle produite ou retouchée avec l'aide d'un agent IA porte un
frontmatter qui rend explicite l'origine du texte. Ce skill définit les champs,
leurs valeurs possibles, et la procédure pour les déterminer et les maintenir à jour à chaque édition.

## Champs

- `ai_origin` (obligatoire) — niveau de paternité, voir échelle ci-dessous.
- `ai_model` — nom du modèle ayant contribué au texte (ex. `Claude Sonnet 4.6`). Si plusieurs modèles sont intervenus à des moments différents, citer le contributeur le plus récent et significatif, et détailler l'historique dans `ai_note`.
- `date` (format `YYYY-MM-DD`) — date de création du premier jet. Ne change pas aux éditions suivantes.
- `ai_note` — une phrase factuelle décrivant concrètement ce que l'IA a fait (généré de zéro, condensé, reformulé, structuré...).
- `reviewed_at` (optionnel, format `YYYY-MM-DD`) — date à laquelle l'utilisateur confirme avoir relu le texte avec attention. Absence du champ = pas encore relu.

## Échelle `ai_origin`

- `human` — rédigé par l'utilisateur, IA non utilisée ou usage marginal (correction orthographique).
- `human-edited` — rédigé par l'utilisateur, IA utilisée pour relire ou reformuler un texte déjà écrit.
- `collab` — co-écriture itérative, allers-retours significatifs avec l'IA sur le fond.
- `ai-drafted` — premier jet généré par l'IA, ensuite retravaillé (coupes, restructuration, réécriture partielle) par l'utilisateur.
- `ai-generated` — texte produit par l'IA et repris quasi tel quel, sans retouche substantielle.

## Procédure

1. **Création à partir d'un thread de conversation avec un agent IA.** Si le texte final reprend la sortie du modèle sans modification substantielle → `ai-generated`. Renseigner `ai_model` (modèle de la session en cours) et `date` (date du jour). Rédiger `ai_note` en une phrase neutre décrivant la tâche ayant produit le texte.
2. **Édition d'une note déjà marquée `ai-generated`.** Édition mineure (typo, micro-reformulation) → laisser `ai_origin` inchangé. Édition substantielle (coupes, restructuration, ajout de contenu propre) → repasser `ai_origin` à `ai-drafted` et mettre à jour `ai_note` pour refléter la nature de la retouche. Ne pas modifier `date`.
3. **Texte initialement écrit par l'utilisateur**, IA utilisée seulement pour relecture/reformulation → `human-edited`, avec `ai_note` précisant l'usage.
4. **Construction par allers-retours répétés et substantiels** entre l'utilisateur et l'IA, sans qu'aucun des deux n'ait produit l'essentiel seul → `collab`.
5. Ne jamais déduire `reviewed_at` automatiquement : ce champ ne se pose que sur confirmation explicite de l'utilisateur qu'il a relu le texte avec attention.

## Garde-fou

Si l'origine du texte est ambiguë, ou que le thread ne permet pas de trancher avec certitude entre deux niveaux adjacents
(ex. `ai-drafted` vs `collab`), demander confirmation à l'utilisateur plutôt que de deviner. Une valeur de provenance mal
 assignée nuit davantage à la transparence recherchée qu'une valeur absente.

## Exemple

Premier jet généré intégralement par l'IA sur demande, puis condensé par l'utilisateur dans un tour suivant :

```yaml
---
ai_origin: ai-drafted
ai_model: Claude Sonnet 4.6
date: 2026-06-18
ai_note: Premier jet généré par Claude, condensé et restructuré en wikilinks par la suite.
---
```
