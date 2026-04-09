import { spawnSync } from "node:child_process";

function run(command: string, args: string[]): void {
  const result = spawnSync(command, args, {
    stdio: "inherit",
    shell: process.platform === "win32"
  });
  if (result.status !== 0) {
    throw new Error(`Command failed: ${command} ${args.join(" ")}`);
  }
}

function main(): void {
  const apply = process.argv.includes("--apply");
  console.log("== Producer cycle ==");
  console.log("1) Standup summary");
  run("npm", ["run", "linear:standup"]);
  console.log("2) Dispatch preview");
  if (apply) {
    run("npm", ["run", "linear:dispatch", "--", "--apply"]);
  } else {
    run("npm", ["run", "linear:dispatch"]);
  }
}

try {
  main();
} catch (error) {
  console.error(error);
  process.exit(1);
}
