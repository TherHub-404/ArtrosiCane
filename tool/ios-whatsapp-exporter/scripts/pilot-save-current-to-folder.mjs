import "dotenv/config";
import {
  clickFirstExisting,
  createClient,
  pause,
  saveScreenshotAndReadText,
  timestamp,
} from "./lib/session-utils.mjs";

const targetFolderName = process.env.EXPORT_ROOT_NAME || "Chat-Clyo-Full";
const chooseChatTap = { x: 200, y: 401 };
const withoutMediaTap = { x: 240, y: 1585 };
const saveToFilesTap = { x: 171, y: 1457 };
const saveTap = { x: 774, y: 72 };

function lines(text) {
  return text.split("\n").slice(0, 18).join(" | ");
}

async function checkpoint(client, label) {
  const shot = await saveScreenshotAndReadText(client, `${timestamp()}-${label}`);
  console.log(`${label}: ${lines(shot.text)}`);
  console.log(`${label} screenshot: ${shot.screenshotPath}`);
  return shot;
}

const client = await createClient();

try {
  const start = await checkpoint(client, "pilot-start");

  if (start.text.toLowerCase().includes("choose chat")) {
    console.log("Open first chat from Choose chat");
    await client.execute("mobile: tap", chooseChatTap);
    await pause(2200);
    await checkpoint(client, "pilot-after-open-first-chat");
  }

  console.log("Tap Without media");
  await client.execute("mobile: tap", withoutMediaTap);
  await pause(2200);
  let afterWithoutMedia = await checkpoint(client, "pilot-after-without-media");

  if (afterWithoutMedia.text.toLowerCase().includes("export chat")) {
    console.log("Retry Without media");
    await client.execute("mobile: tap", withoutMediaTap);
    await pause(2200);
    afterWithoutMedia = await checkpoint(client, "pilot-after-without-media-retry");
  }

  console.log("Open Save to Files");
  const saveToFilesSelector = await clickFirstExisting(client, [
    "~Save to Files",
    '//XCUIElementTypeButton[@name="Save to Files"]',
    '//XCUIElementTypeStaticText[@name="Save to Files"]',
    '//XCUIElementTypeCell[.//XCUIElementTypeStaticText[@name="Save to Files"]]',
  ]);
  if (!saveToFilesSelector) {
    await client.execute("mobile: tap", saveToFilesTap);
  }
  await pause(2600);

  const picker = await checkpoint(client, "pilot-after-save-to-files");

  const pickerText = picker.text.toLowerCase();
  const folderAlreadyOpen = pickerText.includes(targetFolderName.toLowerCase()) && pickerText.includes("save");

  if (!folderAlreadyOpen) {
    console.log("Search target folder");
    const search = await client.$("//XCUIElementTypeSearchField");
    if (await search.isExisting()) {
      await search.click();
      await pause(600);
      await search.setValue(targetFolderName);
    } else {
      await client.execute("mobile: tap", { x: 235, y: 133 });
      await pause(600);
      const keyboard = await client.$("//XCUIElementTypeSearchField");
      if (await keyboard.isExisting()) {
        await keyboard.setValue(targetFolderName);
      } else {
        throw new Error("Non trovo il campo Search nel picker Files.");
      }
    }
    await pause(1800);
    await checkpoint(client, "pilot-after-search");

    console.log("Open target folder");
    const folderSelector = await clickFirstExisting(client, [
      `~${targetFolderName}`,
      `//XCUIElementTypeCell[.//XCUIElementTypeStaticText[@name="${targetFolderName}"]]`,
      `//XCUIElementTypeStaticText[@name="${targetFolderName}"]`,
      `//XCUIElementTypeStaticText[@label="${targetFolderName}"]`,
    ]);

    if (!folderSelector) {
      throw new Error(`Non trovo la cartella ${targetFolderName} nel picker Files.`);
    }

    await pause(1800);
    await checkpoint(client, "pilot-after-open-folder");
  }

  console.log("Confirm Save");
  const saveSelector = await clickFirstExisting(client, [
    "~Save",
    '//XCUIElementTypeButton[@name="Save"]',
  ]);
  if (!saveSelector) {
    await client.execute("mobile: tap", saveTap);
  }
  await pause(3200);

  await checkpoint(client, "pilot-after-save");
} finally {
  await client.deleteSession();
}
