import { clickFirstExisting, createClient, pause, saveScreenshot, timestamp } from "./lib/session-utils.mjs";

const client = await createClient();

try {
  const selector = await clickFirstExisting(client, [
    "~Back",
    '//XCUIElementTypeButton[@name="Back"]',
  ]);

  if (!selector) {
    await client.execute("mobile: tap", { x: 76, y: 71 });
  }

  await pause(1800);
  const screenshotPath = await saveScreenshot(client, `${timestamp()}-files-parent-from-current`);
  console.log(`Screenshot cartella padre: ${screenshotPath}`);
} finally {
  await client.deleteSession();
}
