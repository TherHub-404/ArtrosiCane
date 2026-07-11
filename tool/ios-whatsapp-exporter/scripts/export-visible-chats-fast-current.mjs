import { createClient, pause, saveScreenshot, timestamp } from "./lib/session-utils.mjs";

const defaultRowYs = [300, 478, 656, 834, 1012];
const rowYs = (process.env.ROW_YS || defaultRowYs.join(","))
  .split(",")
  .map((value) => Number.parseInt(value.trim(), 10))
  .filter((value) => Number.isFinite(value));
const maxExports = Number.parseInt(process.env.MAX_EXPORTS || `${rowYs.length}`, 10);
const afterChatTapMs = Number(process.env.AFTER_CHAT_TAP_MS || "350");
const afterWithoutMediaMs = Number(process.env.AFTER_WITHOUT_MEDIA_MS || "350");
const afterSaveToFilesMs = Number(process.env.AFTER_SAVE_TO_FILES_MS || "500");
const afterSaveMs = Number(process.env.AFTER_SAVE_MS || "700");

const client = await createClient();

try {
  const base = timestamp();
  const rowsToExport = rowYs.slice(0, Math.max(0, maxExports));

  for (let index = 0; index < rowsToExport.length; index += 1) {
    const y = rowsToExport[index];

    // Open a visible chat from the current "Choose chat" list.
    await client.execute("mobile: tap", { x: 320, y });
    await pause(afterChatTapMs);

    // Select "Without media" from the export action sheet.
    await client.execute("mobile: tap", { x: 240, y: 1585 });
    await pause(afterWithoutMediaMs);

    // Choose "Save to Files" from the share sheet.
    await client.execute("mobile: tap", { x: 171, y: 1457 });
    await pause(afterSaveToFilesMs);

    // Confirm save inside the current Chat-Clyo folder.
    await client.execute("mobile: tap", { x: 775, y: 72 });
    await pause(afterSaveMs);
  }

  const screenshotPath = await saveScreenshot(client, `${base}-after-fast-visible-export`);
  console.log(`Export veloce completato. Screenshot finale: ${screenshotPath}`);
} finally {
  await client.deleteSession();
}
