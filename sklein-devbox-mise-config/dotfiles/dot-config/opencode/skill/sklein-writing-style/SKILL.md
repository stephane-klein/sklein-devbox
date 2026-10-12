---
name: sklein-writing-style
description: "Style d'écriture de Stéphane Klein : narration du processus intellectuel. Pour toute rédaction (notes, documentation, messages). Français et anglais."
---

# Narration du processus intellectuel

Conventions de style pour toute rédaction (notes, issues, documentation, messages).

## Registre

- Raconter le **cheminement** : les questions qu'on se pose, les erreurs qu'on fait, les bifurcations, comment on a avancé sur un sujet.
- Écrire en première personne, de manière incarnée. Le « je » est le bienvenu.
- Être direct et concis.
- Pas de style marketing, pas de langage publicitaire.
- **Vouvoiement** : utiliser le vouvoiement sur sklein.xyz et notes.sklein.xyz. Ailleurs, s'adapter au contexte.
- **Anglais** : le tutoiement/vouvoiement ne se pose pas, utiliser "you" par défaut.

## Narrer le processus intellectuel

Principe : écrire comme on pense, pas comme on conclut.

- Montrer les questions non résolues, les doutes, ce qui résiste.
- Ne pas gommer les hésitations — les rendre lisibles au contraire.
- Distinguer clairement ce qu'on sait de ce qu'on suppose.
- Signaler les changements d'avis en cours d'écriture : « je pensais X mais maintenant je penche pour Y ».
- Si un point n'est pas compris du tout, le dire.

**Contraste sain** (ce qu'on ne veut pas) : un texte qui donne l'impression que tout était déjà clair avant d'écrire, que l'auteur survole le sujet d'un regard omniscient.

## Structure skimmable

Organiser le contenu pour la lecture rapide :

- Des titres descriptifs et des liens ancrés sur les titres pour partager directement au bon endroit.
- Ne pas enfouir les idées dans de la prose : un lecteur doit pouvoir trouver une réponse précise sans tout lire.
- La structure (headers, sections) est une aide à la navigation — elle ne doit pas être doublée par une rhétorique de plan annoncé dans la prose (cf. `tone-analyzer`).

## Marqueurs de modestie épistémique

Utiliser des formulations qui marquent le doute, la nuance, **ou le processus en cours** :

- « il me semble que… », « I think that… »
- « probablement… », « likely… »
- « peut-être… », « perhaps… »
- « mon intuition dirait que… », « my intuition would be that… »
- « je me trompe sans doute… », « I am probably wrong… »
- « je n'arrive pas encore à trancher… »
- « plusieurs questions restent ouvertes… »
- « je pensais X mais maintenant… »
- « je bute sur ce point… »
- « je ne comprends pas encore pourquoi… »
- « selon cet article… », « according to this article… »
- « il paraît que… », « it appears that… »

**Règle d'usage** : ajouter ces marqueurs quand c'est pertinent, pas de manière systématique ou gratuite. Adapter à la langue cible (français ou anglais).

## Signaux professoraux à éviter

Ces mécanismes créent une distance artificielle et contredisent la narration du processus :

- **Effacement du sujet** : éviter les constructions impersonnelles qui évitent le « je » (« on constate que », « il apparaît que », « il convient de noter », « cela démontre »). Préférer « je constate que », « ça me fait penser que ».
- **Nominalisation** : éviter les noms longs là où un verbe suffit (« la problématisation de » → « comment poser le problème », « une mise en perspective » → « replacer dans le contexte »).
- **Transitions formelles** : éviter les connecteurs lourds entre paragraphes (« Ainsi, nous pouvons affirmer que… », « Dès lors, il convient de s'interroger… », « Au regard de ce qui précède… »).
- **Conclusions sans cheminement** : éviter les affirmations péremptoires ou les conclusions abruptes qui n'ont pas été préparées par le raisonnement.

Pour une analyse fine, utiliser le skill **tone-analyzer**.

## Clarté

- Privilégier la communication explicite.
- Les répétitions de pronoms sont acceptables si elles améliorent la compréhension.
- **Exemples** : un ou deux exemples concrets valent mieux qu'une définition formelle quand un point peut être ambigu. Ne pas en forcer là où le texte est déjà clair sans — l'exemple doit éclairer, pas décorer.
- **Acronymes** : définir ou linker les acronymes à leur première occurrence.

## Terminologie

- Conserver les termes techniques en anglais (noms de librairies, protocoles, fonctions, etc.), quelle que soit la langue de rédaction.

## Typographie

### Deux-points

- En **français** : toujours insérer un espace avant le deux-points. Exemple : `Foo bar :`.
- En **anglais** : ne jamais insérer d'espace avant le deux-points. Exemple : `Foo bar:`.

Cette règle respecte les conventions typographiques de chaque langue.

### Gras et italique

- Ne pas utiliser le gras (`**texte**`) ni l'italique (`*texte*`) dans les rédactions de documents, commentaires, notes ou documentation.
- L'utilisateur préfère choisir lui-même ce qui doit être mis en valeur.
- Exception : utiliser le gras ou l'italique uniquement si l'utilisateur demande explicitement un verbatim d'un source ou s'il l'instruit de le faire.
