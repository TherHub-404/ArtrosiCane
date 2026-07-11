import { clickFirstExisting, createClient, pause, saveScreenshot, timestamp } from "./lib/session-utils.mjs";

const client = await createClient();

try {
  const base = timestamp();
  const selector = await clickFirstExisting(client, [
    "~Save to Files",
    '//XCUIElementTypeButton[@name="Save to Files"]',
    '//XCUIElementTypeStaticText[@name="Save to Files"]',
    '//XCUIElementTypeCell[.//XCUIElementTypeStaticText[@name="Save to Files"]]',
  ]);

  if (!selector) {
    await client.execute("mobile: tap", { x: 171, y: 1457 });
  }

  await pause(2500);
  const screenshotPath = await saveScreenshot(client, `${base}-files-picker-from-current`);
  console.log(`Screenshot picker Files: ${screenshotPath}`);
} finally {
  await client.deleteSession();
}
