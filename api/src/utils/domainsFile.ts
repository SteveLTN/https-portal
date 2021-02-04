import fs from "fs";
import { config } from "../config";
import { DomainMapping } from "../types";

export function writeDomainsFile(
  mappings: DomainMapping[],
  dappnodeDomain: string
): void {
  const output = mappings
    .map(({ from, to }) => [`${from}.${dappnodeDomain}`, to].join(" -> "))
    .join(", ");

  fs.writeFileSync(config.domains_filepath, output);
}
