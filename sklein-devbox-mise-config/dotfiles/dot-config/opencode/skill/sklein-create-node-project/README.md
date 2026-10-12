# sklein-create-node-project

Skill for creating Node.js projects based on Stéphane Klein's preferences.

## Version Prefix Doctrine

All direct dependencies in `package.json` use the **tilde (`~`)** prefix.

**Why not caret (`^`) ?**

Caret allows minor-level updates automatically. Minor releases can introduce regressions in subtle ways (new behavior, changed defaults, deprecated APIs still present but behaving differently). Past experience on team projects showed these regressions consumed significant debugging time.

**Why not exact pin ?**

Exact pin blocks everything — including security patches. With exact pin, you must manually edit `package.json` for every patch update, which means patches often get deferred or forgotten.

**Why tilde is the sweet spot :**

| Risk | Pin exact | `~` (tilde) | `^` (caret) |
|---|---|---|---|
| Security patches arrive automatically | ❌ | ✅ | ✅ |
| Minor regressions blocked | ✅ | ✅ | ❌ |
| Intent visible in `package.json` | ✅ | ✅ | ~ |

The tilde allows patch updates (safe, fixes only) while requiring an explicit decision for any minor or major change. This is enforced both by the literal `~` in version ranges and by the `.npmrc` setting `save-prefix=~` that ensures `pnpm add` uses tilde for new dependencies.

## Package.json Linting Rationale

This skill uses [npm-package-json-lint](https://npmpackagejsonlint.org) instead of `sort-package-json`.

**Why:**

- **Validation + Order**: Validates package.json structure AND enforces top-level property order.
- **Preserves script groupings**: sort-package-json forces alphabetical sorting of scripts, erasing intentional developer groupings. npm-package-json-lint only validates property order — scripts stay human-organized.
- **Custom order**: Enables organizing scripts by semantic family with blank lines between groups.