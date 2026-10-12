---
name: sklein-utilitarian-ux
description: "Construire des interfaces web dans le style de GoatCounter, Miniflux, Hacker News, Lobsters, Sourcehut et Pinboard : fonctionnelles d'abord, sans distraction, rapides et tranchées. Utiliser cette skill chaque fois que l'utilisateur veut une interface « boring », « minimal », « fast », « utility-first », « indie dev », « FOSS-style » ou « no-nonsense », ou mentionne explicitement des outils comme GoatCounter, Miniflux, Pinboard, Lobsters, Sourcehut, Craigslist, HN-style comme références esthétiques. L'utiliser aussi quand il dit des choses comme « I don't want flashy », « just show the data », « developer tool », « self-hosted tool » ou « everything else is noise »."
---

# Utilitarian UX Skill

Construire des applications web qui incarnent la philosophie de GoatCounter et Miniflux : **la fonction avant la forme, le contenu avant la décoration, la vitesse avant l'animation, l'utilité avant le marketing**.

Il ne s'agit PAS d'un exercice d'esthétique minimaliste. C'est une idéologie UX spécifique : un logiciel qui respecte le temps et l'intelligence de l'utilisateur en se mettant de côté.

> « The content is the most important thing. Everything else is just noise. » — Miniflux
>
> « Flashy things aren't necessarily better. In fact, they're not infrequently just worse UX. » — GoatCounter

---

## Philosophie centrale

### Ce que ce style EST

- **Fonction d'abord** : chaque élément gagne sa place en servant la tâche. Si vous ne pouvez pas expliquer pourquoi un élément de design existe, supprimez-le.
- **Densité lisible** : plus d'information par écran que le SaaS typique, mais organisée hiérarchiquement. Dense ≠ chaotique.
- **URL-driven state** : l'URL est la source de vérité pour l'état de l'interface. Pas d'état significatif caché dans du JS, pas de modale sans route dédiée, pas de perte d'état au refresh. Tout est partageable par copier-coller de l'URL.
- **Minimiser les clics** : navigation par liens texte directs, pas de dropdowns ou de hamburger menus. L'action la plus courante doit toujours être à un clic.
- **Boring is a feature** : une liste simple est souvent meilleure qu'une carte, un graphique ou une grille de cards. Les tableaux textes battent les dashboards pour la comparaison de données.
- **La vitesse comme UX** : perçue comme instantanée. Pas de loading skeletons, pas de spinners si évitable. SSR (server-side rendering) privilégié.
- **Agrégats utiles** : montrer ce qui aide à décider, pas ce qui impressionne. « 2.3 GB » pas « 2359296 bytes ». « il y a 7 min » pas « 2025-01-15T14:23:11+01:00 ».
- **Clavier d'abord** : raccourcis clavier pour les actions courantes. Une navigation qui fonctionne sans souris.
- **Accessibilité d'abord** : HTML sémantique, labels ARIA, pas d'encodage d'information par la couleur seule. Compatible avec les screen readers.
- **La friction comme signal** : la difficulté d'ajouter un élément décoratif est une feature, pas un bug. Si ça demande de l'effort pour l'ajouter, c'est peut-être que ça ne devrait pas être là.
- **Pas de dark pattern** : aucune interface conçue pour tromper, manipuler ou pousser à l'erreur. Le désabonnement est aussi simple que l'abonnement. Les cases ne sont pas pré-cochées contre l'intérêt de l'utilisateur.
- **Limites explicites** : les fonctionnalités indisponibles sont montrées comme telles, pas cachées. Un bouton désactivé a un `title` qui explique pourquoi, ou est remplacé par un message clair.
- **Clipboard sovereignty** : jamais de blocage du copier-coller. L'utilisateur contrôle son presse-papier.
- **Markdown natif** : le Markdown est supporté comme format de saisie et d'affichage. Pas d'éditeur propriétaire qui empêche l'export ou le copier-coller fidèle.

### Ce que ce style N'EST PAS

