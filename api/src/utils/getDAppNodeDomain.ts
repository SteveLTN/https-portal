import axios from "axios";
import { config } from "../config";
import fs from "fs";

const maxRetries = 20;

export async function getDAppNodeDomain(): Promise<string> {
  if (process.env.PUBLIC_DOMAIN) {
    return process.env.PUBLIC_DOMAIN;
  }
  const path: string = '/var/run/domains.d/fulldomain';
  if (fs.existsSync(path)) {
    return fs.readFileSync(path, 'utf-8');
  }
  for (let i = 0; i < maxRetries; i++) {
    try {
      const response = await axios.get(config.dappmanager_domain_url);
      if (response.status === 200) {
        fs.writeFileSync(path, response.data, 'utf-8');
        return response.data;
      }
    } finally {
    await new Promise(r => setTimeout(r, 1000));
    }
  }

  throw Error("Max polls exceeded");
}
