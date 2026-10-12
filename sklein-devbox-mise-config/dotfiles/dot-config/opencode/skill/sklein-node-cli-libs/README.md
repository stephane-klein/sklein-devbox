# Rationnel — Choix de `yargs` pour les CLIs Node.js (mai 2026)

Ces choix reflètent l'expérience et les préférences personnelles de Stéphane Klein. Ils ne constituent pas une recommandation universelle.

SKILL créé avec DeepSeek V4 Pro.

## Contexte

Pour construire une CLI Node.js structurée avec subcommands, parsing de flags,
variables d'environnement et fichiers de configuration (TOML/YAML), avec une
chaîne de priorité **CLI > env > config local > config global > defaults** —
pattern inspiré de Cobra/Viper en Go.

Les fichiers de configuration sont lus par :

[`smol-toml`](https://github.com/smikitky/smol-toml) (0 dep, ~2 kB) ou
[`js-yaml`](https://github.com/nodeca/js-yaml) (1 dep, ~5 kB)

## Pattern Cobra/Viper avec `yargs`

Ordre de chargement (bottom-up) et priorité (top-down) :

```
Chargement : global config → local config → env vars → CLI flags
Priorité   : CLI flags > env vars > local config > global config > defaults
```

Exemple minimal :

```js
import yargs from 'yargs'
import { hideBin } from 'yargs/helpers'
import { readFileSync } from 'node:fs'
import { homedir } from 'node:os'
import { parse as parseToml } from 'smol-toml'
// import { load as parseYaml } from 'js-yaml' — selon besoin

const globalConfig = parseToml(
  readFileSync(`${homedir()}/.config/myapp/config.toml`, 'utf8')
)
const localConfig = parseToml(
  readFileSync('./myapp.toml', 'utf8')
)

yargs(hideBin(process.argv))
  .config(globalConfig)
  .config(localConfig)
  .env('MYAPP')
  .option('db-host', { type: 'string', default: 'localhost' })
  .option('api-token', { type: 'string' })
  .command('sync', 'Sync data', {}, (argv) => {
    console.log(argv.dbHost, argv.apiToken)
  })
  .parse()
```

`.env('PREFIX')` rend `dotenv` inutile : `yargs` lit directement `process.env`
et mappe les variables préfixées vers les noms d'options.

## Analyse selon la doctrine de dépendance

**§1.4 — La librairie réduit la complexité accidentelle.** `yargs` intègre
nativement les trois couches du pattern Cobra/Viper : `.env('PREFIX')` pour
mapper les variables d'environnement, `.config()` pour les fichiers de
configuration (JSON natif, parser custom pour TOML/YAML), et la chaîne de
priorité intégrée. Avec les alternatives (`cac`, `commander`), il faut
implémenter manuellement le merge des sources — du glue code sans valeur métier.

**§1.5 — La librairie est en bonne santé.** 11.5k stars, 186M
téléchargements/semaine, release majeure en 2025 (v18), maintenance active.

**§2.3 — Complexité d'apprentissage.** Plusieurs expériences positives avec
`yargs` depuis mi-2022 → coût d'apprentissage nul pour Stéphane Klein.

**§2.5 — Coût de retrait futur faible.** Le parsing d'arguments est localisé
au point d'entrée de la CLI, sans contamination du code métier. Remplaçable
sans impact systémique.

## Comparaison détaillée

| Librairie   | Stars  | Création  | Dernière release | DL/semaine | Deps | Gzip   | Raison d'écartement                                            |
| ----------- | ------ | --------- | ---------------- | ---------- | ---- | ------ | -------------------------------------------------------------- |
| `cac`       | 3.1k   | 2016-01   | v7.0 (fév. 2026) | 35M        | 0    | 3.9 kB | Pas de support natif env/config file — glue code manuel requis |
| `commander` | 28.2k  | 2011-08   | v15.0 (mai 2026) | 391M       | 0    | 11 kB  | Idem — pas d'env/config file natif                             |
| `citty`     | 1.3k   | 2022-04   | v0.2 (avr. 2026) | 21M        | 0    | 3.6 kB | Valeur dans l'inférence TypeScript, sans objet en JS pur       |
| `cleye`     | 656    | 2022-01   | v2.6 (avr. 2026) | 274k       | 2    | 14 kB  | Idem — TS narrowing, sans objet en JS pur                      |
| `oclif`     | 9.5k   | 2018-01   | 4.23 (mai 2026)  | 7.2M       | 18   | ~200 kB | Framework monolithique (classes), incompatible style fonctionnel |
| `clipanion` | 1.2k   | 2017-04   | 4.0-rc.4 (sep. 2024) | 3.9M   | 1    | 10 kB  | Décorateurs de classe, paradigme OOP                           |

## Trade-off accepté

32 kB gzippés et 6 dépendances transitives, contre 3.9 kB / 0 deps pour `cac`.
Ce surcoût est acceptable car :

- Circonscrit à la couche CLI, pas dans le hot path métier.
- Évite d'écrire et maintenir du code de merge config/env/CLI.
- Les dépendances transitives sont stables et massivement déployées
  (186M DL/semaine cumulées).

## Conclusion

En mai 2026, `yargs` reste le choix qui minimise la complexité accidentelle
pour une CLI Node.js avec le pattern Cobra/Viper : env vars, fichiers de
config, subcommands et priorité des sources, le tout intégré nativement, sans
glue code.
