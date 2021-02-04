import fs from "fs";
import path from "path";
import lowdb from "lowdb";
import FileSync from "lowdb/adapters/FileSync";
import { DomainMapping } from "./types";
import { config } from "./config";

const dbPath = config.db_filepath;
fs.mkdirSync(path.dirname(dbPath), { recursive: true });

const adapter = new FileSync<DomainMapping[]>(dbPath, { defaultValue: [] });
const db = lowdb(adapter);

export const entriesDb = {
  get(): DomainMapping[] {
    return db.getState();
  },
  set(entries: DomainMapping[]): void {
    db.setState(entries).write();
  },
  clear(): void {
    this.set([]);
  }
};
