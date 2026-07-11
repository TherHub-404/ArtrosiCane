import { createClient, pause, saveScreenshot, timestamp } from "./lib/session-utils.mjs";

const client = await createClient();

try {
  await client.execute("mobile: swipe", { direction: "up" });
  await pause(1500);
  const screenshotPath = await saveScreenshot(client, `${timestamp()}-after-swipe-up-choose-chat-current`);
  console.log(`Screenshot dopo swipe up: ${screenshotPath}`);
} finally {
  await client.deleteSession();
}
