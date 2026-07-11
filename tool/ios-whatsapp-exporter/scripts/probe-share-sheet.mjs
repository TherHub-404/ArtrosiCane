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

  const beforePath = await saveScreenshot(client, `${base}-choose-chat-before-coordinate-tap`);

  // Coordinates tuned against the real screenshot (828x1792) to hit the first
  // visible chat row under "Frequently contacted" instead of the restriction banner.
  await client.execute("mobile: tap", { x: 320, y: 470 });
  await pause(2200);

  const afterPath = await saveScreenshot(client, `${base}-after-coordinate-chat-tap`);
  const buttons = await describeElements(client, "//XCUIElementTypeButton", 30);
  const sheets = await describeElements(client, "//XCUIElementTypeSheet", 10);
  const texts = await describeElements(client, "//XCUIElementTypeStaticText", 40);

  const dumpPath = await saveJsonArtifact(`${base}-after-coordinate-chat-tap`, {
    buttons,
    sheets,
    texts,
  });

  console.log(`Screenshot prima del tap: ${beforePath}`);
  console.log(`Screenshot dopo il tap: ${afterPath}`);
  console.log(`Dump share sheet: ${dumpPath}`);
} finally {
  await client.deleteSession();
}
