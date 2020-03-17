module.exports = {
	"*.dart": "dartfmt -w",
	"*.{ts,js,json,yml,yaml}": "prettier --write",
	".github/actions/**/*.*": [
		() => "pnpm run --filter ./.github/actions build",
		"git add ./.github/actions",
	],
};