- Minimal ou cassé. Le résultat est un logiciel *complet* qui ne gaspille simplement pas d'espace.
- Moche par accident. La retenue est intentionnelle et cohérente.
- Mobile-last. Responsive, mais optimisé pour la lecture / le scan, pas pour les interactions tactiles lourdes.
- Un clone de Tailwind UI. Pas de card grids, pas de gradient hero sections, pas de « Get started for free » CTAs.
- Anti-TailwindCSS dogmatiquement. TailwindCSS est un outil ; ce sont les patterns qu'il rend faciles qui peuvent être problématiques.

### L'esthétique marketing SaaS (à éviter)

L'opposé de ce paradigme a un nom : l'**esthétique marketing SaaS**. Elle a émergé de l'influence de Stripe autour de 2014–2016 et a été industrialisée par Tailwind UI et shadcn/ui. Ses marqueurs :

- Hero section avec tagline en gros caractères, fond dégradé ou fond sombre avec particules
- Cards avec `border-radius: 12–16px` et `box-shadow` prononcé
- Dégradés sur le texte, les boutons, les fonds
- Dark mode comme fonctionnalité marketée, pas comme préférence système
- `font-weight: 500` utilisé comme décoration, pas comme hiérarchie
- Lucide/Heroicons sur chaque élément de liste même quand le texte suffit
- Animations fade-in déclenchées au scroll
- Trust badges (« SOC2 · 99.9% Uptime · 50k users »)
- CTAs avec `bg-gradient-to-r from-violet-500 to-indigo-500`

Cette esthétique est optimisée pour **convaincre un visiteur non technique en 10 secondes**, pas pour permettre à un utilisateur quotidien de travailler efficacement. C'est une esthétique de landing page appliquée à l'application entière — y compris les écrans où l'utilisateur est déjà convaincu et veut juste accomplir une tâche.

---

## Langage visuel

### Typographie

- **Police corps** : System stack ou une serif lisible. PAS Inter, PAS Space Grotesk.
  - Apps techniques / données : `system-ui, -apple-system, sans-serif` en 15–16px
  - Apps axées lecture : une serif (`Georgia`, `Charter`) en 17–18px, généreux line-height
- **Monospace** : `ui-monospace, 'Cascadia Code', 'Source Code Pro', monospace` pour le code, les nombres, les chemins
- **Line height** : 1.55–1.7 pour le corps. Les tableaux denses peuvent descendre à 1.35.
- **Font weight** : mostly regular (400). Gras avec parcimonie pour une vraie hiérarchie. Pas de `font-weight: 500` comme remplissage « medium ».
- **Échelle de tailles** : 13px (petit / meta), 15px (défaut), 18px (h3), 22px (h2), 28px (h1). Échelle serrée.

### Palette de couleurs

- **Fond** : `#fff` ou `#fafafa`. Pas de dark par défaut.
- **Texte** : `#1a1a1a` ou `#222`. Jamais de `#000` pur.
- **Texte secondaire** : `#666` ou `#777` pour les métadonnées, timestamps, labels.
- **Bordures** : `#ddd` ou `#e5e5e5`. Jamais de `box-shadow` pour la séparation — utiliser `border` ou les espaces blancs.
- **Accent** : UNE couleur, utilisée pour les liens, l'action principale, les états actifs. Informationnelle, pas décorative.
  - Bons choix : `#0066cc`, `#0077aa`, un teal foncé, un violet sourd.
  - Jamais un dégradé. Jamais un accent brillant qui agresse l'œil.
- **Danger/erreur** : `#cc0000`, utilisé uniquement pour les vraies erreurs.
- **Succès** : seulement quand l'utilisateur a besoin de confirmer que quelque chose a fonctionné. Pas comme garniture verte décorative.

```css
:root {
  --bg: #fff;
  --bg-subtle: #f7f7f7;
  --border: #ddd;
  --text: #1a1a1a;
  --text-muted: #666;
  --link: #0066cc;
  --link-visited: #551a8b;
  --accent: #0066cc;
  --danger: #cc0000;
  --font: system-ui, -apple-system, sans-serif;
  --mono: ui-monospace, 'Cascadia Code', monospace;
  --max-width: 960px;
}
```

### Layout

