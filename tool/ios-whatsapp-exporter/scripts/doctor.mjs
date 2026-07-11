import { execFileSync } from "node:child_process";

function run(command, args) {
  try {
    const output = execFileSync(command, args, {
      encoding: "utf8",
      stdio: ["ignore", "pipe", "pipe"],
    });
    return { ok: true, output: output.trim() };
  } catch (error) {
    const stdout = error.stdout?.toString?.() ?? "";
    const stderr = error.stderr?.toString?.() ?? "";
    return {
      ok: false,
      output: `${stdout}${stderr}`.trim(),
      code: error.status ?? 1,
    };
  }
}

function printSection(title, body) {
  console.log(`\n=== ${title} ===`);
  console.log(body || "(no output)");
}

const xcode = run("xcodebuild", ["-version"]);
const devices = run("xcrun", ["xctrace", "list", "devices"]);
const identities = run("security", ["find-identity", "-v", "-p", "codesigning"]);
const pair = run("xcrun", ["devicectl", "list", "devices"]);
const appInfo = run("xcrun", [
  "devicectl",
  "device",
  "info",
  "apps",
  "--device",
  process.env.IOS_UDID ?? "00008030-000174C11439802E",
]);

printSection("Xcode", xcode.output);
printSection("Devices", devices.output);
printSection("Code Signing", identities.output);
printSection("CoreDevice", pair.output);
printSection("App Visibility", appInfo.output);

console.log("\n=== Summary ===");
if (!xcode.ok) {
  console.log("- Xcode non disponibile.");
}
if (appInfo.ok) {
  console.log("- Device pronto per leggere le app installate.");
} else if (appInfo.output.includes("Developer Mode is disabled")) {
  console.log("- Attiva Developer Mode su iPhone per continuare.");
} else if (appInfo.output.includes("must be paired")) {
  console.log("- Il device deve essere paired con devicectl/Xcode.");
} else {
  console.log("- C'e' ancora un blocco da risolvere prima di ispezionare WhatsApp Business.");
}
