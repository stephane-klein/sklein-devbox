---
name: sklein-dependency-doctrine
description: >
  Doctrine de Stéphane pour évaluer les dépendances logicielles. Utiliser cette skill
  chaque fois qu'il s'agit d'ajouter une librairie, de choisir entre plusieurs candidats,
  de décider d'écrire soi-même vs dépendre, ou de retirer une dépendance existante.
  S'applique à tous les langages et écosystèmes.
---

# Doctrine de sélection des dépendances

## Principe central

Toute dépendance est une **couche de complexité accidentelle** (au sens de Brooks, *No Silver Bullet*).
Elle n'est justifiée que si elle réduit la complexité essentielle du problème plus qu'elle
n'en introduit une nouvelle.

L'ennemi est le **cargo cult** : adopter une librairie par habitude, par imitation, ou parce
que c'est "ce qu'on fait" — sans analyser si elle résout un problème réel dans le contexte présent.

Préférer les librairies aux frameworks, et les micro-frameworks aux frameworks
monolithiques qui font tout. L'outil le plus ciblé et le moins enveloppant est
toujours le meilleur candidat par défaut.

---

## 1. Ajouter une nouvelle dépendance

Poser ces questions **dans l'ordre**, et s'arrêter dès qu'une réponse est "non" :

**1.1 — Le problème est-il réel et présent ?**
> Est-ce que j'ai *maintenant* un besoin concret, ou est-ce que j'anticipe un besoin hypothétique ?
> (YAGNI : *You Aren't Gonna Need It*)

**1.2 — Peut-on l'enlever plutôt qu'ajouter ?**
> Avant de chercher une librairie, peut-on reformuler le problème de façon à ce qu'il disparaisse ?
> Exemple : enlever `make` plutôt que chercher un outil "mieux que make".

**1.3 — La stdlib ou les primitives du langage suffisent-elles ?**
> Est-ce que le langage / runtime natif peut couvrir le besoin avec un code raisonnable ?
> Si oui, écrire soi-même est préférable.

**1.4 — La librairie réduit-elle vraiment la complexité accidentelle ?**
> Ce qu'elle apporte > ce qu'elle coûte (apprentissage, maintenance, surface d'attaque,
> contraintes de version, comportement opaque) ?

**1.5 — La librairie est-elle en bonne santé ?**
> - Maintenance active (commits récents, issues traitées) ?
> - Date de création du projet ? Survivre plusieurs années est un bon signal ;
>   un projet trop récent n'a pas fait ses preuves dans la durée.
> - Licence compatible avec le projet ?
> - Dépendances transitives acceptables (pas de chaîne leftpad) ?
> - Communauté ou sponsor pérenne ?

**1.6 — Est-ce du suivisme de hype ?**
> La librairie est-elle choisie parce qu'elle est populaire en ce moment, ou parce qu'elle
> résout *ce* problème mieux que les alternatives dans *ce* contexte ?

---

## 2. Choisir entre plusieurs librairies candidates

Une fois que l'ajout est justifié (section 1), comparer les candidates sur :

**2.1 — Périmètre fonctionnel**
> Laquelle couvre le besoin *minimal requis* sans embarquer des fonctionnalités inutiles ?
> Préférer la librairie focused plutôt que le framework all-in-one si le besoin est limité.

**2.2 — Surface d'API**
> Laquelle expose une API plus petite, plus cohérente, plus prévisible ?
> Une API simple est un signe de conception réfléchie.

**2.3 — Complexité d'apprentissage**
> Combien de temps pour comprendre les edge cases, pas juste le happy path ?
> Une documentation volumineuse est souvent le signe d'une complexité accidentelle embarquée.

**2.4 — Alignement avec le paradigme existant**
> La librairie respecte-t-elle le style fonctionnel / expression-oriented déjà en place ?
> Introduit-elle des mutations, des classes, des patterns incompatibles avec la base de code ?

**2.5 — Coût de retrait futur**
> Si on veut l'enlever dans 2 ans, à quel point est-elle tentaculaire ?
> Préférer une librairie dont l'usage est localisé et remplaçable.

---

## 3. Écrire soi-même vs dépendre

**3.1 — Quelle est la taille réelle du code nécessaire ?**
> Si l'implémentation maison tient en < 50 lignes et couvre 100% du besoin,
> la dépendance est probablement injustifiée.

**3.2 — Le comportement doit-il être entièrement contrôlé ?**
> Pour les parties critiques (sécurité, données, logique métier centrale),
> le contrôle total prime sur la commodité.

**3.3 — La dépendance introduit-elle un comportement opaque ?**
> Si débugger un problème nécessite de lire le code source de la librairie,
> écrire soi-même peut être moins coûteux sur la durée.

**3.4 — Quel est le coût de maintenance comparé ?**
> Code maison : coût d'écriture élevé, coût de maintenance faible si le problème est stable.
> Dépendance : coût d'écriture faible, coût de maintenance distribué mais sujet aux
> breaking changes et abandons.

---

## 4. Retirer une dépendance existante

**4.1 — Quelle valeur réelle apporte-t-elle aujourd'hui ?**
> Pas ce qu'elle apportait à l'époque où elle a été ajoutée — aujourd'hui.
> Les besoins changent, les librairies aussi.

**4.2 — La stdlib a-t-elle comblé le manque depuis ?**
> Les langages évoluent. Ce qui nécessitait une librairie en 2018 est parfois natif en 2025.

**4.3 — Le coût de retrait est-il proportionnel au gain ?**
> Enlever une couche a du sens si le ratio complexité_retirée / effort_retrait est favorable.
> Ne pas retirer pour la pureté idéologique si le coût est élevé et le bénéfice marginal.

**4.4 — Y a-t-il un meilleur moment ?**
> Le retrait peut être planifié lors d'une réécriture ou refactoring connexe
> pour amortir le coût.

---

## Signaux d'alarme (résumé)

Ces signaux doivent déclencher une pause et un questionnement explicite :

- "Tout le monde utilise X" → suspicion de cargo cult
- "X vient de sortir et monte vite sur GitHub" → suspicion de hype (projet trop jeune)
- La documentation de X est un livre → suspicion de complexité accidentelle embarquée
- X résout un problème que je n'ai pas encore eu → YAGNI
- X est la "bonne pratique" dans cet écosystème → challenger pourquoi

---

## Références doctrinales

- **Complexité accidentelle vs essentielle** : Fred Brooks, *No Silver Bullet* (1986)
- **YAGNI** : Kent Beck, Extreme Programming
- **Cargo cult programming** : pratique imitée sans compréhension des raisons
- **Lean / Muda** : éliminer ce qui n'apporte pas de valeur
- **"Enlever des couches"** : principe personnel — reformuler le problème pour supprimer
  le besoin plutôt que le satisfaire
