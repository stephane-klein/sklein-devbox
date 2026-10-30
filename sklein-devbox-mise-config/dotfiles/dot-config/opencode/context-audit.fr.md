# Audit du contexte OpenCode — 2026-10-30 15:52

Ce que la configuration OpenCode coûte en tokens avant le premier mot d’une conversation, et ce que cela coûte en dollars.

## Résumé

| | |
| --- | --- |
| Contexte fixe | **18 098 tokens** |
| dont votre configuration | 12 248 tokens (67,7 %) |
| dont OpenCode | 5 849 tokens (32,3 %) |
| non attribué | 1 tokens (0,0 %) |
| Part de la fenêtre de 1 000 000 tokens | 1,81 % |
| Modèle utilisé pour la tarification | `opencode-go/deepseek-v4.1-flash` |
| Par requête, cache froid | **0,00271 $** |
| Par requête, cache chaud | **0,00005 $** |
| Pour 1 000 requêtes | 2,71 $ / 0,0543 $ |

DeepSeek ne publie aucune durée de vie pour son cache : une entrée inutilisée est effacée « within hours to days ». Les deux colonnes correspondent donc à deux régimes réels, et non à une borne optimiste et une borne pessimiste.

## Conditions de mesure

| | |
| --- | --- |
| Répertoire | `/home/devbox` |
| Agent | `plan` |
| OpenCode | 2.2.0 |
| Serveurs MCP | 8 activés pour la mesure, 7 désactivés normalement |
| Cache observé pendant la mesure | 1 408 tokens servis depuis le cache |
| Coût facturé pour la mesure | non communiqué par le fournisseur |

Le total est mesuré : il correspond à `tokens.input + tokens.cache.read` du premier message assistant de la session, celui que le fournisseur a facturé. La répartition est estimée bloc par bloc avec le tokeniseur `o200k_base` de `ttok`, puis remise à l’échelle sur ce total (facteur 1.212271). Les proportions sont justes ; les valeurs par bloc sont à quelques pour cent près.

## Blocs système

| Bloc | Origine | Fichier | Tokens | Part |
| --- | --- | --- | ---: | ---: |
| Prompt de base | `OpenCode` | — | 362 | 2,0 % |
| Modèle | `OpenCode` | — | 44 | 0,2 % |
| Liste des skills | `config` | — | 457 | 2,5 % |
| Environnement OpenCode | `OpenCode` | — | 79 | 0,4 % |
| AGENTS.md global | `config` | ~/.config/opencode/AGENTS.md | 828 | 4,6 % |
| [Code Mode](https://github.com/anomalyco/opencode/blob/v2.2.0/packages/codemode/README.md) | `OpenCode` | — | 1 867 | 10,3 % |
| Note worktree | `OpenCode` | — | 57 | 0,3 % |
| **Total des blocs système** | | | **3 694** | 20,4 % |

Code Mode est un interpréteur restreint pour un langage de type JavaScript : le modèle appelle des outils du catalogue au lieu de les invoquer un par un. Seuls les blocs d’origine `config` peuvent être réduits ; les autres sont produits par le binaire.

### Extraits

**Prompt de base** — [packages/core/src/session/runner/prompt/system.txt](https://github.com/anomalyco/opencode/blob/v2.2.0/packages/core/src/session/runner/prompt/system.txt)
> You are an AI agent running in OpenCode, a coding agent harness. Help the user accomplish their goal…
> # Harness
> - Responses are rendered as GitHub-flavored Markdown.

**Modèle** — [packages/core/src/plugin/identity.ts](https://github.com/anomalyco/opencode/blob/v2.2.0/packages/core/src/plugin/identity.ts)
> # Your Model
> - Name: DeepSeek V4.1 Flash
> - Provider ID: opencode-go

**Environnement OpenCode** — [packages/core/src/instructions/builtins.ts](https://github.com/anomalyco/opencode/blob/v2.2.0/packages/core/src/instructions/builtins.ts)
> # Code Mode
> Use the `execute` tool to call the tools listed below. They cannot be called directly. They only wor…
> The catalog is complete. Do not guess tool names.

**Code Mode** — [packages/core/src/codemode/instructions.ts](https://github.com/anomalyco/opencode/blob/v2.2.0/packages/core/src/codemode/instructions.ts)
> # Code Mode
> Use the `execute` tool to call the tools listed below. They cannot be called directly. They only wor…
> The catalog is complete. Do not guess tool names.

**Note worktree** — [packages/core/src/tool/plugin/opencode.ts](https://github.com/anomalyco/opencode/blob/v2.2.0/packages/core/src/tool/plugin/opencode.ts)
> When you create a worktree outside the current working directory and intend to use it as your primar…

## Outils

| Élément | Origine | Outils | Tokens | Part |
| --- | --- | ---: | ---: | ---: |
| `playwright` | `config` | 25 | 4 388 | 24,2 % |
| Outils intégrés | `OpenCode` | 13 | 3 440 | 19,0 % |
| `tavily` | `config` | 5 | 1 971 | 10,9 % |
| `toggl-pg-mirror-readonly` | `config` | 3 | 1 737 | 9,6 % |
| `context7` | `config` | 2 | 1 239 | 6,8 % |
| `pitchfork` | `config` | 5 | 496 | 2,7 % |
| `exa` | `config` | 2 | 469 | 2,6 % |
| `mise` | `config` | 3 | 399 | 2,2 % |
| `fetch` | `config` | 1 | 264 | 1,5 % |
| **Total des outils** | | | **14 403** | 79,6 % |

## Répartition

| | Tokens | Part |
| --- | ---: | ---: |
| Blocs système | 3 694 | 20,4 % |
| Outils | 14 403 | 79,6 % |
| Non attribué | 1 | 0,0 % |
| **Total mesuré** | **18 098** | 100 % |

La part non attribuée contient le prompt de mesure, l’encadrement qu’OpenCode ajoute autour des blocs, et l’écart entre le tokeniseur local et celui du fournisseur.

## Skills

53 skills sont enregistrés. Leur liste coûte 457 tokens mesurés, soit 9 tokens par skill enregistré. Le corps d’un `SKILL.md` n’est payé que lorsqu’un skill est invoqué et ne fait pas partie de ce total.

## Recommandations

- `playwright` : 4 388 tokens, 24,2 % du contexte. Payé uniquement tant que ce serveur est actif.
- Outils intégrés : 3 440 tokens, 19,0 % du contexte. Ce sont les outils que `plan` peut appeler.
- `tavily` : 1 971 tokens, 10,9 % du contexte. Payé uniquement tant que ce serveur est actif.
