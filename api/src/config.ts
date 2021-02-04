import path from "path";

const domainsDir = process.env.DOMAINS_DIR || "./domains_dir";

export const config = {
  db_filepath: path.join(domainsDir, "domains.json"),
  domains_filepath: path.join(domainsDir, "domains"),
  dappmanager_domain_url: "http://my.dappnode/global-envs/DOMAIN"
};
