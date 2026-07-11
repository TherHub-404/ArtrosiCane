import { createClient, dumpVisibleElements, pause, saveScreenshot, timestamp } from "./lib/session-utils.mjs";

const client = await createClient();

try {
  const base = timestamp();
  const exportCellSelector = '~SettingsChatsView_ExportChatCell';

  const exportCell = await client.$(exportCellSelector);
  if (!(await exportCell.isExisting())) {
    throw new Error("La schermata corrente non mostra SettingsChatsView_ExportChatCell.");
  }

  await exportCell.click();
  await pause(2000);

  const screenshotPath = await saveScreenshot(client, `${base}-export-chat-list`);
  const { dumpPath } = await dumpVisibleElements(client, `${base}-export-chat-list`);

  console.log(`Screenshot salvato in ${screenshotPath}`);
  console.log(`Elementi visibili salvati in ${dumpPath}`);
} finally {
  await client.deleteSession();
}
