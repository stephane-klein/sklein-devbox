---
name: sklein-text-review
description: Révision et correction de textes — analyse grammaticale, logique et stylistique avec propositions de correction et version reformulée.
---

# sklein-text-review

Quand l'utilisateur demande une review, une relecture, une correction ou une révision d'un texte (note, email, documentation, article, message, etc.) :

- **Scope** : tout type de texte sauf code source. Si le texte contient du code, l'exclure de l'analyse ou signaler qu'un skill dédié au code existe.
- **Langue** : adapter la langue de l'analyse à celle du texte source (français ou anglais).

## Axes d'analyse

Effectuer la review selon quatre axes, dans l'ordre suivant :

### 1. Grammaire, orthographe et ponctuation

- Accords en genre et en nombre (noms, adjectifs, participes passés)
- Conjugaisons et temps verbaux
- Orthographe des mots (y compris homophones)
- Ponctuation (virgules, points, points-virgules, tirets, etc.)
- Typographie : espaces insécables, guillemets, apostrophes, deux-points (selon les règles de la langue source)

### 2. Logique et justesse

- Cohérence des idées et des arguments
- Absence de contradictions internes
- Exactitude des faits affirmés (si vérifiables)
- Structure argumentative : le raisonnement tient-il la route ?
- Pertinence des exemples et illustrations

### 3. Fluidité et style

- Tournures de phrases : sont-elles naturelles et fluides ?
- Lourdeurs, pléonasmes, répétitions inutiles
- Clarté et concision
- Adéquation au ton professionnel détendu (cf. skill sklein-writing-style)
- Bon usage des marqueurs de modestie épistémique quand pertinent
- Absence de formulations absolues du type « il n'y a aucune raison », « c'est toujours… »

### 4. Liens et sources

**Liens :**

- Présence et bonne formulation des URLs et références
- Absence de liens brisés (vérification technique si possible : HTTP 200)
- Cohérence entre le texte du lien et sa destination
- Formatage Markdown correct pour les liens

**Sources des affirmations :**

- Toute affirmation factuelle vérifiable (statistiques, chiffres, citations, faits précis) doit être sourcée
- Si une information chiffrée ou une citation est avancée sans référence : signaler et demander la source
- Formulation de la demande : ajouter la référence entre parenthèses ou en note de bas de page

## Niveaux de sévérité

Pour chaque problème identifié, indiquer un niveau de sévérité :

- 🔴 **Erreur** : faute objective (orthographe, grammaire, ponctuation, incohérence majeure). À corriger impérativement.
- 🟡 **Suggestion** : amélioration recommandée (tournure lourde, manque de clarté, risque de malentendu).
- 🟢 **Remarque** : point de vigilance mineur (style, nuance, préférence subjective).

*Exemples pour l'axe « Liens et sources » :*

- 🔴 Lien brisé ou URL malformée
- 🟡 Affirmation factuelle intéressante mais non sourcée
- 🟢 Opportunité d'ajouter une source secondaire ou d'enrichir un lien existant

## Format de réponse

Structure obligatoire :

1. **Résumé rapide** : nombre de points par axe et par sévérité (ex. « Grammaire : 2 erreurs, 1 suggestion ; Liens et sources : 1 suggestion »)
2. **Détails par axe** : pour chaque problème, indiquer :
   - Le passage concerné (citation courte)
   - La description du problème
   - Le niveau de sévérité (🔴/🟡/🟢)
   - Une **proposition de correction** ou de reformulation
3. **Version corrigée/reformulée** : le texte complet corrigé et amélioré, si le volume le permet. Sinon, proposer les corrections les plus impactantes.

## Règles de correction

- Conserver la longueur originale avec une marge de ~20% (comme sklein-reformulation)
- Préserver le sens et l'intention de l'auteur
- Ne pas ajouter de gras ni d'italique dans la version corrigée sauf demande explicite (cf. sklein-writing-style)
- Utiliser les listes à puces (`-`) si le texte original en contient
- Respecter les conventions typographiques de la langue source (ex. espace avant les deux-points en français)

## Skills à charger

Charge le skill **sklein-writing-style** pour le ton, le registre et les formulations.

Charge le skill **sklein-markdown** pour les questions de formatage Markdown.

Charge le skill **sklein-pkm** pour la syntaxe Obsidian si le texte source l'utilise.

## Exemple de sortie

```
## Résumé

- Grammaire : 1 erreur, 1 suggestion
- Logique : 0 erreur, 1 suggestion
- Fluidité : 0 erreur, 2 remarques
- Liens et sources : 1 suggestion, 1 remarque

## Grammaire, orthographe et ponctuation

🔴 *« Les données sont stocké sur le serveur »*
Accord du participe passé. Proposition : « Les données sont stockées sur le serveur ».

🟡 *« Cependant, il faut noter que… »*
La virgule après « Cependant » est inutile. Proposition : « Cependant il faut noter que… ».

## Logique et justesse

🟡 *« Cette solution est toujours la meilleure. »*
Formulation absolue. Proposition : « Cette solution semble généralement la meilleure. »

## Fluidité et style

🟢 *« Il est important de noter qu'il convient de vérifier que… »*
Tournure lourde et administrative. Proposition : « Vérifiez que… ».

## Liens et sources

🟡 *« 87% des développeurs utilisent cet outil »*
Affirmation chiffrée sans source. Proposition : ajouter « (source : étude X, 2024) ».

🟢 *« https://exemple.com/article »*
Lien fonctionnel mais pourrait être enrichi d'un texte descriptif : « [article sur le sujet](https://exemple.com/article) ».

## Version corrigée

[Texte complet corrigé]
```
