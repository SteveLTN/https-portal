import dotenv from "dotenv-defaults";

dotenv.config();


export default {
  db_dir: process.env.DB_DIR || "/var/run/domains.d",
  db_name: process.env.DB_NAME || "domains.json",
  domains_dir: process.env.DOMAIN_DIR || "/var/run/domains.d",
  domains_file: process.env.DOMAINS || "domains",
};
