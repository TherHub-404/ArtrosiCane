import { clickFirstExisting, createClient, pause, saveScreenshot, timestamp } from "./lib/session-utils.mjs";

const client = await createClient();

try {
  const selector = await clickFirstExisting(client, [
    "~Keep Both",
    '//XCUIElementTypeButton[@name="Keep Both"]',
  ]);

  if (!selector) {
    throw new Error("Non trovo il pulsante 'Keep Both'.");
  }

  await pause(1800);
  const screenshotPath = await saveScreenshot(client, `${timestamp()}-after-keep-both-current`);
  console.log(`Screenshot dopo Keep Both: ${screenshotPath}`);
} finally {
  await client.deleteSession();
}
