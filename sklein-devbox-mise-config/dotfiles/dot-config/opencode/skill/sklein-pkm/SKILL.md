---
name: sklein-pkm
description: "Conventions pour la rédaction dans le PKM (Personal Knowledge Management) de Stéphane Klein sur notes.sklein.xyz. Utilise la syntaxe Obsidian."
---

# sklein-pkm

Conventions spécifiques à la rédaction dans le PKM avec la syntaxe Obsidian.

## Liens et références

- Conserver les WikiLinks existants `[[...]]`.
- Conserver les hashtags existants `#...`.
- Ne pas transformer les WikiLinks en liens Markdown standard `[texte](url)`.

## Syntaxe

- Ce PKM utilise la syntaxe Obsidian.
- Privilégier les fonctionnalités Markdown compatibles avec Obsidian.

## Citations

Pour les citations, utiliser le format callout Obsidian suivant :

```markdown
> [!quote]
>
>  Texte de la citation, potentiellement sur plusieurs paragraphes.
>
> [source](url){.source}
```

- Utiliser le callout `> [!quote]` pour encadrer la citation.
- Indenter le contenu du callout avec deux espaces.
- Placer la source à la fin du callout sous forme de lien Markdown avec la classe CSS `{.source}`.

## Mentions d'articles et de ressources

- Quand on mentionne un article, un livre ou toute ressource en ligne, toujours inclure un lien direct vers la source (URL).
- Ne pas se contenter du titre en italique ou du nom de l'auteur.
