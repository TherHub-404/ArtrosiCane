import { createClient, pause, saveScreenshot, timestamp } from "./lib/session-utils.mjs";

const defaultRowYs = [300, 478, 656, 834, 1012];
const rowYs = (process.env.ROW_YS || defaultRowYs.join(","))
  .split(",")
  .map((value) => Number.parseInt(value.trim(), 10))
  .filter((value) => Number.isFinite(value));

const maxPages = Number.parseInt(process.env.MAX_PAGES || "30", 10);
const afterChatTapMs = Number(process.env.AFTER_CHAT_TAP_MS || "350");
const afterWithoutMediaMs = Number(process.env.AFTER_WITHOUT_MEDIA_MS || "350");
const afterSaveToFilesMs = Number(process.env.AFTER_SAVE_TO_FILES_MS || "500");
const afterSaveMs = Number(process.env.AFTER_SAVE_MS || "700");
const afterSwipeMs = Number(process.env.AFTER_SWIPE_MS || "900");

async function exportVisibleRows(client) {
  for (const y of rowYs) {
    await client.execute("mobile: tap", { x: 320, y });
    await pause(afterChatTapMs);

    await client.execute("mobile: tap", { x: 240, y: 1585 });
    await pause(afterWithoutMediaMs);

    await client.execute("mobile: tap", { x: 171, y: 1457 });
    await pause(afterSaveToFilesMs);

    await client.execute("mobile: tap", { x: 775, y: 72 });
    await pause(afterSaveMs);
  }
}

async function swipeToNextPage(client) {
  await client.execute("mobile: swipe", { direction: "up" });
  await pause(afterSwipeMs);
}

const client = await createClient();

try {
  const base = timestamp();
  let previousScreen = await client.takeScreenshot();

  for (let pageIndex = 0; pageIndex < maxPages; pageIndex += 1) {
    await exportVisibleRows(client);

    if (pageIndex === maxPages - 1) {
      break;
    }

    await swipeToNextPage(client);
    const nextScreen = await client.takeScreenshot();

    if (nextScreen === previousScreen) {
      console.log(`Stop automatico alla pagina ${pageIndex + 1}: nessun cambiamento dopo lo swipe.`);
      break;
    }

    previousScreen = nextScreen;
  }

  const screenshotPath = await saveScreenshot(client, `${base}-after-full-fast-export`);
  console.log(`Export completo veloce terminato. Screenshot finale: ${screenshotPath}`);
} finally {
  await client.deleteSession();
}
