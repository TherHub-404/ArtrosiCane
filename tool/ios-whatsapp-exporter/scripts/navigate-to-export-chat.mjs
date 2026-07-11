import { clickFirstExisting, createClient, dumpVisibleElements, pause, saveScreenshot, timestamp } from "./lib/session-utils.mjs";

const client = await createClient();

try {
  const base = timestamp();

  await clickFirstExisting(client, [
    '~Close',
    '~\u200eDismiss banner',
  ]);
  await pause(800);

  const settingsSelector = await clickFirstExisting(client, [
    '~TabBarButton_Settings',
    '~\u200eSettings',
  ]);
  if (!settingsSelector) {
    throw new Error("Non trovo il tab Settings in WhatsApp Business.");
  }

  await pause(1200);

  const chatsSelector = await clickFirstExisting(client, [
    '//XCUIElementTypeCell[.//XCUIElementTypeStaticText[@name="\u200eChats"]]',
    '//XCUIElementTypeCell[.//XCUIElementTypeStaticText[@label="\u200eChats"]]',
    '~\u200eChats',
  ]);
  if (!chatsSelector) {
    throw new Error("Non trovo la voce Chats nelle impostazioni.");
  }

  await pause(1200);

  const exportSelector = await clickFirstExisting(client, [
    '~SettingsChatsView_ExportChatCell',
    '//XCUIElementTypeCell[.//XCUIElementTypeStaticText[@name="\u200eExport chat"]]',
    '//XCUIElementTypeCell[.//XCUIElementTypeStaticText[@label="\u200eExport chat"]]',
    '~\u200eExport chat',
  ]);
  if (!exportSelector) {
    throw new Error("Non trovo la voce Export chat nella schermata Chats.");
  }

  await pause(2000);

  const screenshotPath = await saveScreenshot(client, `${base}-export-list`);
  const { dumpPath } = await dumpVisibleElements(client, `${base}-export-list`);

  console.log(`Settings selector usato: ${settingsSelector}`);
  console.log(`Chats selector usato: ${chatsSelector}`);
  console.log(`Export selector usato: ${exportSelector}`);
  console.log(`Screenshot salvato in ${screenshotPath}`);
  console.log(`Elementi visibili salvati in ${dumpPath}`);
} finally {
  await client.deleteSession();
}
