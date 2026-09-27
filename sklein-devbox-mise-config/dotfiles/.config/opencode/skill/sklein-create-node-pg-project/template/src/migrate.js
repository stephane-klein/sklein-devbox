#!/usr/bin/env node
import { fileURLToPath } from "node:url";
import shift from "postgres-shift";

import { logger } from "./logger.js";
import { sql, waitForDb } from "./db.js";

await waitForDb();

shift({
    sql,
    path: fileURLToPath(new URL("../sqls/migrations", import.meta.url)),
    before: ({ migration_id, name }) => {
        logger.info(
            {
                migration_id,
                name,
            },
            "Migrating",
        );
    },
})
    .then(() => {
        logger.info("Migrations done");
        process.exit(0);
    })
    .catch((err) => {
        logger.error(
            {
                err,
            },
            "Migration failed",
        );
        process.exit(1);
    });