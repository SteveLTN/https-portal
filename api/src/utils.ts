import fs from "fs";
import { Schema } from "./types";
import path from 'path';
import config from "./config";
import lowdb from "lowdb";
import FileAsync from "lowdb/adapters/FileAsync";
import { promisify } from "util";
import axios from "axios";

import * as child from "child_process";
const exec = promisify(child.exec);

async function generateDomainsString(): Promise<string> {
  const adapter = new FileAsync<Schema>(path.join(config.db_dir, config.db_name));
  const db = await lowdb(adapter);

  const data = db.get('entries').value();
  let output: string = "";

  for(const entry of data){
    output += entry.from + " -> " + entry.to + ", ";
  }

  return output.slice(0, -2);
}

async function generateDomainsFile(): Promise<void> {
  const output: string = await generateDomainsString();
  return promisify(fs.writeFile)(path.join(config.domains_dir, config.domains_file), output);
}



async function getDAppNodeDomain(): Promise <string> {
  const url: string = "http://my.dappnode/global-envs/DOMAIN";
  const maxPolls: number = 20;
  let polls: number = 0;
  return new Promise<string>((resolve, reject) => {
    const poller = async () => {
      polls++;
      const response = await axios.get(url);
      if(response.status === 200) {
        resolve(response.data);
      } else if(polls >= maxPolls) {
        reject("Max polls exceeded")
      } else {
        setTimeout(poller, 1000);
      }
    }
    poller();
  });
}

const defaultTimeout: number = 1000 * 60 * 3;

export default async function shell(
  cmd: string | string[],
  options?: { timeout?: number; maxBuffer?: number }
): Promise<string> {
  const timeout = options && options.timeout ? options.timeout : defaultTimeout;
  const maxBuffer = options && options.maxBuffer;
  try {
    const { stdout = "" } = await exec(
      Array.isArray(cmd) ? cmd.join(" ") : cmd,
      { timeout, maxBuffer }
    );
    return stdout.trim();
  } catch (e) {
    // Rethrow a typed error, and ignore the internal NodeJS stack trace
    const err: child.ExecException = e;
    if (err.signal === "SIGTERM")
      throw new ShellError(e, `process timeout ${timeout} ms, cmd: ${cmd}`);
    else throw new ShellError(e);
  }
}

export class ShellError extends Error implements child.ExecException {
  cmd?: string;
  killed?: boolean;
  code?: number;
  signal?: NodeJS.Signals;
  stdout?: string;
  stderr?: string;
  constructor(
    e: child.ExecException & { stdout?: string; stderr?: string },
    message?: string
  ) {
    super(message || e.message);
    this.cmd = e.cmd;
    this.killed = e.killed;
    this.code = e.code;
    this.signal = e.signal;
    this.stdout = e.stdout;
    this.stderr = e.stderr;
  }
}

export { generateDomainsString, generateDomainsFile, getDAppNodeDomain, shell };
