import { clickFirstExisting, createClient, pause, saveScreenshot, timestamp } from "./lib/session-utils.mjs";

const client = await createClient();

try {
  const selector = await clickFirstExisting(client, [
    "~Save",
    '//XCUIElementTypeButton[@name="Save"]',
  ]);

  if (!selector) {
    await client.execute("mobile: tap", { x: 775, y: 72 });
  }

  await pause(3500);
  const screenshotPath = await saveScreenshot(client, `${timestamp()}-after-confirm-save-current`);
  console.log(`Screenshot dopo conferma Save: ${screenshotPath}`);
} finally {
  await client.deleteSession();
}
