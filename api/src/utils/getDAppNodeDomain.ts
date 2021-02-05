import axios from "axios";
import { config } from "../config";

const maxRetries = 20;

export async function getDAppNodeDomain(): Promise<string> {
  if (process.env.PUBLIC_DOMAIN) {
    return process.env.PUBLIC_DOMAIN;
  }
  for (let i = 0; i < maxRetries; i++) {
    const response = await axios.get(config.dappmanager_domain_url);
    if (response.status === 200) {
      return response.data;
    }
    await new Promise(r => setTimeout(r, 1000));
  }

  throw Error("Max polls exceeded");
}
