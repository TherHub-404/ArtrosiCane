import { clickFirstExisting, createClient, pause, saveScreenshot, timestamp } from "./lib/session-utils.mjs";

const client = await createClient();

try {
  const selector = await clickFirstExisting(client, [
    "~More",
    "~More Actions",
    "~More actions",
    '//XCUIElementTypeButton[@name="More"]',
  ]);

  if (!selector) {
    await client.execute("mobile: tap", { x: 601, y: 71 });
  }

  await pause(1800);
  const screenshotPath = await saveScreenshot(client, `${timestamp()}-files-more-menu-current`);
  console.log(`Screenshot menu puntini: ${screenshotPath}`);
} finally {
  await client.deleteSession();
}
