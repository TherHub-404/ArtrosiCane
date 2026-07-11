import { createClient, saveScreenshot, timestamp } from "./lib/session-utils.mjs";

const client = await createClient();

try {
  const path = await saveScreenshot(client, `${timestamp()}-current-screen-fast`);
  console.log(`Screenshot corrente: ${path}`);
} finally {
  await client.deleteSession();
}
