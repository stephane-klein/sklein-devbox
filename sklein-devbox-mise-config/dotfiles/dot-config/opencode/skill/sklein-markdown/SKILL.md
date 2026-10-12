---
name: sklein-markdown
description: "Préférences Markdown de Stéphane Klein. Conventions de formatage pour les listes, les tableaux, la structure et la mise en forme."
---

# sklein-markdown

Conventions de formatage Markdown pour toute rédaction.

## Général

- Utiliser `-` pour les listes à puces (pas `*`).
- Utiliser `**gras**` pour l'emphase (pas `__gras__` ni `*italique*` pour l'emphase principale).

## Listes

### Espacement des listes

**Format préféré** : une ligne vide sépare le paragraphe introductif de la liste, mais pas de ligne vide au sein de la liste.

```markdown
Paragraphe:

- item 1
- item 2
  - item 2.1
  - item 2.2
- item 3
```

**Format à éviter** : pas de ligne vide entre le paragraphe et la liste, ni de ligne vide au milieu de la liste.

```markdown
Paragraphe:
- item 1
- item 2
  - item 2.1
  - item 2.2

- item 3
```

### Listes imbriquées

- Utiliser 2 espaces pour l'indentation des sous-listes.
- Ne pas insérer de ligne vide entre un item parent et ses enfants.

## Tableaux

- Utiliser des tableaux Markdown avec les colonnes alignées via les deux-points `:`.
- Aligner à gauche `:---`, centrer `:---:`, aligner à droite `---:`.

Exemple :

```markdown
| Colonne 1 | Colonne 2 | Colonne 3 |
|:----------|:---------:|----------:|
| Gauche    | Centré    | Droite    |
```

## Terminal sessions

### Convention d'affichage

- Les lignes commençant par `$` indiquent une commande utilisateur.
- Les lignes commençant par `#` indiquent une commande root.
- Les lignes sans préfixe sont la sortie du terminal.
- Les commentaires en fin de ligne utilisent `# …`.

```markdown
$ echo "Hello, world!"
Hello, world!

$ sudo su
# systemctl restart nginx
$ exit

$ uptime # Affiche l'uptime
```

### Toujours utiliser `$` (y compris sans sortie)

Contrairement à la règle MD014 (omettre `$` quand il n'y a pas de sortie), **toujours préfixer les commandes par `$`**, même si le bloc ne contient que des commandes sans sortie.

Justification : dans une documentation qui mélange fichiers de configuration et commandes, l'absence de `$` crée une ambiguïté entre ce qui est à exécuter et ce qui est de la configuration.

### Ces blocs sont des "screenshots" explicatifs

Ils n'ont pas vocation à être copiés/collés en masse. Si un groupe de commandes est fréquemment copié, le remplacer par un script helper (voir `sklein-helper-scripts`).

## Liens vers dossiers

Quand un README liste les dossiers d'un projet, chaque entrée doit être un lien
cliquable vers le dossier concerné :

```markdown
- [`01-fedora-minimal-mutable/`](./01-fedora-minimal-mutable/) — Description.
- [`02-fedora-minimal-bootc/`](./02-fedora-minimal-bootc/) — Description.
```

Format : `` [`nom-dossier/`](./nom-dossier/) `` — backticks + slash + lien relatif.

## Scope

Ces conventions s'appliquent à tout Markdown, sauf si le projet concerné définit déjà ses propres conventions de formatage.
