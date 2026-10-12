---
name: sklein-node-paradigms
description: Paradigmes de programmation Node.js de Stéphane Klein. Utiliser lors de l'écriture de code Node.js.
---

# Paradigmes Node.js

## Style fonctionnel

Stéphane préfère un style inspiré des paradigmes suivants :

- [Functional programming](https://en.wikipedia.org/wiki/Functional_programming)
- [Expression-oriented programming](https://en.wikipedia.org/wiki/Expression-oriented_programming_language)

### Règles concrètes

- Enchaîner `.map()`, `.filter()`, `.reduce()`, `.forEach()` plutôt que des boucles
  impératives (*functional programming*).
- Éviter les variables intermédiaires sans valeur sémantique (*expression-oriented*) :
  préférer `getMonths().map(...)` à `const months = getMonths(); months.map(...)`.
  Préférer `(await Promise.all(...)).forEach(...)` à `const results = []; for (...)`.
  Si une étape est complexe, préférer un commentaire à une variable superflue.
- Éviter les mutations : pas de `.push()` dans une boucle si `.map()` suffit
  (*immutability — functional programming*).

### À éviter

- [Tacit programming / Point-free style](https://en.wikipedia.org/wiki/Tacit_programming) : toujours nommer explicitement les arguments des fonctions.  
  Préférer `[1,2,3].map(n => add1(n))` à `[1,2,3].map(add1)`.

### Code style

- Logique simple en ligne : préférer les expressions inline plutôt que d'extraire des fonctions helper pour des opérations triviales (ex: appels `await sql` simples).
- Extraire des fonctions uniquement lorsque la réutilisation du code, la lisibilité ou la testabilité en bénéficient réellement.
