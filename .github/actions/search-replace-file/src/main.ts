import * as core from "@actions/core";
import replaceInFile from "replace-in-file";

(async function main(argv: string[]): Promise<void> {
	const from = core.getInput("from", { required: true });
	const expressionParts = from.split("/");
	const result = await replaceInFile({
		files: core.getInput("files", { required: true }),
		from: new RegExp(expressionParts[1], expressionParts[2]),
		to: core.getInput("to", { required: true }),
	});
	core.info(JSON.stringify(result, undefined, 4));
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
