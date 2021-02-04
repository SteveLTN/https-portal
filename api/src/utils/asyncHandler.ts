import { Request, RequestHandler } from "express";

export class HttpError extends Error {
  code: number;
  constructor(message: string, code: number) {
    super(message);
    this.code = code;
  }
}

export function asyncHandler<T>(
  handler: (req: Request) => Promise<T>
): RequestHandler {
  return (req, res, next) => {
    handler(req)
      .then(result => res.json(result || {}))
      .catch(e => next(e));
  };
}
