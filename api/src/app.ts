import express, { NextFunction, Request, Response } from "express";
import asyncHandler from "express-async-handler";
import { oneOf, query, validationResult } from "express-validator";
import { generateDomainsFile, generateDomainsString } from './utils'
import morgan from "morgan";
import path from "path";
import config from "./config";
import { Schema } from "./types";
import lowdb from "lowdb";
import FileAsync from "lowdb/adapters/FileAsync";
import exec from 'child_process';
import empty from "is-empty";

const app = express();


app.use(morgan("tiny"));
app.get(
  "/add",
  [
    query("from").exists().isString(),
    query("to").exists().isString()
  ],
  asyncHandler(async (req: Request, res: Response, next: NextFunction) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const from: string = `${req.query.from as string}.${config.public_domain}`;
    const to: string = req.query.to as string;

    const adapter = new FileAsync<Schema>(path.join(config.db_dir, config.db_name));
    const db = await lowdb(adapter);
    db.defaults({ entries: [] }).write();

    if (!empty(db.get('entries').find({ from: from }).value())) {
      return res.status(400).json({ error: "External endpoint already exists!" });
    }

    db.get('entries').push({from, to}).write().then(() => {
        return generateDomainsFile();
    }).then(() => {
        exec.exec("reconfig");
        res.sendStatus(204);
    }).catch(err => {
        console.log(err);
        next(err);
    });
    
}));

app.get("/remove",
  oneOf(
    [
      query("from").exists().isString(),
      query("to").exists().isString()
  ]),
  asyncHandler(async (req: Request, res: Response, next: NextFunction) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }
    const adapter = new FileAsync<Schema>(path.join(config.db_dir, config.db_name));
    const db = await lowdb(adapter);
    db.defaults({ entries: [] }).write();
    let removeKey: any = {};

    if(!req.query.to  && req.query.from) {
      const from: string = `${req.query.from as string}.${config.public_domain}`;
      if (empty(db.get('entries').find({ from: from }).value())) {
        return res.status(400).json({ error: "External endpoint not found!" });
      }
      removeKey = {from: from};
    }

    else if(req.query.to  && !req.query.from) {
      const to: string = req.query.to as string;
      if (empty(db.get('entries').find({ to: to }).value())) {
        return res.status(400).json({ error: "Internal endpoint not found!" });
      }
      removeKey = {to: to};
    }

    else {
      const from: string = `${req.query.from as string}.${config.public_domain}`;
      const to: string = req.query.to as string;
      if (empty(db.get('entries').find({from: from, to: to }).value())) {
        return res.status(304).json({ message: "External -> internal forwarding not found!" });
      }
      removeKey = {from: from, to: to};
    }
    db.get('entries').remove(removeKey).write().then(() => {
      generateDomainsFile();
      exec.exec("reconfig");
      return res.sendStatus(204);
    }).catch((err) => {
        console.log(err);
        next(err);
    });
    

}));

app.get("/dump/:how", 
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
    } else {
      return res.status(400).send("Unknown parameter");
    }

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