- **Colonne unique, centrée** : `max-width: 960px` (chargé en données) ou `800px` (axé lecture), `margin: 0 auto`, padding horizontal modeste.
- **Pas de cards** : éviter les boîtes aux coins arrondis avec ombres portées pour grouper les données. Utiliser les espaces blancs, `<hr>`, ou une couleur de fond subtile.
- **Tableaux pour les données** : `<table>` est correct pour les données tabulaires. Le styliser simplement : border-bottom sur les lignes, pas de zebra stripes sauf nécessité.
- **Listes pour la navigation** : `<ul>` / `<ol>` sans puces pour les éléments de navigation. Les liens comme éléments interactifs.
- **Header** : petit, basé sur du texte. Logo = texte ou petite icône. Nav = liens texte. Pas de mega-menu.
- **Pas de hero sections** : les applications commencent par le contenu, pas par un pitch marketing.

### Espacement

- Unité de base : 8px
- Serré là où la densité compte (tableaux, listes) : 6–8px de padding vertical par ligne
- Généreux là où la lisibilité compte (articles, paramètres) : 24–32px d'écart entre sections
- Jamais de `padding: 40px` sur une ligne de données fonctionnelle

### Bordures et séparateurs

- Fin : `1px solid var(--border)`
- Jamais de `box-shadow: 0 4px 20px rgba(0,0,0,0.15)` pour les cards
- Règles fines entre les sections : `border-top: 1px solid #eee`

---

## Component Patterns

### Navigation

```html
<nav>
  <a href="/dashboard">Dashboard</a> ·
  <a href="/feeds">Feeds</a> ·
  <a href="/settings">Settings</a>
</nav>
```

Le séparateur `·` (middot) est canonique. `|` ou les espaces blancs sont aussi acceptables.

### Data Tables

```html
<table class="data-table">
  <thead>
    <tr><th>Path</th><th>Visitors</th><th>Views</th></tr>
  </thead>
  <tbody>
    <tr>
      <td><a href="/blog/post-1">/blog/post-1</a></td>
      <td>142</td>
      <td>198</td>
    </tr>
  </tbody>
</table>
```

```css
.data-table { width: 100%; border-collapse: collapse; font-size: 14px; }
.data-table th { text-align: left; font-weight: 600; border-bottom: 2px solid var(--border); padding: 6px 8px; color: var(--text-muted); font-size: 12px; text-transform: uppercase; letter-spacing: .05em; }
.data-table td { padding: 6px 8px; border-bottom: 1px solid var(--border); }
.data-table tr:hover td { background: var(--bg-subtle); }
.data-table td:last-child, .data-table th:last-child { text-align: right; }
```

### Boutons

```css
.btn { display: inline-block; padding: 6px 14px; font-size: 14px; border: 1px solid var(--accent); background: var(--accent); color: #fff; border-radius: 3px; cursor: pointer; text-decoration: none; }
.btn:hover { background: #0055bb; }
.btn-ghost { background: transparent; color: var(--accent); }
.btn-ghost:hover { background: var(--bg-subtle); }
.btn-danger { background: var(--danger); border-color: var(--danger); }
```

Pas de gros boutons pill. Pas de boutons dégradés. Pas d'ombre au hover.

### Formulaires

```css
input[type=text], input[type=email], input[type=password], select, textarea {
  width: 100%; padding: 6px 8px; border: 1px solid var(--border); border-radius: 3px;
  font: inherit; font-size: 14px; background: #fff;
}
input:focus, select:focus, textarea:focus {
  outline: 2px solid var(--accent); outline-offset: -1px; border-color: var(--accent);
}
label { display: block; font-size: 13px; font-weight: 600; margin-bottom: 4px; }
.form-hint { font-size: 12px; color: var(--text-muted); margin-top: 3px; }
```

Pas de floating labels. Pas d'animated placeholders. Label au-dessus de l'input, toujours.

### Page de connexion

La page de connexion est le test le plus révélateur de ce paradigme. Le réflexe SaaS est de centrer une card verticalement sur la page (`min-height: 100vh` + `display: flex` + `align-items: center`). **C'est l'anti-pattern Bootstrap.** Ça crée une boîte flottante qui signale « page marketing » au lieu d'« outil ».

L'approche correcte : la page de connexion est une page normale dans le flux du document. Elle a le même header que toutes les autres pages. Le formulaire se trouve dans `<main>`, aligné à gauche comme tout le reste du contenu.

