---
name: sklein-node-cli-libs
description: >
  Build a Node.js CLI with yargs following the Cobra/Viper pattern — subcommands,
  env vars, config files (TOML/YAML) with CLI > env > local config > global config >
  defaults priority. Use when creating a CLI in Node.js, adding subcommands, or
  setting up argument/env/config parsing.
---

# CLI Node.js avec yargs (pattern Cobra/Viper)

## Déclencheur

Ce skill est activé lorsque l'utilisateur demande de :

- Créer une CLI Node.js
- Ajouter des subcommands
- Mettre en place le parsing d'arguments, variables d'environnement ou fichiers de config
- Discuter de libraries CLI Node.js

## Choix de la librairie

`yargs` est le choix par défaut. Pas de comparaison à mener : le rationale est documenté dans [README.md](README.md).

## Révision périodique

Revoir ce choix à partir du **21 mai 2027** pour étudier si `yargs` reste le choix
le plus pertinent ou si une alternative est devenue meilleure.

## Fichiers de configuration : optionnel

Le support des fichiers de configuration (TOML/YAML) n'est **pas systématique**. Pour une CLI simple (peu d'options, usage local), s'en tenir aux flags CLI et aux variables d'environnement suffit.

L'agent doit **demander à l'utilisateur** s'il souhaite un support de fichiers de configuration avant de l'implémenter.

Si le support est retenu, les librairies sont :
- **TOML** : [`smol-toml`](https://github.com/smikitky/smol-toml) (0 dep, ~2 kB)
- **YAML** : [`js-yaml`](https://github.com/nodeca/js-yaml) (1 dep, ~5 kB)

Pas de `dotenv` : `.env('PREFIX')` lit `process.env` et mappe les variables préfixées vers les noms d'options.

## Pattern Cobra/Viper (sans fichiers de config)

Ordre de chargement et priorité :

```
Chargement : env vars → CLI flags
Priorité   : CLI flags > env vars > defaults
```

## Exemple minimal (CLI + env, sans fichier de config)

```js
import yargs from 'yargs'
import { hideBin } from 'yargs/helpers'

yargs(hideBin(process.argv))
  .env('MYAPP')
  .option('db-host', { type: 'string', default: 'localhost' })
  .option('api-token', { type: 'string' })
  .command('sync', 'Sync data', (yargs) => {
    yargs.option('force', { type: 'boolean', alias: 'f' })
  }, (argv) => {
    console.log(argv.dbHost, argv.apiToken)
  })
  .demandCommand(1, 'Use one of the available commands')
  .parse()
```

## Subcommands

```js
yargs(hideBin(process.argv))
  .env('MYAPP')
  .command(
    ['serve [port]', '$0'],
    'Start the server',
    (yargs) => {
      yargs.positional('port', {
        describe: 'Port to bind on',
        default: 3000,
        type: 'number',
      })
    },
    (argv) => console.log(`Serving on port ${argv.port}`)
  )
  .command('sync', 'Sync data', {}, (argv) => {
    console.log(`Syncing to ${argv.dbHost}`)
  })
  .demandCommand(1)
  .parse()
```

## Avec fichiers de configuration (optionnel)

Si l'utilisateur souhaite un support de fichiers de config, le pattern Cobra/Viper complet s'applique :

```
Chargement : global config → local config → env vars → CLI flags
Priorité   : CLI flags > env vars > local config > global config > defaults
```

```js
import { readFileSync, existsSync } from 'node:fs'
import { homedir } from 'node:os'
import { parse as parseToml } from 'smol-toml'

function loadConfig(path) {
  if (!existsSync(path)) return {}
  return parseToml(readFileSync(path, 'utf8'))
}

const globalConfig = loadConfig(`${homedir()}/.config/myapp/config.toml`)
const localConfig = loadConfig('./myapp.toml')

yargs(hideBin(process.argv))
  .config(globalConfig)
  .config(localConfig)
  .env('MYAPP')
  .option('db-host', { type: 'string', default: 'localhost' })
  // ...
  .parse()
```

Emplacements conventionnels :
- Config globale : `~/.config/<app>/config.toml` (ou `.yaml`)
- Config locale : `./<app>.toml` (ou `.yaml`)

## Comportement de l'agent

- Utiliser `yargs` pour toute nouvelle CLI Node.js.
- **Toujours demander** à l'utilisateur s'il souhaite un support de fichiers de configuration avant de l'implémenter.
- Pour une CLI simple, ne pas proposer de fichiers de config.
- Utiliser `smol-toml` pour le TOML, `js-yaml` pour le YAML (si config retenue).
- Toujours charger les sources dans l'ordre de priorité croissante (les dernières surchargent les premières).
- Ne pas proposer `dotenv` — `.env('PREFIX')` le remplace.
- Ne pas proposer de librairies alternatives (`commander`, `cac`, `citty`, `oclif`, etc.).
