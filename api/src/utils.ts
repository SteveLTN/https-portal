import fs from "fs";
import { Schema } from "./types";
import path from 'path';
import config from "./config";
import lowdb from "lowdb";
import FileAsync from "lowdb/adapters/FileAsync";

function createIfNotExists(path: string) {
  if (!fs.existsSync(path)) {
    fs.mkdirSync(path);
  }
}


async function generateDomainsString(): Promise<string> {
  const adapter = new FileAsync<Schema>(path.join(config.db_dir, config.db_name));
  const db = await lowdb(adapter);

  const data = db.get('entries').value();
  let output: string = "";

  for(let entry of data){
    output += entry.from + " -> " + entry.to + ", ";
  }

  return output.slice(0, -2);
}

async function generateDomainsFile(): Promise<void> {
  const output: string = await generateDomainsString();
  fs.writeFileSync(path.join(config.domains_dir, config.domains_file), output);
}

export { createIfNotExists, generateDomainsString, generateDomainsFile };