```html
<header>
  <a href="/">AppName</a>
</header>

<main>
  <h1>Sign in</h1>
  <form method="POST" action="/login" style="max-width: 340px">
    <div class="field">
      <label for="email">Email</label>
      <input type="email" id="email" name="email" autocomplete="email" autofocus required>
    </div>
    <div class="field">
      <label for="password">Password</label>
      <input type="password" id="password" name="password" autocomplete="current-password" required>
    </div>
    <div class="actions">
      <button type="submit">Sign in</button>
      <a href="/forgot-password">Forgot password?</a>
    </div>
  </form>
</main>
```

Détails clés : `autofocus` sur le premier champ (le seul geste UX « actif » de la page). `max-width: 340px` sur le formulaire, pas sur une card wrapper. Pas de checkbox « Remember me » — c'est le comportement par défaut. Pas de lien « Create account » si l'app est self-hosted sans inscription publique.

Voir les pages dans `references/` (`login.html`, `signup.html`, `forgot-password.html`, `profile.html`, `users.html`, `time-entries.html`, `admin-settings.html`, `admin-users.html`) pour des exemples complets fonctionnels.

### Statuts / Badges

```css
.badge { display: inline-block; padding: 1px 6px; font-size: 11px; border-radius: 2px; font-weight: 600; }
.badge-ok   { background: #e6f4ea; color: #1a7f37; border: 1px solid #acd3b0; }
.badge-warn { background: #fff8e1; color: #856404; border: 1px solid #f0c36d; }
.badge-err  { background: #fde8e8; color: #cc0000; border: 1px solid #f5b8b8; }
```

Discrets, pas néon. Basés sur du texte, pas uniquement sur des icônes.

### Empty States

```html
<p class="empty">No entries yet.</p>
```

```css
.empty { color: var(--text-muted); font-style: italic; padding: 24px 0; }
```

Pas d'illustrations. Pas de copie « Start your journey! ».

### Error pages

Les pages d'erreur suivent le même flux de document que le reste de l'application : header, main, footer. Pas de centrage vertical, pas d'illustration, pas de branding « désolé ».

```html
<header>
  <a href="/">AppName</a>
  <nav>
    <a href="/dashboard">Dashboard</a> ·
    <a href="/settings">Settings</a>
  </nav>
</header>

<main>
  <p class="error-code">404</p>
  <h1>Page not found</h1>
  <p class="error-desc">This page doesn't exist or has been moved.</p>
  <div class="error-actions">
    <a href="/" class="btn">Go to dashboard</a>
    <a href="javascript:history.back()" class="btn btn-ghost">Go back</a>
  </div>
</main>

<footer>
  <a href="/docs">Documentation</a> ·
  <a href="/status">Status</a>
</footer>
```

```css
.error-code { font-family: var(--mono); font-size: 13px; font-weight: 700; color: var(--text-muted); text-transform: uppercase; letter-spacing: .08em; margin-bottom: 10px; }
.error-code.is-danger { color: var(--danger); }
.error-desc { font-size: 15px; color: var(--text-muted); margin-bottom: 24px; max-width: 480px; }
.error-actions { display: flex; gap: 12px; align-items: center; flex-wrap: wrap; }
```

**Variantes par code :**

| Code | Badge | Comportement |
|------|-------|-------------|
| 404 | `error-code` | Navigation normale. Actions : dashboard + go back. |
| 403 | `error-code is-danger` | Navigation normale. Action : dashboard + contact admin. |
| 500 | `error-code is-danger` | Navigation normale. Actions : reload + dashboard + status. Détails techniques dans `<details>`. |
| 503 | `error-code` | **Page isolée** — pas de header ni footer. Affiche la fenêtre de maintenance avec créneaux horaires. |

Les détails techniques (500 uniquement) utilisent `<details>` :

```html
<details>
  <summary>Technical details</summary>
  <pre>Error ID : a3f9c2d1-8b4e-4f12-9c7a-e6d0b5f1a8c3
Timestamp: 2025-07-07T14:23:01Z
Path     : /api/entries/sync
Message  : pq: connection refused (postgresql://localhost:5432)</pre>
</details>
```

Voir `references/error.html` pour la page de démonstration interactive et `examples/chefchef-theme/src/routes/+error.svelte` pour l'implémentation SvelteKit 5.

### Pagination

