import { createClient, pause, saveScreenshot, timestamp } from "./lib/session-utils.mjs";

const client = await createClient();

try {
  const search = await client.$("//XCUIElementTypeSearchField");
  if (await search.isExisting()) {
    await search.click();
    await pause(600);
    await search.setValue("Clyo-Chats");
  } else {
    await client.execute("mobile: tap", { x: 235, y: 133 });
    await pause(600);
    await client.keys(["C","l","y","o","-","C","h","a","t","s"]);
  }

  await pause(1800);
  const screenshotPath = await saveScreenshot(client, `${timestamp()}-search-clyo-chats-current`);
  console.log(`Screenshot ricerca Clyo-Chats: ${screenshotPath}`);
} finally {
  await client.deleteSession();
}
