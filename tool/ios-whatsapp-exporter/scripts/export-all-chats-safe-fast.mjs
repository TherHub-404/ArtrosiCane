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

const bundleId = process.env.APP_BUNDLE_ID;
const defaultRowYs = [401, 579, 756, 934];
const rowYs = (process.env.ROW_YS || defaultRowYs.join(","))
  .split(",")
  .map((value) => Number.parseInt(value.trim(), 10))
  .filter((value) => Number.isFinite(value));

const maxPages = Number.parseInt(process.env.MAX_PAGES || "25", 10);
const afterChatTapMs = Number(process.env.AFTER_CHAT_TAP_MS || "550");
const afterWithoutMediaMs = Number(process.env.AFTER_WITHOUT_MEDIA_MS || "500");
const afterSaveToFilesMs = Number(process.env.AFTER_SAVE_TO_FILES_MS || "800");
const afterSaveMs = Number(process.env.AFTER_SAVE_MS || "1100");
const afterDuplicateDecisionMs = Number(process.env.AFTER_DUPLICATE_DECISION_MS || "700");
const afterSwipeMs = Number(process.env.AFTER_SWIPE_MS || "1200");
const startFromCurrent = (process.env.START_FROM_CURRENT || "false") === "true";
const trustCurrentPosition = (process.env.TRUST_CURRENT_POSITION || "false") === "true";
const chatTapX = Number(process.env.CHAT_TAP_X || "200");
const keepBothX = Number(process.env.KEEP_BOTH_X || "414");
const keepBothY = Number(process.env.KEEP_BOTH_Y || "918");

function classifyScreenText(text) {
  const normalized = text.toLowerCase();

  if (normalized.includes("choose chat")) {
    return "choose_chat";
  }
  if (normalized.includes("replace existing items") || normalized.includes("keep both")) {
    return "duplicate_popup";
  }
  if (normalized.includes("save to files")) {
    return "share_sheet";
  }
  if (normalized.includes("clear chats") || normalized.includes("clear all chats")) {
    return "clear_chats";
  }
  if (normalized.includes("chat-clyo")) {
    return "files_picker";
  }
  if (normalized.includes("without media") || normalized.includes("attach media")) {
    return "export_sheet";
  }

  return "unknown";
}

async function activateWhatsApp(client) {
  await client.execute("mobile: activateApp", { bundleId });
  await pause(600);
}

async function navigateToExportList(client) {
  await clickFirstExisting(client, [
    "~Back",
    '//XCUIElementTypeButton[@name="Back"]',
  ]);
  await pause(200);

  await clickFirstExisting(client, [
    "~Close",
    "~\u200eDismiss banner",
  ]);
  await pause(200);

  let settingsSelector = await clickFirstExisting(client, [
    "~TabBarButton_Settings",
    "~\u200eSettings",
  ]);
  if (!settingsSelector) {
    await client.execute("mobile: tap", { x: 34, y: 88 });
    await pause(400);
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
}

async function recoverToExportList(client) {
  console.log("Riallineo a Export Chat...");
  await activateWhatsApp(client);
  await navigateToExportList(client);
}

async function ensureChooseChat(client) {
  const inExportList = await elementExists(client, "~TabBarButton_Settings").catch(() => false);
  if (inExportList) {
    return;
  }
  await recoverToExportList(client);
}

async function openExportSheetForRow(client, y) {
  const beforeScreen = await client.takeScreenshot();
  await client.execute("mobile: tap", { x: chatTapX, y });
  await pause(afterChatTapMs);

  const afterTapScreen = await client.takeScreenshot();
  if (afterTapScreen === beforeScreen) {
    return false;
  }

  await client.execute("mobile: tap", { x: 240, y: 1585 });
  console.log("Toccato Without media.");
  return true;
}

async function finishExportCurrentChat(client) {
  await pause(afterWithoutMediaMs);

  console.log("Apro Save to Files...");
  await client.execute("mobile: tap", { x: 171, y: 1457 });

  await pause(afterSaveToFilesMs);

  console.log("Confermo Save...");
  await client.execute("mobile: tap", { x: 775, y: 72 });

  await pause(afterSaveMs);

  const { screenshotPath, text } = await saveScreenshotAndReadText(
    client,
    `${timestamp()}-post-save-check`,
  );
  const screen = classifyScreenText(text);
  console.log(`Schermata dopo Save: ${screen} (${screenshotPath})`);

  if (screen === "duplicate_popup") {
    console.log("Duplicato trovato, scelgo Keep Both.");
    await client.execute("mobile: tap", { x: keepBothX, y: keepBothY });
    await pause(afterDuplicateDecisionMs);
    const duplicateResolved = await saveScreenshotAndReadText(
      client,
      `${timestamp()}-after-keep-both`,
    );
    const resolvedScreen = classifyScreenText(duplicateResolved.text);
    console.log(`Schermata dopo Keep Both: ${resolvedScreen} (${duplicateResolved.screenshotPath})`);
    return resolvedScreen === "choose_chat";
  }

  return screen === "choose_chat";
}

async function exportVisibleRows(client) {
  for (let index = 0; index < rowYs.length; index += 1) {
    const y = rowYs[index];
    console.log(`Riga ${index + 1}/${rowYs.length} alla quota y=${y}`);

    const opened = await openExportSheetForRow(client, y);
    if (!opened) {
      const stillOnChooseChat = await elementExists(client, "~TabBarButton_Settings").catch(() => false);
      if (stillOnChooseChat) {
        console.log("Tap mancato ma siamo ancora su Choose chat, passo alla riga successiva.");
        continue;
      }

      console.log("Export sheet non trovata e non siamo piu' su Choose chat, provo a recuperare.");
      await recoverToExportList(client);
      continue;
    }

    const saved = await finishExportCurrentChat(client);
    if (!saved) {
      console.log("Save non trovato, provo a recuperare.");
      await recoverToExportList(client);
      continue;
    }

    console.log("Chat salvata, verifico il ritorno alla lista.");
    if (!trustCurrentPosition) {
      await ensureChooseChat(client);
    }
  }
}

async function swipeToNextPage(client) {
  await client.execute("mobile: swipe", { direction: "up" });
  await pause(afterSwipeMs);
}

const client = await createClient();

try {
  const base = timestamp();
  if (startFromCurrent && trustCurrentPosition) {
    console.log("Riparto direttamente dalla Choose chat corrente.");
  } else if (startFromCurrent) {
    console.log("Provo a riprendere dalla schermata corrente.");
    await ensureChooseChat(client);
  } else {
    await recoverToExportList(client);
  }

  let previousScreen = await client.takeScreenshot();

  for (let pageIndex = 0; pageIndex < maxPages; pageIndex += 1) {
    console.log(`Pagina ${pageIndex + 1}/${maxPages}`);
    await exportVisibleRows(client);

    if (pageIndex === maxPages - 1) {
      break;
    }

    console.log("Swipe verso la pagina successiva...");
    await swipeToNextPage(client);
    if (!trustCurrentPosition) {
      await ensureChooseChat(client);
    }

    const nextScreen = await client.takeScreenshot();
    if (nextScreen === previousScreen) {
      console.log(`Stop automatico alla pagina ${pageIndex + 1}: nessun cambiamento dopo lo swipe.`);
      break;
    }

    previousScreen = nextScreen;
  }

  const screenshotPath = await saveScreenshot(client, `${base}-after-safe-fast-export`);
  console.log(`Export safe-fast terminato. Screenshot finale: ${screenshotPath}`);
} finally {
  await client.deleteSession();
}
