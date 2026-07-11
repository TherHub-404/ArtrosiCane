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

function isLikelyChatCell(cell) {
  const text = [cell.name, cell.label, cell.value].filter(Boolean).join(" | ");
  if (!text) {
    return false;
  }

  const blocked = [
    "Close",
    "Settings",
    "Chats",
    "Updates",
    "Calls",
    "Tools",
    "Frequently contacted",
    "Recent chats",
    "Choose chat",
    "restricted",
    "Show details",
  ];

  return !blocked.some((part) => text.includes(part));
}

const client = await createClient();

try {
  const base = timestamp();

  await navigateToExportList(client);

  const beforeCells = await describeElements(client, "//XCUIElementTypeCell", 30);
  const beforeButtons = await describeElements(client, "//XCUIElementTypeButton", 20);
  const beforeTexts = await describeElements(client, "//XCUIElementTypeStaticText", 40);

  const dumpPath = await saveJsonArtifact(`${base}-choose-chat-probe`, {
    stage: "choose-chat",
    beforeCells,
    beforeButtons,
    beforeTexts,
  });
  const screenshotPath = await saveScreenshot(client, `${base}-choose-chat-probe`);

  const candidate = beforeCells.find(isLikelyChatCell);
  if (!candidate) {
    throw new Error("Non trovo una chat cliccabile nella schermata Choose chat.");
  }

  const selector = `//XCUIElementTypeCell[@name=${JSON.stringify(candidate.name)}]`;
  const cell = await client.$(selector);
  await cell.click();
  await pause(1800);

  const afterButtons = await describeElements(client, "//XCUIElementTypeButton", 25);
  const afterCells = await describeElements(client, "//XCUIElementTypeCell", 20);
  const afterTexts = await describeElements(client, "//XCUIElementTypeStaticText", 50);

  const afterDumpPath = await saveJsonArtifact(`${base}-after-chat-tap`, {
    stage: "after-chat-tap",
    tappedCell: candidate,
    afterButtons,
    afterCells,
    afterTexts,
  });
  const afterScreenshotPath = await saveScreenshot(client, `${base}-after-chat-tap`);

  console.log(`Probe salvato in ${dumpPath}`);
  console.log(`Screenshot lista chat in ${screenshotPath}`);
  console.log(`Chat toccata: ${candidate.name || candidate.label || candidate.value}`);
  console.log(`Dump dopo tap in ${afterDumpPath}`);
  console.log(`Screenshot dopo tap in ${afterScreenshotPath}`);
} finally {
  await client.deleteSession();
}
