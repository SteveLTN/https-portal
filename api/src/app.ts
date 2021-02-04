import express, { ErrorRequestHandler, Request, Response } from "express";
import morgan from "morgan";
import { HttpError, asyncHandler } from "./utils/asyncHandler";
import { entriesDb } from "./db";
import { reconfigureNGINX } from "./nginx";
import { sanitizeFrom, sanitizeTo } from "./utils/sanitize";

const app = express();

app.use(morgan("tiny"));

app.get(
  "/add",
  asyncHandler(async req => {
    const from = sanitizeFrom(req.query.from as string);
    const to = sanitizeTo(req.query.to as string);

    const entries = entriesDb.get();
    if (entries.some(entry => entry.from === from)) {
      throw new HttpError("External endpoint already exists", 400);
    }

    entries.push({ from, to });
    entriesDb.set(entries);

    await reconfigureNGINX();
  })
);

app.get(
  "/remove",
  asyncHandler(async req => {
    const from = sanitizeFrom(req.query.from as string);

    const entries = entriesDb.get();
    entriesDb.set(entries.filter(e => e.from !== from));

    await reconfigureNGINX();
  })
);

app.get(
  "/",
  asyncHandler(async () => entriesDb.get())
);

app.get(
  "/reconfig",
  asyncHandler(async () => await reconfigureNGINX())
);

app.get(
  "/clear",
  asyncHandler(async () => {
    entriesDb.clear();
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
