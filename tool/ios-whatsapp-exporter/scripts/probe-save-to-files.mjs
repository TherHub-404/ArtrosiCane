import {
  clickFirstExisting,
  createClient,
  describeElements,
  pause,
  saveJsonArtifact,
  saveScreenshot,
  timestamp,
} from "./lib/session-utils.mjs";

async function navigateToExportList(client) {
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

  await pause(1200);

  const chatsSelector = await clickFirstExisting(client, [
    '//XCUIElementTypeCell[.//XCUIElementTypeStaticText[@name="\u200eChats"]]',
    '//XCUIElementTypeCell[.//XCUIElementTypeStaticText[@label="\u200eChats"]]',
    "~\u200eChats",
  ]);
  if (!chatsSelector) {
    throw new Error("Non trovo la voce Chats.");
  }

  await pause(1200);

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

const client = await createClient();

try {
  const base = timestamp();
  await navigateToExportList(client);

  await client.execute("mobile: tap", { x: 320, y: 470 });
  await pause(2200);
  const exportSheetPath = await saveScreenshot(client, `${base}-export-sheet`);

  // Coordinates tuned on the real screenshot of the export sheet.
  await client.execute("mobile: tap", { x: 240, y: 1585 });
  await pause(3200);

  const afterPath = await saveScreenshot(client, `${base}-after-without-media`);
  const buttons = await describeElements(client, "//XCUIElementTypeButton", 30);
  const cells = await describeElements(client, "//XCUIElementTypeCell", 20);
  const texts = await describeElements(client, "//XCUIElementTypeStaticText", 50);
  const sheets = await describeElements(client, "//XCUIElementTypeSheet", 10);

  const dumpPath = await saveJsonArtifact(`${base}-after-without-media`, {
    buttons,
    cells,
    texts,
    sheets,
  });

  console.log(`Screenshot export sheet: ${exportSheetPath}`);
  console.log(`Screenshot dopo 'Without media': ${afterPath}`);
  console.log(`Dump dopo 'Without media': ${dumpPath}`);
} finally {
  await client.deleteSession();
}
