import { HttpError } from "./asyncHandler";

/**
 * from param must be a subdomain
 */
export function sanitizeFrom(from: string): string {
  if (!from) throw new HttpError(`param "from" required`, 400);
  if (from.includes(".")) {
    throw new HttpError(
      "Parameter from must not be FQDN nor contain any subdomains",
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
