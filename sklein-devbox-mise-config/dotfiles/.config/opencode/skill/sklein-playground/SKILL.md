---
name: sklein-playground
description: >
  Créer ou itérer sur un playground (spike / POC) pour apprendre une
  technologie de fond en comble et lever tous les pièges avant la prod.
  À utiliser quand l'utilisateur dit "playground", "spike", "POC",
  "apprendre", "explorer", ou valide une techno pour la prod.
---

# sklein-playground

Un playground est un **terrain d'apprentissage systématique**. Contrairement
à un prototype (qui répond à une question précise et se jette), le playground
explore une techno de bout en bout, documente chaque obstacle, et produit
un savoir réutilisable pour la production.

## Principes

1. **Spike d'abord, prod ensuite** — on explore, on casse, on comprend, puis
   on industrialise. Le playground n'est pas la prod.
2. **Validation complète** — chaque chemin utile en prod (install, config,
   déploiement, upgrade, recovery) doit être testé ici.
3. **Pédagogique** — on avance pas à pas, chaque étape est documentée. Un
   futur lecteur (ou toi dans 6 mois) doit pouvoir suivre sans contexte.
4. **Pièges remontés** — chaque erreur, chaque contournement, chaque
   décision non-triviale est capturé (dans AGENTS.md, ADR, ou notes).

## Convention de nommage

Les repositories de playground portent le suffixe `-playground`
(ex: `fedora-bootc-playground`).

## Livrables attendus

À la fin du playground, on doit avoir :

- Un `AGENTS.md` à la racine qui résume le contexte, la structure et
  les décisions clés pour les agents IA
- Des scripts ou tâches reproduisibles
- La documentation des pièges et contournements rencontrés
- Une ou plusieurs ADR pour les décisions d'architecture difficiles à
  révoquer ou surprenantes sans contexte
- Une évaluation de l'aptitude à la production de chaque chemin validé

## Workflow recommandé

1. **Cadrer** — définir les objectifs, le périmètre et ce qu'on veut valider
2. **Explorer** — suivre le guide pas-à-pas upstream, noter les divergences
3. **Valider** — tester chaque chemin utile en prod (quickstart, config avancée,
   recovery, etc.)
4. **Documenter** — capturer les décisions, les pièges, les alternatives
5. **Évaluer** — est-ce prêt pour la prod ? Quels risques restent ?
