# OpenCode context audit — 2026-10-30 15:52

What the OpenCode configuration costs in tokens before the first word of a
conversation, and what that costs in dollars.

## Summary

| | |
| --- | --- |
| Fixed context | **18 098 tokens** |
| of which your configuration | 12 248 tokens (67,7 %) |
| of which OpenCode | 5 849 tokens (32,3 %) |
| unattributed | 1 tokens (0,0 %) |
| Share of the 1 000 000-token window | 1,81 % |
| Model used for pricing | `opencode-go/deepseek-v4.1-flash` |
| Per request, cold cache | **0,00271 $** |
| Per request, warm cache | **0,00005 $** |
| For 1 000 requests | 2,71 $ / 0,0543 $ |

DeepSeek publishes no lifetime for its cache: an unused entry is cleared
"within hours to days". The two columns are therefore two real regimes,
not an optimistic and a pessimistic bound.

## Measurement conditions

| | |
| --- | --- |
| Directory | `/home/devbox` |
| Agent | `plan` |
| OpenCode | 2.2.0 |
| MCP servers | 8 enabled for the measurement, 7 disabled normally |
| Cache observed during the measurement | 1 408 tokens served from cache |
| Cost billed for the measurement | not reported by the provider |

The total is measured: it is `tokens.input + tokens.cache.read` of the
session's first assistant message, the one the provider billed. The
breakdown is estimated block by block with `ttok`'s `o200k_base` tokenizer,
then rescaled onto that total (factor 1.212271). Proportions are right; per-block
values are within a few percent.

## System blocks

| Block | Origin | File | Tokens | Share |
| --- | --- | --- | ---: | ---: |
| Base prompt | `OpenCode` | — | 362 | 2,0 % |
| Model | `OpenCode` | — | 44 | 0,2 % |
| Skills listing | `config` | — | 457 | 2,5 % |
| OpenCode environment | `OpenCode` | — | 79 | 0,4 % |
| AGENTS.md global | `config` | ~/.config/opencode/AGENTS.md | 828 | 4,6 % |
| [Code Mode](https://github.com/anomalyco/opencode/blob/v2.2.0/packages/codemode/README.md) | `OpenCode` | — | 1 867 | 10,3 % |
| Worktree note | `OpenCode` | — | 57 | 0,3 % |
| **System blocks total** | | | **3 694** | 20,4 % |

Code Mode is a restricted interpreter for a JavaScript-like language: the
model calls catalog tools instead of invoking them one by one. Only blocks of
origin `config` can be trimmed; the others are produced by the binary.

### Extracts

**Base prompt** — [packages/core/src/session/runner/prompt/system.txt](https://github.com/anomalyco/opencode/blob/v2.2.0/packages/core/src/session/runner/prompt/system.txt)
> You are an AI agent running in OpenCode, a coding agent harness. Help the user accomplish their goal…
> # Harness
> - Responses are rendered as GitHub-flavored Markdown.

**Model** — [packages/core/src/plugin/identity.ts](https://github.com/anomalyco/opencode/blob/v2.2.0/packages/core/src/plugin/identity.ts)
> # Your Model
> - Name: DeepSeek V4.1 Flash
> - Provider ID: opencode-go

**OpenCode environment** — [packages/core/src/instructions/builtins.ts](https://github.com/anomalyco/opencode/blob/v2.2.0/packages/core/src/instructions/builtins.ts)
> # Code Mode
> Use the `execute` tool to call the tools listed below. They cannot be called directly. They only wor…
> The catalog is complete. Do not guess tool names.

**Code Mode** — [packages/core/src/codemode/instructions.ts](https://github.com/anomalyco/opencode/blob/v2.2.0/packages/core/src/codemode/instructions.ts)
> # Code Mode
> Use the `execute` tool to call the tools listed below. They cannot be called directly. They only wor…
> The catalog is complete. Do not guess tool names.

**Worktree note** — [packages/core/src/tool/plugin/opencode.ts](https://github.com/anomalyco/opencode/blob/v2.2.0/packages/core/src/tool/plugin/opencode.ts)
> When you create a worktree outside the current working directory and intend to use it as your primar…

## Tools

| Item | Origin | Tools | Tokens | Share |
| --- | --- | ---: | ---: | ---: |
| `playwright` | `config` | 25 | 4 388 | 24,2 % |
| Built-in tools | `OpenCode` | 13 | 3 440 | 19,0 % |
| `tavily` | `config` | 5 | 1 971 | 10,9 % |
| `toggl-pg-mirror-readonly` | `config` | 3 | 1 737 | 9,6 % |
| `context7` | `config` | 2 | 1 239 | 6,8 % |
| `pitchfork` | `config` | 5 | 496 | 2,7 % |
| `exa` | `config` | 2 | 469 | 2,6 % |
| `mise` | `config` | 3 | 399 | 2,2 % |
| `fetch` | `config` | 1 | 264 | 1,5 % |
| **Tools total** | | | **14 403** | 79,6 % |

## Breakdown

| | Tokens | Share |
| --- | ---: | ---: |
| System blocks | 3 694 | 20,4 % |
| Tools | 14 403 | 79,6 % |
| Unattributed | 1 | 0,0 % |
| **Measured total** | **18 098** | 100 % |

The unattributed part holds the measurement prompt, the framing OpenCode adds
around blocks, and the gap between the local tokenizer and the provider's.

## Skills

53 skills are registered. Their listing costs 457 measured tokens, which
is 9 tokens per registered skill. A `SKILL.md` body is only paid when a
skill is invoked and is not part of this total.

## Recommendations

- `playwright`: 4 388 tokens, 24,2 % of the context. Paid only while that
  server is active.
- Built-in tools: 3 440 tokens, 19,0 % of the context. These are the tools
  `plan` can call.
- `tavily`: 1 971 tokens, 10,9 % of the context. Paid only while that
  server is active.
