import { createClient, pause, saveScreenshot, timestamp } from "./lib/session-utils.mjs";

const client = await createClient();

try {
  // Back from the search view to the "On My iPhone" browse view.
  await client.execute("mobile: tap", { x: 74, y: 72 });
  await pause(1800);

  // Open the visible Chat-Clyo folder.
  await client.execute("mobile: tap", { x: 315, y: 537 });
  await pause(1800);

  // Confirm the save in the current folder.
  await client.execute("mobile: tap", { x: 774, y: 72 });
  await pause(3500);

  const screenshotPath = await saveScreenshot(client, `${timestamp()}-after-save-into-chat-clyo`);
  console.log(`Screenshot dopo Save: ${screenshotPath}`);
} finally {
  await client.deleteSession();
}
