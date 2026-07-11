import { execFileSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import "dotenv/config";

const device = process.env.IOS_UDID;

if (!device) {
  console.error("Imposta IOS_UDID nel file .env.");
  process.exit(1);
}

const outputPath = path.join(os.tmpdir(), `devicectl-apps-${Date.now()}.json`);

try {
  execFileSync(
    "xcrun",
    [
      "devicectl",
      "--json-output",
      outputPath,
      "device",
      "info",
      "apps",
      "--include-all-apps",
      "--device",
      device,
    ],
    {
      stdio: ["ignore", "pipe", "pipe"],
      encoding: "utf8",
    },
  );

  const raw = fs.readFileSync(outputPath, "utf8");
  const payload = JSON.parse(raw);
  const apps = payload?.result?.apps ?? [];
  const matches = apps.filter((app) =>
    JSON.stringify(app).toLowerCase().includes("whatsapp"),
  );

  if (matches.length === 0) {
    console.log("Nessun bundle WhatsApp trovato nel JSON di devicectl.");
    process.exit(0);
  }

  for (const app of matches) {
    console.log(JSON.stringify(app));
  }
} catch (error) {
  const stderr = error.stderr?.toString?.() ?? "";
  const stdout = error.stdout?.toString?.() ?? "";
  console.error(`${stdout}${stderr}`.trim());
  process.exit(error.status ?? 1);
} finally {
  fs.rmSync(outputPath, { force: true });
}
