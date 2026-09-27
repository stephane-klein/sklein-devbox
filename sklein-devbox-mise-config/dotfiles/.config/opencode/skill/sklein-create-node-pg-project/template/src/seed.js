#!/usr/bin/env node
// Utility script — loads and executes all SQL fixture files from sqls/fixtures/
import { readFileSync, readdirSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { join, dirname } from "node:path";

import { logger } from "./logger.js";
import { sql, waitForDb } from "./db.js";

await waitForDb();

const __dirname = dirname(fileURLToPath(import.meta.url));
const fixturesDir = join(__dirname, "..", "sqls/fixtures");

const files = readdirSync(fixturesDir)
    .filter((f) => f.endsWith(".sql"))
    .sort();

for (const file of files) {
    logger.info(
        {
            file,
        },
        "Loading fixture",
    );
    const content = readFileSync(join(fixturesDir, file), "utf8");
    await sql.unsafe(content);
}

await sql.end();