```html
<nav class="pagination">
  <a href="?page=1">« First</a>
  <a href="?page=3">‹ Previous</a>
  <span>Page 4 of 12</span>
  <a href="?page=5">Next ›</a>
  <a href="?page=12">Last »</a>
</nav>
```

Liens texte. Pas de groupes de boutons stylisés.

### Raccourcis clavier

```html
<kbd>j</kbd> / <kbd>k</kbd> — next / previous
<kbd>o</kbd> — open entry
<kbd>m</kbd> — mark as read
```

```css
kbd { font-size: 11px; padding: 1px 5px; border: 1px solid #ccc; border-bottom-width: 2px; border-radius: 3px; font-family: var(--mono); background: #f5f5f5; }
```

### Confirmation inline (pas de modal)

Les confirmations apparaissent inline, à côté du bouton qui les a déclenchées. Pas de modal. C'est une conséquence directe du principe **URL-driven state** : une modale cache l'état dans du JS, n'a pas d'URL propre, et ne peut pas être partagée.

```html
<span class="inline-confirm" hidden>
  Are you sure? <a href="/delete/123">Yes, delete</a> · <button onclick="this.closest('.inline-confirm').hidden=true">Cancel</button>
</span>
```

---

## Anti-patterns

| À éviter | Utiliser à la place |
|----------|-------------------|
| Card grid avec ombres | Data table ou liste simple |
| Sidebar avec icônes uniquement | Liens de navigation textuels |
| Animations de loading skeleton | Rendu rapide ou texte simple « Loading… » |
| Empty state avec illustration SVG | Texte en italique simple |
| Modal sans route dédiée / état dans du JS | Page dédiée avec URL partageable |
| Modal pour chaque confirmation | Confirmation inline ou page dédiée |
| Tooltip sur tout | Label visible ou `<abbr title="">` |
| Progress bar pour du non-progress | Statut texte (« Saved », « 3 of 10 done ») |
| Sticky header qui mange 80px | Flux de document normal |
| Hero section avec dégradé | Commencer directement par le contenu |
| CTA « Get Started » avant login | Juste le formulaire de connexion |
| Dark mode toggle comme fonctionnalité | Support via `prefers-color-scheme` uniquement |
| Accent néon / saturé | Accent discret, informatif, bleu ou teal |
| `border-radius: 16px` | `border-radius: 3px` max |
| Formulaire de connexion centré verticalement | Formulaire de connexion dans le flux normal du document |
| `min-height: 100vh` + flex center | `<main>` dans le flux du document avec `padding-top` |

---

## JavaScript Policy

**JS seulement là où c'est nécessaire.**

- Utiliser JS pour : les raccourcis clavier, la validation de formulaire inline, la navigation SPA, les labels time-ago, ProseMirror / rich text editors.
- Ne pas utiliser JS pour : les animations décoratives, les dropdowns qui pourraient être des `<details>`, les tabs qui pourraient être des liens.
- **JS minimal et contextuel** : pas de manipulation DOM directe là où le framework le fait.
  - Avec **Svelte/SvelteKit** : réactivité et bindings (`bind:this`, `$state`, `{#each}`). Pas de `querySelector` dans un composant.
  - Avec **htmx** : `hx-*` attributes pour toute interaction ; JS réservé aux extensions et event handlers.
  - `fetch` uniquement si pas d'API framework disponible (ex. appels externes non-HTML en htmx).
- Pas de bibliothèques d'animation. Pas de Framer Motion. CSS `transition` ≤ 150ms sur les changements d'état fonctionnels (hover, focus) uniquement.

**Sur les rich text editors** : ProseMirror est compatible avec ce paradigme quand il est implémenté avec retenue. Une toolbar minimale (`B I _ | " | {} | ⌘K`) est acceptable. Ce qu'il faut éviter : les floating toolbars au survol de la sélection (style Notion), les color pickers, les dropdowns de taille de police, les sélecteurs `font-family`. Le schema doit contraindre ce qui est possible, pas tout exposer.

---

## Tailwind CSS Policy

Tailwind n'est **pas proscrit**, mais il porte un risque spécifique dans ce paradigme : il rend l'esthétique marketing SaaS trivialement facile à produire. La discipline requise :

