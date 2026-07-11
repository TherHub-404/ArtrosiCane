import "dotenv/config";
import {
  clickFirstExisting,
  createClient,
  elementExists,
  pause,
  saveScreenshot,
  saveScreenshotAndReadText,
  timestamp,
} from "./lib/session-utils.mjs";

const rowYs = [401, 579, 756, 934, 1110];
const targetFolderName = process.env.EXPORT_ROOT_NAME || "Clyo-Chats";
const fallbackFolderName = "Chat-Clyo";
const maxExports = Number.parseInt(process.env.MAX_EXPORTS || `${rowYs.length}`, 10);

async function navigateToChooseChat(client) {
  const current = await saveScreenshotAndReadText(client, `${timestamp()}-batch-start-check`);
  if (current.text.toLowerCase().includes("choose chat")) {
    return;
  }

  const isChooseChatOpen = await elementExists(client, '//XCUIElementTypeStaticText[@name="Choose chat"]')
    || await elementExists(client, '//XCUIElementTypeStaticText[@label="Choose chat"]')
    || await elementExists(client, '~Choose chat');
  if (isChooseChatOpen) {
    return;
  }

  await clickFirstExisting(client, [
    "~Close",
    "~\u200eDismiss banner",
  ]);
  await pause(800);

  const settingsSelector = await clickFirstExisting(client, [
    "~TabBarButton_Settings",
    "~\u200eSettings",
  ]);
  if (!settingsSelector) {
    throw new Error("Non trovo il tab Settings.");
  }

  await pause(1500);

  const chatsSelector = await clickFirstExisting(client, [
    '//XCUIElementTypeCell[.//XCUIElementTypeStaticText[@name="\u200eChats"]]',
    '//XCUIElementTypeCell[.//XCUIElementTypeStaticText[@label="\u200eChats"]]',
    "~\u200eChats",
  ]);
  if (!chatsSelector) {
    throw new Error("Non trovo la voce Chats.");
  }

  await pause(1500);

  const exportSelector = await clickFirstExisting(client, [
    "~SettingsChatsView_ExportChatCell",
    '//XCUIElementTypeCell[.//XCUIElementTypeStaticText[@name="\u200eExport chat"]]',
    '//XCUIElementTypeCell[.//XCUIElementTypeStaticText[@label="\u200eExport chat"]]',
    "~\u200eExport chat",
  ]);
  if (!exportSelector) {
    throw new Error("Non trovo la voce Export chat.");
  }

  await pause(1800);
}

async function chooseWithoutMedia(client) {
  const selector = await clickFirstExisting(client, [
    "~Without media",
    '//XCUIElementTypeButton[@name="Without media"]',
    '//XCUIElementTypeStaticText[@name="Without media"]',
  ]);

  if (!selector) {
    await client.execute("mobile: tap", { x: 240, y: 1585 });
  }

  await pause(2200);
}

async function openSaveToFiles(client) {
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
}

async function ensureFolderAndSave(client) {
  const saveVisible = await clickFirstExisting(client, [
    "~Save",
    '//XCUIElementTypeButton[@name="Save"]',
  ]);

  if (!saveVisible) {
    const folderSelector = await clickFirstExisting(client, [
      `~${targetFolderName}`,
      `//XCUIElementTypeCell[.//XCUIElementTypeStaticText[@name="${targetFolderName}"]]`,
      `~${fallbackFolderName}`,
      `//XCUIElementTypeCell[.//XCUIElementTypeStaticText[@name="${fallbackFolderName}"]]`,
    ]);

    if (!folderSelector) {
      throw new Error(`Non trovo ne' ${targetFolderName} ne' ${fallbackFolderName} nel picker Files.`);
    }

    await pause(1800);

    const finalSaveSelector = await clickFirstExisting(client, [
      "~Save",
      '//XCUIElementTypeButton[@name="Save"]',
    ]);

    if (!finalSaveSelector) {
      throw new Error("Non trovo il pulsante Save nel picker Files.");
    }
  }

  await pause(3500);
}

const client = await createClient();

try {
  const base = timestamp();
  await navigateToChooseChat(client);

  const rowsToExport = rowYs.slice(0, Math.max(0, maxExports));

  for (let index = 0; index < rowsToExport.length; index += 1) {
    const y = rowsToExport[index];

    await client.execute("mobile: tap", { x: 320, y });
    await pause(2200);

    await chooseWithoutMedia(client);
    await openSaveToFiles(client);
    await ensureFolderAndSave(client);
    await pause(1800);
  }

  const screenshotPath = await saveScreenshot(client, `${base}-after-batch-visible-export`);
  console.log(`Batch visibile completato. Screenshot finale: ${screenshotPath}`);
} finally {
  await client.deleteSession();
}
