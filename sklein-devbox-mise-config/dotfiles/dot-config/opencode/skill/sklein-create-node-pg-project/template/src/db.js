import postgres from "postgres";

import { logger } from "./logger.js";

// biome-ignore format: keep multi-line destructuring
const {
    POSTGRES_HOST,
    POSTGRES_USER,
    POSTGRES_PASSWORD,
    POSTGRES_DB,
    POSTGRES_PORT
} = process.env;

export const sql = postgres({
    host: POSTGRES_HOST || "postgres",
    port: Number(POSTGRES_PORT) || 5432,
    database: POSTGRES_DB,
    user: POSTGRES_USER,
    password: POSTGRES_PASSWORD,
    idle_timeout: 1,
});

export async function waitForDb(maxRetries = 10, delayMs = 1000) {
    const host = POSTGRES_HOST || "postgres";
    const port = Number(POSTGRES_PORT) || 5432;
    const db = POSTGRES_DB;

    logger.info(`Attempting to connect to postgres://${POSTGRES_USER}@${host}:${port}/${db}`);

    for (let i = 1; i <= maxRetries; i++) {
        try {
            await sql`SELECT 1`;
            return;
        } catch (err) {
            if (i === maxRetries) throw err;
            await new Promise((r) => setTimeout(r, delayMs));
        }
    }
}