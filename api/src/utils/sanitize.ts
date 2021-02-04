import { HttpError } from "./asyncHandler";
import { config } from "../config";
import { getDAppNodeDomain } from "./getDAppNodeDomain"

/**
 * from param must be a subdomain
 */
export async function sanitizeFrom(from: string): Promise<string> {
  if (!from) throw new HttpError(`param "from" required`, 400);
  if (from.includes(".")) {
    throw new HttpError(
      "Parameter from must not be FQDN nor contain any subdomains",
      400
    );
  }
  const fullDomain: string = `${from}.${await getDAppNodeDomain()}`;
  if (fullDomain.length  > config.maximum_domain_length) {
    throw new HttpError(
       `Your domain (${fullDomain}) is ${fullDomain.length} charachters long. Maximum allowed is ${config.maximum_domain_length}.`,
       400
    );
    }
  
  return from;
}

/**
 * to param must be a host with maybe a port number
 */
export function sanitizeTo(to: string): string {
  if (!to) throw new HttpError(`param "to" required`, 400);
  return to;
}
