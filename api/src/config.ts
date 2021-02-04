import path from "path";

const domainsDir = process.env.DOMAINS_DIR || "./domains_dir";

export const config = {
  db_filepath: path.join(domainsDir, "domains.json"),
  domains_filepath: path.join(domainsDir, "domains"),
  dappmanager_domain_url: "http://my.dappnode/global-envs/DOMAIN",
  maximum_domain_length: process.env.SERVER_NAMES_HASH_BUCKET_SIZE || 128
};
