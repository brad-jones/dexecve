import * as path from "path";
import * as core from "@actions/core";
import * as tc from "@actions/tool-cache";

(async function main(argv: string[]): Promise<void> {
	const isWin = /^win/.test(process.platform);
	const isMac = process.platform === "darwin";
	const dartOS = isWin ? "windows" : isMac ? "macos" : "linux";
	const dartVersion = core.getInput("version") || "latest";
	const dartChannel = dartVersion.includes("dev") ? "dev" : "stable";
	const url = `https://storage.googleapis.com/dart-archive/channels/${dartChannel}/release/${dartVersion}/sdk/dartsdk-${dartOS}-x64-release.zip`;
	const dartZipPath = await tc.downloadTool(url);
	const dartSdkPath = await tc.extractZip(dartZipPath);
	core.addPath(path.join(dartSdkPath, "dart-sdk", "bin"));
	core.setOutput("dart-sdk", dartSdkPath);
})(process.argv)
	.then(() => {
		process.exit(0);
	})
	.catch(e => {
		if (e["message"] !== undefined) {
			core.setFailed(e.message);
		}
		console.error(e);
		process.exit(1);
	});
