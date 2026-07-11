import fs from "node:fs/promises";
import path from "node:path";
import { createClient, dumpVisibleElements, getArtifactsDir, saveScreenshot, timestamp } from "./lib/session-utils.mjs";

const artifactsDir = getArtifactsDir();
const client = await createClient();

try {
  const base = timestamp();
  const screenshotPath = await saveScreenshot(client, `${base}-probe`);
  const sourcePath = path.join(artifactsDir, `${base}-probe.xml`);
  console.log(`Screenshot salvato in ${screenshotPath}`);

  try {
    const source = await client.getPageSource();
    await fs.writeFile(sourcePath, source, "utf8");
    console.log(`UI XML salvato in ${sourcePath}`);
  } catch (error) {
    const { dumpPath } = await dumpVisibleElements(client, `${base}-probe`);
    console.log(`XML non disponibile, dump elementi salvato in ${dumpPath}`);
    console.log(`Motivo: ${error.message}`);
  }
} finally {
  await client.deleteSession();
}
