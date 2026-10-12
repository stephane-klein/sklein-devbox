import pino from "pino";
import pinoPretty from "pino-pretty";

const prettyTransport = new pinoPretty({
    colorize: true,
    translateTime: "SYS:yyyy-mm-dd HH:MM:ss.l",
    singleLine: true,
    ignore: "pid,hostname",
    sync: true,
});

export const logger = pino(
    {
        level: "info",
    },
    process.env.NODE_ENV !== "production" ? prettyTransport : pino.destination(1),
);