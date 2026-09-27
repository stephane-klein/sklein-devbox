---
name: sklein-orthographe
description: Correction orthographique et grammaticale rigoureuse de fichiers Markdown en deux phases. Analyse exhaustive → fichier YAML des erreurs → validation manuelle → correction en une passe. Use when user says "analyze errors", "apply corrections", "orthographe", "grammaire", "correction ortho", ou demande de corriger les fautes d'un fichier .md.
---

# sklein-orthographe

Correction orthographique/grammaticale de fichiers Markdown en **deux phases** :
1. **Analyse** — détecte toutes les erreurs, produit `~/.corrections/fichier-source-erreurs.yaml`
2. **Application** — après validation manuelle, corrige tout en une passe

## Prérequis

- Le fichier cible est un `.md`
- Le dossier `~/.corrections/` est créé automatiquement s'il n'existe pas

---

## Phase 1 — Analyse

Commande : `analyze errors in chemin/vers/fichier.md`

Le skill :
1. Lit le fichier `.md` cible
2. Exclut de l'analyse :
   - Les blocs de code \`\`\`
   - Le code inline `` ` ``
   - Le frontmatter YAML (`---...---`) **sauf** les champs `title` et `aliases`
3. Détecte ligne par ligne les erreurs de :
   - **Orthographe** : mots mal écrits, homophones (ce/se, ou/où, etc.)
   - **Grammaire** : accords en genre/nombre, accords du participe passé, conjugaisons
   - **Ponctuation** : virgules, points, points-virgules manquants ou superflus
   - **Typographie française** : espaces insécables avant `:;!?%», guillemets français `« »`, apostrophes `'` courbes
   - **Wikilinks** : analyser le display text dans `[[cible|display]]` et le nom de cible
4. Contexte minimal : lire 3 lignes avant/après chaque ligne pour les accords distants
5. Produit `~/.corrections/fichier-source-erreurs.yaml`

### Format du YAML produit

```yaml
file: "chemin/vers/fichier.md"
errors:
  - line: 12
    column: 24
    original: "stocké"
    correction: "stockées"
    type: "accord"
    rule: "Accord du participe passé avec l'auxiliaire être"
  - line: 45
    column: 5
    original: "Il ce peut que"
    correction: "Il se peut que"
    type: "orthographe"
    rule: "Homophones ce/se"
```

Types possibles : `accord`, `conjugaison`, `orthographe`, `ponctuation`, `typographie`.

---

## Phase 2 — Application

1. Tu modifies `~/.corrections/fichier-source-erreurs.yaml` :
   - **Supprime** les lignes d'erreurs que tu ne veux PAS corriger
   - Ne change rien d'autre
2. Tu dis : `apply corrections from chemin/vers/fichier.md`

Le skill :
1. Vérifie que `~/.corrections/fichier-source-erreurs.yaml` existe avec au moins une entrée
2. Sauvegarde l'original dans `~/.corrections/fichier-source.md.bak` (n'écrase pas une sauvegarde existante)
3. **Trie les corrections de la dernière ligne à la première** (bottom-up) pour éviter les décalages de numéros de ligne
4. Pour chaque ligne avec plusieurs corrections : applique de droite à gauche
5. Applique **toutes** les corrections restantes dans le fichier source
6. Vérifie qu'aucune occurrence d'`original` ne subsiste dans le fichier corrigé (alerte si c'est le cas, sans bloquer)
7. Affiche le résumé : nombre de corrections appliquées, lien vers la sauvegarde

### Règles strictes

- **Tout corriger en une passe**. Ne laisser aucune erreur volontairement.
- Ne modifier **rien d'autre** que les corrections listées.
- Si plusieurs fichiers sont concernés, traiter un seul fichier à la fois.
- Ne jamais modifier le fichier YAML de son propre chef.
- Ne pas appliquer les corrections sans que le YAML ait été validé.

---

## Exemples

### Analyse

```
analyze errors in notes/ma-note.md
```

→ Génère `~/.corrections/ma-note-erreurs.yaml`

### Application

```
apply corrections from notes/ma-note.md
```

→ Sauvegarde → `~/.corrections/ma-note.md.bak`
→ Corrige le fichier source
→ Affiche le résumé
