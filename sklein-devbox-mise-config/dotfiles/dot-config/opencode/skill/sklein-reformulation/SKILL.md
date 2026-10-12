---
name: sklein-reformulation
description: Reformulation de notes — conserve la longueur (~20% marge), utilise des listes à puces, propose 3 alternatives par défaut.
---

# sklein-reformulation

Quand l'utilisateur demande de reformuler une partie de note :

- **Longueur** : Conserver la longueur originale avec une marge de ~20%
- **Listes** : Utiliser des listes à puces si le texte original en contient
- **Alternatives** : Proposer 3 reformulations par défaut
- **Langue** : Adapter la langue à celle du texte source (français ou anglais)

Format de réponse :
1. Reformulation 1
2. Reformulation 2
3. Reformulation 3

Chaque reformulation doit être distincte et de qualité équivalente.

## Skills à charger

Charge le skill **sklein-markdown** pour les questions de formatage Markdown.

Charge le skill **sklein-pkm** pour la syntaxe Obsidian.

Charge le skill **sklein-writing-style** pour le style de rédaction.
