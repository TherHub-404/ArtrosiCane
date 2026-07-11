import { clickFirstExisting, createClient, pause } from "./lib/session-utils.mjs";

const client = await createClient();

try {
  await clickFirstExisting(client, [
    "~Back",
    '//XCUIElementTypeButton[@name="Back"]',
  ]);
  await pause(250);

  await clickFirstExisting(client, [
    "~Close",
    "~\u200eDismiss banner",
  ]);
  await pause(250);

  let settingsSelector = await clickFirstExisting(client, [
    "~TabBarButton_Settings",
    "~\u200eSettings",
  ]);
  if (!settingsSelector) {
    await client.execute("mobile: tap", { x: 34, y: 88 });
    await pause(500);
    settingsSelector = await clickFirstExisting(client, [
      "~TabBarButton_Settings",
      "~\u200eSettings",
    ]);
  }
  if (!settingsSelector) {
    throw new Error("Non trovo il tab Settings.");
  }

  await pause(500);

  const chatsSelector = await clickFirstExisting(client, [
    '//XCUIElementTypeCell[.//XCUIElementTypeStaticText[@name="\u200eChats"]]',
    '//XCUIElementTypeCell[.//XCUIElementTypeStaticText[@label="\u200eChats"]]',
    "~\u200eChats",
  ]);
  if (!chatsSelector) {
    throw new Error("Non trovo la voce Chats.");
  }

  await pause(500);

  const exportSelector = await clickFirstExisting(client, [
    "~SettingsChatsView_ExportChatCell",
    '//XCUIElementTypeCell[.//XCUIElementTypeStaticText[@name="\u200eExport chat"]]',
    '//XCUIElementTypeCell[.//XCUIElementTypeStaticText[@label="\u200eExport chat"]]',
    "~\u200eExport chat",
  ]);
  if (!exportSelector) {
    throw new Error("Non trovo la voce Export chat.");
  }

  await pause(700);
  console.log("Export list aperta.");
} finally {
  await client.deleteSession();
}
