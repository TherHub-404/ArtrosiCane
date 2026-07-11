import "dotenv/config";
import { createClient, pause, saveScreenshot, timestamp } from "./lib/session-utils.mjs";

const bundleId = process.env.APP_BUNDLE_ID;
const client = await createClient();

try {
  await client.execute("mobile: activateApp", { bundleId });
  await pause(1800);
  const screenshotPath = await saveScreenshot(client, `${timestamp()}-after-activate-whatsapp-business`);
  console.log(`Screenshot dopo activateApp: ${screenshotPath}`);
} finally {
  await client.deleteSession();
}
