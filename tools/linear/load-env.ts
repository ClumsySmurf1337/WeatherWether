import dotenv from "dotenv";
import { existsSync } from "node:fs";
import { resolve } from "node:path";

/**
 * Load env in precedence order (later overrides earlier):
 * .env → .env.linear.generated → .env.local
 */
export function loadLinearEnv(cwd: string = process.cwd()): void {
  const base = resolve(cwd, ".env");
  const generated = resolve(cwd, ".env.linear.generated");
  const local = resolve(cwd, ".env.local");

  if (existsSync(base)) {
    dotenv.config({ path: base });
  }
  if (existsSync(generated)) {
    dotenv.config({ path: generated, override: true });
  }
  if (existsSync(local)) {
    dotenv.config({ path: local, override: true });
  }
}
