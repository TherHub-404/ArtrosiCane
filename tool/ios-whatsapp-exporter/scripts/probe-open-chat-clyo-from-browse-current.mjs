import { clickFirstExisting, createClient, pause, saveScreenshot, timestamp } from "./lib/session-utils.mjs";

const client = await createClient();

try {
  const selector = await clickFirstExisting(client, [
    "~Chat-Clyo",
    '//XCUIElementTypeCell[.//XCUIElementTypeStaticText[@name="Chat-Clyo"]]',
    '//XCUIElementTypeStaticText[@name="Chat-Clyo"]',
  ]);

  if (!selector) {
    await client.execute("mobile: tap", { x: 224, y: 218 });
  }

  await pause(2000);
  const screenshotPath = await saveScreenshot(client, `${timestamp()}-open-chat-clyo-from-browse-current`);
  console.log(`Screenshot dentro Chat-Clyo: ${screenshotPath}`);
} finally {
  await client.deleteSession();
}
