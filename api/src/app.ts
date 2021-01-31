import express, { NextFunction, Request, Response } from "express";
import asyncHandler from "express-async-handler";
import { oneOf, query, param, validationResult } from "express-validator";
import { generateDomainsFile, generateDomainsString, getDAppNodeDomain, shell } from './utils'
import morgan from "morgan";
import path from "path";
import config from "./config";
import { Schema } from "./types";
import lowdb from "lowdb";
import FileAsync from "lowdb/adapters/FileAsync";
import empty from "is-empty";
import fs from "fs";

const app = express();

app.use(morgan("tiny"));
app.get(
  "/add",
  [
    query("from").exists(),
    query("to").exists()
  ],
  asyncHandler(async (req: Request, res: Response, next: NextFunction) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const domain: string = await getDAppNodeDomain();
    const from: string = `${req.query.from as string}.${domain}`;
    const to: string = req.query.to as string;

    if((req.query.from as string).includes(".")) {
      return res.status(400).json({ error: "Parameter from should not be FQDN nor contain any aditiondal subdomains" });
    }
    const adapter = new FileAsync<Schema>(path.join(config.db_dir, config.db_name));
    const db = await lowdb(adapter);
    db.defaults({ entries: [] }).write();

    if (!empty(db.get('entries').find({ from }).value())) {
      return res.status(400).json({ error: "External endpoint already exists!" });
    }

    await db.get('entries').push({from, to}).write();
    await generateDomainsFile();
    console.log(await shell("reconfig"));
    return res.sendStatus(204);

}));

app.get("/remove",
  oneOf(
    [
      query("from").exists()
  ]),
  asyncHandler(async (req: Request, res: Response, next: NextFunction) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const domain: string = await getDAppNodeDomain();
    const adapter = new FileAsync<Schema>(path.join(config.db_dir, config.db_name));
    const db = await lowdb(adapter);
    db.defaults({ entries: [] }).write();
    let removeKey: any = {};

    if(!req.query.to  && req.query.from) {
      const from: string = `${req.query.from as string}.${domain}`;
      if (empty(db.get('entries').find({ from }).value())) {
        return res.status(400).json({ error: "External endpoint not found!" });
      }
      removeKey = {from};
    }

    else if(req.query.to  && !req.query.from) {
      const to: string = req.query.to as string;
      if (empty(db.get('entries').find({ to }).value())) {
        return res.status(400).json({ error: "Internal endpoint not found!" });
      }
      removeKey = {to};
    }

    else {
      const from: string = `${req.query.from as string}.${domain}`;
      const to: string = req.query.to as string;
      if (empty(db.get('entries').find({from, to }).value())) {
        return res.status(304).json({ message: "External -> internal forwarding not found!" });
      }
      removeKey = {from, to};
    }
    await db.get('entries').remove(removeKey).write();
    await generateDomainsFile();
    console.log(await shell("reconfig"));
    return res.sendStatus(204);
}));

app.get("/dump/:how",
  [
    param("how").exists().isIn(["json", "txt"]).withMessage("Only json and txt allowed.")
  ],
  asyncHandler(async (req: Request, res: Response, next: NextFunction) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const adapter = new FileAsync<Schema>(path.join(config.db_dir, config.db_name));
    const db = await lowdb(adapter);

    if(req.params.how === "json") {
      return res.status(200).json(db.get('entries').value())
    } else if(req.params.how === "txt") {
      return res.status(200).send(await generateDomainsString());
    }

}));

app.get("/clear",
  asyncHandler(async (req: Request, res: Response, next: NextFunction) => {

    const dbFile: string = path.join(config.db_dir, config.db_name);
    if(fs.existsSync(dbFile)) {

      fs.unlinkSync(dbFile);
      const adapter = new FileAsync<Schema>(dbFile);
      const db = await lowdb(adapter);
      await db.defaults({ entries: [] }).write();
    }

    return res.sendStatus(204);
}));


app.get("/reconfig",
  asyncHandler(async (req: Request, res: Response, next: NextFunction) => {
    console.log(await shell("reconfig"));
    return res.sendStatus(204);
}));

app.use((err: any, req: Request, res: Response, next: NextFunction) => {
  return res.status(500).json({
    error: err,
  });
});

app.use((req: Request, res: Response, next: NextFunction) => {
  return res.status(404).json({
    error: "Not Found",
  });
});

export { app };


