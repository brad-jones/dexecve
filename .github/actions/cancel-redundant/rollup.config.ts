import { RollupOptions } from "rollup";
import { terser } from "rollup-plugin-terser";
import commonjs from "@rollup/plugin-commonjs";
import json from "@rollup/plugin-json";
import resolve from "@rollup/plugin-node-resolve";
import typescript from "@rollup/plugin-typescript";

const nodeJsBuiltInModules = [
	"assert",
	"buffer",
	"child_process",
	"cluster",
	"crypto",
	"dgram",
	"dns",
	"domain",
	"events",
	"fs",
	"http",
	"https",
	"net",
	"os",
	"path",
	"punycode",
	"querystring",
	"readline",
	"stream",
	"string_decoder",
	"timers",
	"tls",
	"tty",
	"url",
	"util",
	"v8",
	"vm",
	"zlib",
];

export default {
	input: "./src/main.ts",
	output: {
		file: "./dist/main.js",
		format: "cjs",
	},
	treeshake: true,
	external: [...nodeJsBuiltInModules],
	plugins: [
		json(),
		typescript(),
		resolve({ preferBuiltins: true }),
		commonjs(),
		terser(),
	],
	onwarn(error, warn) {
		if (error.code !== "CIRCULAR_DEPENDENCY") {
			warn(error);
		}
	},
} as RollupOptions;