**Utilisation acceptable de Tailwind :**
```html
<!-- Layout, spacing, responsive — OK -->
<div class="flex items-center gap-4 mt-6">
<table class="w-full text-sm">
<nav class="border-b border-gray-200 py-2">
```

**Utilisation interdite de Tailwind :**
```html
<!-- Décoration, dégradés, ombres lourdes — on s'arrête là -->
<div class="rounded-2xl shadow-xl p-8 bg-white">
<button class="bg-gradient-to-r from-violet-500 to-indigo-500 rounded-full">
<div class="animate-pulse bg-gray-200 h-4 rounded">  <!-- skeleton loader -->
```

**Le test** : si la classe Tailwind fait du travail de layout ou d'espacement, c'est OK. Si elle fait du travail de décoration visuelle, écrire du vanilla CSS à la place — la friction est intentionnelle.

**Ne jamais utiliser les blocs de composants Tailwind UI ou shadcn/ui** comme source. Leurs composants encodent l'esthétique marketing SaaS au niveau du design, pas seulement au niveau du CSS.

---

## Structure de page

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Page Title — AppName</title>
</head>
<body>
  <header>
    <div class="container">
      <a href="/" class="site-name">AppName</a>
      <nav>
        <a href="/section-a">Section A</a> ·
        <a href="/section-b">Section B</a> ·
        <a href="/settings">Settings</a>
      </nav>
    </div>
  </header>

  <main class="container">
    <h1>Page Title</h1>
    <!-- Content immediately. No hero. No empty padding. -->
  </main>

  <footer>
    <div class="container">
      <a href="/docs">Docs</a> · <a href="/about">About</a>
    </div>
  </footer>
</body>
</html>
```

```css
*, *::before, *::after { box-sizing: border-box; }
body { margin: 0; font: 15px/1.6 var(--font); color: var(--text); background: var(--bg); }
.container { max-width: var(--max-width); margin: 0 auto; padding: 0 20px; }
header { border-bottom: 1px solid var(--border); padding: 8px 0; }
header .container { display: flex; align-items: center; justify-content: space-between; }
.site-name { font-weight: 700; color: var(--text); text-decoration: none; }
nav a { color: var(--text-muted); text-decoration: none; font-size: 14px; }
nav a:hover { color: var(--link); text-decoration: underline; }
main { padding: 24px 0 48px; }
h1 { font-size: 22px; font-weight: 700; margin: 0 0 20px; }
h2 { font-size: 18px; font-weight: 700; margin: 32px 0 12px; border-bottom: 1px solid var(--border); padding-bottom: 6px; }
a { color: var(--link); }
a:visited { color: var(--link-visited); }
footer { border-top: 1px solid var(--border); padding: 12px 0; font-size: 13px; color: var(--text-muted); }
```

---

## Notes SvelteKit / React

- **Pas de bibliothèque de composants UI** par défaut (pas de shadcn, pas de Chakra, pas de Radix). Écrire le petit peu de CSS nécessaire.
- **Pas de CSS-in-JS**. Un seul fichier `.css` ou bloc `<style>`.
- **Tailwind** : acceptable avec la discipline décrite ci-dessus.
- **Pas d'imports d'animation**.
- SSR / server components par défaut.
- `<table>` est un élément Svelte/React valide. L'utiliser pour les données tabulaires sans culpabilité.
- Les composants se justifient par un **comportement répété**, pas par un markup répété. Un `<DataTable>` avec 15 props est du HTML inline qui est devenu trop ambitieux.
- `examples/chefchef-theme/` — implémentation SvelteKit 5 + UnoCSS des mêmes écrans que `references/`.

---

## Références esthétiques

- [Hacker News](https://news.ycombinator.com) — idéal platonicien de densité sans chaos
- [Lobste.rs](https://lobste.rs) — HN avec un peu plus d'air
- [Sourcehut](https://sr.ht) — le manifeste le plus explicite ; Drew DeVault a mesuré le poids des pages
- [Pinboard](https://pinboard.in) — bookmarking qui respecte votre temps
- [GoatCounter](https://www.goatcounter.com) — données par ligne, navigation textuelle
- [Miniflux](https://miniflux.app) — optimisé pour la lecture, piloté au clavier

Si un nouvel élément d'UI ressemble à quelque chose qui appartiendrait à une landing page marketing, supprimez-le.
