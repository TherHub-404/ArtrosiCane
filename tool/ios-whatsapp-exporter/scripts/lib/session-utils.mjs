import fs from "node:fs/promises";
import path from "node:path";
import { execFile } from "node:child_process";
import { promisify } from "node:util";
import { fileURLToPath } from "node:url";
import "dotenv/config";
import { remote } from "webdriverio";

const execFileAsync = promisify(execFile);
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const rootDir = path.resolve(__dirname, "..", "..");
const artifactsDir = path.join(rootDir, "artifacts");
const ocrScriptPath = path.join(__dirname, "ocr-image.swift");

const udid = process.env.IOS_UDID;
const bundleId = process.env.APP_BUNDLE_ID;
const wdaBundleId = process.env.WDA_BUNDLE_ID;
const xcodeOrgId = process.env.XCODE_ORG_ID;
const xcodeSigningId = process.env.XCODE_SIGNING_ID || "Apple Development";

export function getArtifactsDir() {
  return artifactsDir;
}

export function timestamp() {
  return new Date().toISOString().replaceAll(":", "-");
}

export async function createClient() {
  if (!udid || !bundleId || !xcodeOrgId || !wdaBundleId) {
    throw new Error("Config incompleta. Servono IOS_UDID, APP_BUNDLE_ID, WDA_BUNDLE_ID e XCODE_ORG_ID nel file .env.");
  }

  await fs.mkdir(artifactsDir, { recursive: true });

  return remote({
    hostname: "127.0.0.1",
    port: 4723,
    path: "/wd/hub",
    logLevel: process.env.WDIO_LOG_LEVEL || "warn",
    connectionRetryTimeout: Number(process.env.WDIO_CONNECTION_RETRY_TIMEOUT || "7000"),
    connectionRetryCount: Number(process.env.WDIO_CONNECTION_RETRY_COUNT || "1"),
    capabilities: {
      platformName: "iOS",
      "appium:automationName": "XCUITest",
      "appium:udid": udid,
      "appium:bundleId": bundleId,
      "appium:noReset": true,
      "appium:newCommandTimeout": 300,
      "appium:showXcodeLog": (process.env.SHOW_XCODE_LOG || "false") === "true",
      "appium:xcodeOrgId": xcodeOrgId,
      "appium:xcodeSigningId": xcodeSigningId,
      "appium:updatedWDABundleId": wdaBundleId,
      "appium:allowProvisioningDeviceRegistration": true,
      "appium:waitForIdleTimeout": Number(process.env.WAIT_FOR_IDLE_TIMEOUT || "0"),
      "appium:animationCoolOffTimeout": Number(process.env.ANIMATION_COOL_OFF_TIMEOUT || "0"),
      "appium:shouldWaitForQuiescence": (process.env.SHOULD_WAIT_FOR_QUIESCENCE || "false") === "true",
      "appium:wdaLaunchTimeout": Number(process.env.WDA_LAUNCH_TIMEOUT || "60000"),
      "appium:wdaStartupRetries": Number(process.env.WDA_STARTUP_RETRIES || "1"),
      "appium:wdaStartupRetryInterval": Number(process.env.WDA_STARTUP_RETRY_INTERVAL || "10000"),
    },
  });
}

export async function saveScreenshot(client, basename) {
  const screenshotPath = path.join(artifactsDir, `${basename}.png`);
  const screenshot = await client.takeScreenshot();
  await fs.writeFile(screenshotPath, screenshot, "base64");
  return screenshotPath;
}

export async function readScreenshotText(imagePath) {
  const { stdout } = await execFileAsync("swift", [ocrScriptPath, imagePath], {
    maxBuffer: 1024 * 1024,
  });
  return stdout.trim();
}

export async function saveScreenshotAndReadText(client, basename) {
  const screenshotPath = await saveScreenshot(client, basename);
  const text = await readScreenshotText(screenshotPath);
  return { screenshotPath, text };
}

export async function dumpVisibleElements(client, basename) {
  const selectors = [
    "//XCUIElementTypeButton",
    "//XCUIElementTypeCell",
    "//XCUIElementTypeStaticText",
    "//XCUIElementTypeSearchField",
    "//XCUIElementTypeTextField",
    "//XCUIElementTypeTextView",
    "//XCUIElementTypeImage",
    "//XCUIElementTypeSheet",
    "//XCUIElementTypeScrollView",
  ];

  const collected = [];

  for (const selector of selectors) {
    let elements = [];
    try {
      elements = await client.$$(selector);
    } catch {
      continue;
    }

    for (const element of elements.slice(0, 80)) {
      try {
        const [name, label, value, visible, enabled] = await Promise.all([
          element.getAttribute("name").catch(() => null),
          element.getAttribute("label").catch(() => null),
          element.getAttribute("value").catch(() => null),
          element.getAttribute("visible").catch(() => null),
          element.getAttribute("enabled").catch(() => null),
        ]);

        collected.push({
          selector,
          name,
          label,
          value,
          visible,
          enabled,
        });
      } catch {
        // Ignore stale or unreadable elements.
      }
    }
  }

  const dumpPath = path.join(artifactsDir, `${basename}-visible-elements.json`);
  await fs.writeFile(dumpPath, JSON.stringify(collected, null, 2), "utf8");
  return { dumpPath, elements: collected };
}

export async function describeElements(client, selector, limit = 40) {
  let elements = [];
  try {
    elements = await client.$$(selector);
  } catch {
    return [];
  }

  const described = [];

  for (const element of elements.slice(0, limit)) {
    try {
      const [name, label, value, visible, enabled, rect] = await Promise.all([
        element.getAttribute("name").catch(() => null),
        element.getAttribute("label").catch(() => null),
        element.getAttribute("value").catch(() => null),
        element.getAttribute("visible").catch(() => null),
        element.getAttribute("enabled").catch(() => null),
        element.getRect().catch(() => null),
      ]);

      described.push({
        selector,
        name,
        label,
        value,
        visible,
        enabled,
        rect,
      });
    } catch {
      // Ignore stale or unreadable elements.
    }
  }

  return described;
}

export async function saveJsonArtifact(basename, payload) {
  const dumpPath = path.join(artifactsDir, `${basename}.json`);
  await fs.writeFile(dumpPath, JSON.stringify(payload, null, 2), "utf8");
  return dumpPath;
}

export async function clickIfExists(client, selector) {
  try {
    const element = await client.$(selector);
    const exists = await element.isExisting();
    if (!exists) {
      return false;
    }
    await element.click();
    return true;
  } catch {
    return false;
  }
}

export async function clickFirstExisting(client, selectors) {
  for (const selector of selectors) {
    try {
      const element = await client.$(selector);
      if (await element.isExisting()) {
        await element.click();
        return selector;
      }
    } catch {
      // Ignore selector timeouts and fall back to the next strategy.
    }
  }
  return null;
}

export async function elementExists(client, selector) {
  try {
    const element = await client.$(selector);
    return element.isExisting();
  } catch {
    return false;
  }
}

export async function pause(ms = 1500) {
  await new Promise((resolve) => setTimeout(resolve, ms));
}
