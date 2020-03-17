import * as core from "@actions/core";
import * as github from "@actions/github";

(async function main(argv: string[]): Promise<void> {
	// Create a new instance of the Github REST client
	const octokit = new github.GitHub(core.getInput("token"));

	// Bail out early if it's not a push or a pr
	const event = process.env["GITHUB_EVENT_NAME"];
	if (!["push", "pull_request"].includes(event)) {
		core.info("Skipping unsupported event");
		return;
	}

	// Determine the branch we are running on
	const branchPrefix = "refs/heads/";
	const tagPrefix = "refs/tags/";
	const pullRequest = "pull_request" === event;
	const fqBranch = pullRequest
		? process.env["GITHUB_HEAD_REF"]
		: process.env["GITHUB_REF"];
	if (!pullRequest && !fqBranch.startsWith(branchPrefix)) {
		if (fqBranch.startsWith(tagPrefix)) {
			core.info("Skipping tag build");
			return;
		}
		throw new Error(
			`${fqBranch} was not an expected branch ref (refs/heads/).`
		);
	}
	const branch = fqBranch.replace(branchPrefix, "");

	// Get the workflow id
	const runId = process.env["GITHUB_RUN_ID"];
	const repository = process.env["GITHUB_REPOSITORY"];
	const [owner, repo] = repository.split("/");
	const reply = await octokit.actions.getWorkflowRun({
		owner,
		repo,
		run_id: Number.parseInt(runId),
	});
	const workFlowId = reply.data.workflow_url.split("/").pop() || "";
	if (!(workFlowId.length > 0)) {
		throw new Error("Could not resolve workflow");
	}
	core.info(
		JSON.stringify(
			{
				owner,
				repo,
				branch,
				runId,
				workFlowId,
			},
			undefined,
			4
		)
	);

	// Find all workflow runs that can be canceled
	for (const status of ["queued", "in_progress"]) {
		const listRuns = octokit.actions.listWorkflowRuns.endpoint.merge({
			owner,
			repo,
			workflow_id: workFlowId,
			status,
			branch,
			event,
		});

		for await (const item of octokit.paginate.iterator(listRuns)) {
			// There is some sort of bug where the pagination URLs point to a
			// different endpoint URL which trips up the resulting representation
			// In that case, fallback to the actual REST 'workflow_runs' property
			const runs =
				item.data.length === undefined
					? item.data.workflow_runs
					: item.data;

			for (const run of runs) {
				// Make sure we don't cancel ourselves
				if (run.id === parseInt(runId)) {
					continue;
				}
				try {
					const reply = await octokit.actions.cancelWorkflowRun({
						owner,
						repo,
						run_id: run.id,
					});
					core.info(
						`Previous run (id ${run.id}) cancelled, status = ${reply.status}`
					);
				} catch (error) {
					core.info(
						`[warn] Could not cancel run (id ${run.id}): [${error.status}] ${error.message}`
					);
				}
			}
		}
	}
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
