import express, { ErrorRequestHandler, Request, Response } from "express";
import morgan from "morgan";
import { HttpError, BadRequestError, asyncHandler } from "./utils/asyncHandler";
import { entriesDb } from "./db";
import { reconfigureNGINX } from "./nginx";
import { sanitizeFrom, sanitizeTo } from "./utils/sanitize";
import { config } from "./config";
import { getDAppNodeDomain } from "./utils/getDAppNodeDomain";

const app = express();

app.use(morgan("tiny"));

app.get(
  "/add",
  asyncHandler(async req => {
    const from = await sanitizeFrom(req.query.from as string);
    const to = sanitizeTo(req.query.to as string);

    const entries = entriesDb.read();
    if (entries.some(entry => entry.from === from)) {
      throw new BadRequestError("External endpoint already exists");
    }

    // NGINX will crash in loop if a domain is longer than `server_names_hash_bucket_size`
    // Force that from has only ASCII characters to make sure the char length = bytes lenght
    // fulldomain = from + "." + dappnodeDomain
    const dappnodeDomain = await getDAppNodeDomain();
    const maxLen = config.maximum_domain_length - dappnodeDomain.length - 1;
    if (from.length > maxLen) {
      throw new BadRequestError(`'from' ${from} exceeds max length of ${from}`);
    }

    entries.push({ from, to });
    entriesDb.write(entries);

    await reconfigureNGINX();
  })
);

app.get(
  "/remove",
  asyncHandler(async req => {
    const from = await sanitizeFrom(req.query.from as string);

    const entries = entriesDb.read();
    entriesDb.write(entries.filter(e => e.from !== from));

    await reconfigureNGINX();
  })
);

app.get(
  "/",
  asyncHandler(async () => entriesDb.read())
);

app.get(
  "/reconfig",
  asyncHandler(async () => await reconfigureNGINX())
);

app.get(
  "/clear",
  asyncHandler(async () => {
    entriesDb.write([]);
    await reconfigureNGINX();
  })
);

app.use((_req: Request, res: Response) => {
  res.status(404).json({ error: "Not Found" });
});

// Default error handler
app.use(function (err, _req, res, next) {
  if (res.headersSent) return next(err);
  const code = err instanceof HttpError ? err.code : 500;
  res.status(code).json({ error: err.message });
} as ErrorRequestHandler);

export { app };
