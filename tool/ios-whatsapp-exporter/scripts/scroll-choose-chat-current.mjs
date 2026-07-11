import { createClient, pause, saveScreenshot, timestamp } from "./lib/session-utils.mjs";

const client = await createClient();

try {
  await client.execute("mobile: dragFromToForDuration", {
    duration: 0.12,
    fromX: 390,
    fromY: 1180,
    toX: 390,
    toY: 430,
  });

  await pause(1800);
  const screenshotPath = await saveScreenshot(client, `${timestamp()}-after-scroll-choose-chat-current`);
  console.log(`Screenshot dopo scroll: ${screenshotPath}`);
} finally {
  await client.deleteSession();
}
