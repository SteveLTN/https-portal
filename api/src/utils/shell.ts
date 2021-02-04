import util from "util";
import * as child from "child_process";

const exec = util.promisify(child.exec);

/**
 * If timeout is greater than 0, the parent will send the signal
 * identified by the killSignal property (the default is 'SIGTERM')
 * if the child runs longer than timeout milliseconds.
 */
const defaultTimeout = 5 * 60 * 1000; // ms

/**
 * Run arbitrary commands in a shell in the DAPPMANAGER container
 * If the child process exits with code > 0, rejects
 */
export default async function shell(
  cmd: string | string[],
  options?: { timeout?: number; maxBuffer?: number }
): Promise<string> {
  const timeout = options && options.timeout ? options.timeout : defaultTimeout;
  const maxBuffer = options && options.maxBuffer;
  try {
    const { stdout = "" } = await exec(
      Array.isArray(cmd) ? cmd.join(" ") : cmd,
      { timeout, maxBuffer }
    );
    return stdout.trim();
  } catch (e) {
    // Rethrow a typed error, and ignore the internal NodeJS stack trace
    const err: child.ExecException = e;
    if (err.signal === "SIGTERM")
      throw new ShellError(e, `process timeout ${timeout} ms, cmd: ${cmd}`);
    else throw new ShellError(e);
  }
}

/**
 * Typed error implementing the native node child exception error
 * Can be rethrow to ignore the internal NodeJS stack trace
 */
export class ShellError extends Error implements child.ExecException {
  cmd?: string;
  killed?: boolean;
  code?: number;
  signal?: NodeJS.Signals;
  stdout?: string;
  stderr?: string;
  constructor(
    e: child.ExecException & { stdout?: string; stderr?: string },
    message?: string
  ) {
    super(message || e.message);
    this.cmd = e.cmd;
    this.killed = e.killed;
    this.code = e.code;
    this.signal = e.signal;
    this.stdout = e.stdout;
    this.stderr = e.stderr;
  }
}
