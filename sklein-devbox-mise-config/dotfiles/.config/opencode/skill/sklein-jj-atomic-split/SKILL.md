---
name: sklein-jj-atomic-split
description: "Décompose un commit Jujutsu (jj) en plusieurs commits atomiques — enrichis si nécessaire pour la cohérence — par itérations récursives, avec validation humaine avant chaque application."
---

# sklein-jj-atomic-split

Décompose un commit Jujutsu en plusieurs commits atomiques par itérations récursives :
chaque itération extrait un commit par `jj split`, l'enrichit si nécessaire pour le
rendre cohérent et autonome, puis boucle sur le reste. Validation humaine avant chaque
application.

## Prérequis

- `opencode`
- `jj` >= 0.20
- `jj-hunk` (installable via `cargo install jj-hunk`)
- Working copy propre (`@` must have no diff against its parent)

## Paramètre

| Paramètre | Obligatoire | Description |
|-----------|-------------|-------------|
| `--revision` / `-r` | Oui | Le commit jj à décomposer |
| `--ignore-immutable` | Non (flag) | Autoriser la modification d'un commit immutable |

Exemple d'appel : `opencode --prompt "Décompose le commit jj --revision vrxktnropytru in commits atomiques"`

## Doctrine des commits atomiques

Un commit atomique doit répondre à **un seul "single concern"** parmi :

- **Correction de bug** — répare un comportement incorrect
- **Refactoring stable et motivé** — changement de structure sans altération de comportement
- **Fonctionnalité** — ajout incrémental de valeur
- **Enabler** — exceptionnellement, prérequis pour une fonctionnalité trop grosse

Chaque commit doit être le plus petit incrément qui apporte de la valeur au projet.
Un commit ne doit jamais servir de backup ou contenir des étapes sans sens propre.

## Workflow itératif

Le découpage ne planifie pas tous les commits à l'avance. Chaque itération
extrait **un seul commit atomique** du reste, l'enrichit si nécessaire pour
le rendre cohérent et autonome, puis boucle sur le reste.
`ATOMIC-SPLIT-PLAN.md` est un journal incrémental — mis à jour après chaque
itération avec le commit produit et l'enrichissement effectué.

```
commit source
  → itération 1 : analyser → split → enrichir → [commit1] + [reste]
  → itération 2 : analyser le reste → split → enrichir → [commit2] + [reste]
  → ... jusqu'à ce qu'il ne reste qu'un seul concern
```

### Étape 1 — Check

L'agent appelle le script helper :

```bash
atomic-split.sh check
```

Ce script vérifie :
- `jj-hunk` est disponible dans `$PATH`
- Le working copy est propre (`jj diff -r @` est vide)
- Si échec : message d'erreur clair et arrêt

### Étape 2 — Analyser le premier commit à extraire

L'agent lit le diff source pour identifier **le premier concern à extraire**
— le plus indépendant, celui qui peut être isolé du reste.

Commandes à exécuter :

```bash
jj diff --summary -r <rev>
jj show <rev>
jj-hunk list --rev <rev>
```

L'agent doit :

1. **Analyser le diff complet** (`jj show`) pour comprendre l'intention globale
2. **Identifier le concern le plus indépendant** :
   - **Suppressions pures** → priorité, extraire en premier
   - **Renommages** (même contenu, chemin différent) → priorité
   - **Ajouts de fichiers** → extraire si sans dépendance
   - **Modifications** → analyser le contenu des hunks pour identifier le
     single concern
   - Si un même fichier contient des changements appartenant à deux concerns
     différents, l'agent utilise les hunks individuels (`jj-hunk list`) pour
     les séparer
3. **Signaler les enrichissements probables** pour ce premier commit
   — sans en connaître le contenu exact — sous forme de notes :
   - « README.md sera probablement à mettre à jour »
   - « Un export manque dans src/index.ts »

Si le diff n'a qu'un seul single concern, l'agent annonce le split terminé
et s'arrête.

### Étape 3 — Plan du premier commit

L'agent consigne le premier commit proposé dans `ATOMIC-SPLIT-PLAN.md`.
Ce fichier est un **journal incrémental** — chaque itération y ajoute
son commit, l'enrichissement effectué, et son message.

Le message original du commit source est **jeté**. Chaque nouveau commit reçoit
un message neuf décrivant uniquement son single concern.

Format Markdown attendu :

```markdown
# Atomic split journal for <rev>

Source commit: <change-id>
Original message: "..."

## Itération 1
### Commit 1: <message>
**Files:** path/to/file1, path/to/file2
**Enrichissement probable:** README.md (à confirmer après split)
**Rationale:** Pourquoi ce regroupement...
```

Une fois le plan écrit, l'agent informe l'humain :

> Le premier commit proposé est dans ATOMIC-SPLIT-PLAN.md.
> Relis-le, modifie-le si besoin, puis dis "ok" pour passer au split.

### Étape 4 — Validation humaine

L'humain valide ou ajuste le **premier commit seulement**. L'agent attend
la confirmation explicite avant de passer à l'étape 5.

### Étape 5 — Split + Enrichissement

**Règle de sécurité :** `jj split` est exécuté avec `--no-integrate-operation`.

1. Générer le fichier de spec JSON pour `jj-hunk` correspondant au premier
   commit
2. Split :

   ```bash
   atomic-split.sh split <rev> <spec-file> "<message>"
   ```

