/**
 * One-off or batch image generation via Replicate (e.g. FLUX) using REPLICATE_API_TOKEN.
 * Loads .env / .env.local like Linear tooling. Outputs to art/reference/ by default.
 *
 * Usage:
 *   npm run art:replicate -- --prompt "your prompt"
 *   npm run art:replicate -- --prompt "..." --out art/reference/my_tile.png
 *   npm run art:replicate -- --batch tools/art/batch-prompts.example.txt
 *   npm run art:replicate -- --prompt "..." --dry-run
 *
 * See tools/art/README.md for Gemini CLI + nanobanana workflow.
 */
import Replicate from "replicate";
import { mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";

import { loadLinearEnv } from "../linear/load-env";

const DEFAULT_MODEL =
  process.env.REPLICATE_IMAGE_MODEL ?? "black-forest-labs/flux-schnell";

function getArg(flag: string): string | undefined {
  const i = process.argv.indexOf(flag);
  if (i === -1 || i + 1 >= process.argv.length) {
    return undefined;
  }
  return process.argv[i + 1];
}

function hasFlag(flag: string): boolean {
  return process.argv.includes(flag);
}

async function downloadToFile(url: string, dest: string): Promise<void> {
  const dir = dirname(dest);
  mkdirSync(dir, { recursive: true });
  const res = await fetch(url);
  if (!res.ok) {
    throw new Error(`Download failed ${res.status}: ${url}`);
  }
  const buf = await res.arrayBuffer();
  writeFileSync(dest, Buffer.from(buf));
}

function normalizeUrls(output: unknown): string[] {
  if (output == null) {
    return [];
  }
  if (typeof output === "string" && output.startsWith("http")) {
    return [output];
  }
  if (Array.isArray(output)) {
    return output.filter((x): x is string => typeof x === "string" && x.startsWith("http"));
  }
  return [];
}

async function runOne(
  replicate: Replicate,
  model: string,
  prompt: string,
  dryRun: boolean
): Promise<string[]> {
  if (dryRun) {
    console.log(`[dry-run] model=${model}`);
    console.log(`[dry-run] prompt=${prompt.slice(0, 200)}${prompt.length > 200 ? "…" : ""}`);
    return [];
  }

  const input: Record<string, string | number> = {
    prompt,
    aspect_ratio: process.env.REPLICATE_ASPECT_RATIO ?? "1:1",
    output_format: process.env.REPLICATE_OUTPUT_FORMAT ?? "png"
  };

  const output = await replicate.run(model, { input });

  return normalizeUrls(output);
}

function defaultOutPath(index: number): string {
  const d = new Date().toISOString().slice(0, 10);
  return join("art", "reference", `${d}-replicate-${index}.png`);
}

async function main(): Promise<void> {
  loadLinearEnv(process.cwd());

  const token = process.env.REPLICATE_API_TOKEN?.trim();
  if (!token && !hasFlag("--dry-run")) {
    console.error("Missing REPLICATE_API_TOKEN (add to .env.local). Or use --dry-run.");
    process.exit(1);
  }

  const replicate = new Replicate({ auth: token ?? "dry-run" });
  const model = getArg("--model") ?? DEFAULT_MODEL;
  const dryRun = hasFlag("--dry-run");
  const batchPath = getArg("--batch");
  const promptSingle = getArg("--prompt");

  const prompts: string[] = [];
  if (batchPath) {
    const abs = resolve(process.cwd(), batchPath);
    const raw = readFileSync(abs, "utf8");
    for (const line of raw.split(/\r?\n/)) {
      const t = line.trim();
      if (t === "" || t.startsWith("#")) {
        continue;
      }
      prompts.push(t);
    }
  } else if (promptSingle) {
    prompts.push(promptSingle);
  } else {
    console.error(
      "Provide --prompt \"...\" or --batch path/to/prompts.txt. See tools/art/README.md"
    );
    process.exit(1);
  }

  let idx = 0;
  for (const prompt of prompts) {
    idx += 1;
    const outArg = getArg("--out");
    let outPath: string;
    if (prompts.length === 1 && outArg) {
      outPath = resolve(process.cwd(), outArg);
    } else {
      outPath = resolve(process.cwd(), defaultOutPath(idx));
    }

    const urls = await runOne(replicate, model, prompt, dryRun);
    if (dryRun) {
      continue;
    }
    if (urls.length === 0) {
      console.error(`No image URLs in Replicate output for prompt #${idx}.`);
      process.exit(1);
    }
    const target = urls.length === 1 || !hasFlag("--all") ? urls[0] : urls[0];
    await downloadToFile(target, outPath);
    console.log(`Wrote ${outPath}`);
    if (urls.length > 1 && !hasFlag("--all")) {
      console.log(`(first of ${urls.length} outputs; use --all or set num_outputs=1)`);
    }
  }
}

main().catch((err: unknown) => {
  console.error(err);
  process.exit(1);
});
