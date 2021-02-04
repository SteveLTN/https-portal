import { entriesDb } from "./db";
import { writeDomainsFile } from "./utils/domainsFile";
import { getDAppNodeDomain } from "./utils/getDAppNodeDomain";
import shell from "./utils/shell";

export async function reconfigureNGINX(): Promise<void> {
  const dappnodeDomain = await getDAppNodeDomain();

  // Write domain mapping file
  writeDomainsFile(entriesDb.get(), dappnodeDomain);

  // reconfig NGINX
  const reconfigOutput = await shell("reconfig");
  console.log(`Reconfigured NGINX\n${reconfigOutput}`);
}