3. Le script retourne l'opération ID
4. Noter l'opération ID pour l'étape d'application
5. **Inspection du commit atomique isolé :**
   - L'agent lit l'état du commit extrait
   - Identifie les lacunes de cohérence :
     - Le README reflète-t-il l'état après ce commit ?
     - Les exports / index sont-ils à jour ?
     - La documentation est-elle cohérente ?
     - Y a-t-il des ajustements évidents nécessaires ?
6. **Enrichissement :**
   - L'agent propose le contenu d'enrichissement à l'humain
   - Si validation :
     `jj edit <commit-extrait>` → appliquer l'enrichissement → `jj squash`
   - Si le contenu est trivial (export manquant, ajustement mécanique),
     l'agent peut appliquer sans validation et le documenter
7. Mettre à jour `ATOMIC-SPLIT-PLAN.md` avec le détail de l'enrichissement
   effectué

Le reste (ce qui n'a pas été extrait) devient la cible pour l'itération
suivante.

### Étape 6 — Boucle

Le « reste » devient le nouveau commit source.

- Si le reste a **plus d'un single concern** → retour à l'étape 2
- Si le reste n'a **qu'un seul concern** → on le conserve. Enrichissement
  optionnel : inspection → proposition → validation → application.
  Puis passage à l'étape 7.
- Si le reste est **vide** → passage à l'étape 7

Illustration récursive :

```
commit originel
  → itération 1 : split → [commit1 enrichi] + [reste]
  → itération 2 : split du reste → [commit2 enrichi] + [reste]
  → ... → [commitN] + [rien]
```

### Étape 7 — Inspection globale + Application

L'agent montre le résultat final à l'humain :

1. Appelle `jj --at-op=<dernier-op-id> log` pour afficher la nouvelle stack
2. Met à jour `ATOMIC-SPLIT-PLAN.md` avec les IDs de commit réels
3. Demande validation : "OK pour appliquer définitivement ?"

Après validation :

```bash
atomic-split.sh integrate <op-id-1> <op-id-2> ... <op-id-N>
```

Puis :

```bash
atomic-split.sh cleanup ATOMIC-SPLIT-PLAN.md
```

## Script helper

Le skill inclut `scripts/atomic-split.sh`. Interface :

```
atomic-split.sh check                        # Vérifie préconditions
atomic-split.sh list <rev>                   # jj-hunk list --rev <rev> (sortie JSON)
atomic-split.sh split <rev> <spec-file> <msg> # jj split --no-integrate-operation --tool=jj-hunk
atomic-split.sh integrate <op-id>...         # jj op integrate pour chaque op
atomic-split.sh plan-init <rev> <output>     # Template Markdown initial (optionnel)
atomic-split.sh cleanup <plan-file>          # Supprime le plan Markdown
```

**IMPORTANT :** Pour chaque opération jj invoquée par le script, utiliser le
flag `--quiet` pour éviter les sorties parasites que l'agent aurait à parser.

## Gestion des erreurs

### Cas 1 : `jj split` échoue (hunks ambigus, conflit)

1. L'agent annule les opérations sandbox déjà faites (`jj op undo` x N)
2. L'agent affiche l'erreur à l'humain
3. L'agent propose : ajuster le plan ou abandonner

### Cas 2 : Le plan ne correspond plus à la réalité

Si l'humain a modifié des fichiers entre la validation et la sandbox :
1. L'agent détecte l'écart (le diff a changé)
2. L'agent re-scanne et met à jour le plan
3. Retour à l'étape 4 (validation)

### Cas 3 : `jj op integrate` échoue

1. Les opérations sandbox restent orphelines (non intégrées)
2. L'agent diagnostique l'erreur
3. L'agent propose des actions correctives

## Format des specs jj-hunk

Les specs sont en JSON. Structure :

```json
{
  "files": {
    "path/to/file1": {"hunks": [0, 1]},
    "path/to/file2": {"action": "keep"},
    "path/to/file3": {"action": "reset"}
  },
  "default": "reset"
}
```

- `"hunks": [indices]` — sélectionne des hunks spécifiques (par index, pas par ID)
- `"action": "keep"` — garde tous les changements du fichier
- `"action": "reset"` — rejette tous les changements du fichier
- `"default": "reset"` — les fichiers non listés sont laissés dans le commit restant
- `"default": "keep"` — les fichiers non listés sont inclus dans le commit extrait

**Règle :** toujours utiliser `"default": "reset"` pour que le commit extrait ne
contienne que ce qui est explicitement listé. Le reste demeure dans le commit
parent pour les itérations suivantes.

## Conventions de commit

Utiliser le skill `sklein-git-commit-message` :
- Verbe impératif, présent, anglais
- Première lettre capitalisée
- Pas de point final
- Pas de préfixe conventional commit
- Verbes recommandés : `Add`, `Drop`, `Fix`, `Refactor`, `Rename`, `Move`, `Update`

## Invocation rapide

Un wrapper `~/bin/jj-atomic-split.sh` est fourni :

```bash
#!/usr/bin/env bash
set -euo pipefail
REV="${1:?Usage: jj-atomic-split.sh <revision>}"
opencode --prompt "Décompose le commit jj --revision ${REV} en commits atomiques"
```

## Fichiers temporaires

`ATOMIC-SPLIT-PLAN.md` est écrit à la racine du projet. Ce fichier doit être
ignoré par Git (ajouté au `.gitignore` du projet).
