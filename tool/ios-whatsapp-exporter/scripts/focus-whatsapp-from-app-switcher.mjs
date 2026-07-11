import { createClient, pause, saveScreenshot, timestamp } from "./lib/session-utils.mjs";

const client = await createClient();

try {
  await client.execute("mobile: tap", { x: 710, y: 880 });
  await pause(1800);
  const screenshotPath = await saveScreenshot(client, `${timestamp()}-after-focus-whatsapp-from-app-switcher`);
  console.log(`Screenshot dopo focus WhatsApp: ${screenshotPath}`);
} finally {
  await client.deleteSession();
}
