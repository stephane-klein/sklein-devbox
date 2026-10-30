// sklein-context-dump - capture the model request assembled for an audited
// session, so `sklein-generate-opencode-context-report` can break the context
// cost down by source (system blocks, built-in tools, MCP tools).
//
// OpenCode loads this plugin with every server start and the hook is always
// registered; that costs one condition per model call and, more importantly,
// avoids the two things that made the first designs fragile. A plugin cannot
// observe its own registries during `setup` -- `mcp.list()` and `tool.list()`
// both answer with empty lists while the location is not materialised yet --
// and arming through `opencode reload` disturbs the shared server, which kills
// the very session running the audit.
//
// The script therefore connects the MCP servers it wants through
// `POST /api/experimental/mcp/{server}/connect`, writes
// `~/.cache/sklein-context-audit/run.json` with the audited session id, then
// prompts. This hook only writes when that file names the session, once.
//
// Only `system` and `tools` are captured: the audit measures the fixed overhead
// of the configuration, and prompts have no business landing in a cache file.

import { Plugin } from "@opencode/plugin"
import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs"
import { homedir } from "node:os"
import { join } from "node:path"

const dir = join(homedir(), ".cache", "sklein-context-audit")
const runPath = join(dir, "run.json")
const dumpPath = join(dir, "dump.json")

function auditedSession(): string | undefined {
  try {
    return JSON.parse(readFileSync(runPath, "utf8"))?.sessionID
  } catch {
    return undefined
  }
}

export default Plugin.define({
  id: "sklein-context-dump",
  async setup(ctx) {
    // Sessions already dumped in this process, so a long conversation does not
    // overwrite the reference point with a larger, already-contextualised
    // request on its second turn.
    const dumped = new Set<string>()

    await ctx.session.hook("context", (event) => {
      if (!existsSync(runPath)) return
      const target = auditedSession()
      if (!target || target !== event.sessionID) return
      if (dumped.has(event.sessionID)) return
      dumped.add(event.sessionID)

      const system = (event.system ?? []).map((part) => ({
        type: part.type,
        text: part.text,
      }))

      const tools = Object.entries(
        (event.tools ?? {}) as Record<string, Record<string, unknown>>,
      ).map(([name, tool]) => ({
        name,
        description: tool?.description ?? null,
        input: tool?.input ?? null,
      }))

      mkdirSync(dir, { recursive: true, mode: 0o700 })
      writeFileSync(
        dumpPath,
        JSON.stringify(
          {
            sessionID: event.sessionID,
            at: new Date().toISOString(),
            system,
            tools,
          },
          null,
          2,
        ) + "\n",
      )
    })
  },
})
