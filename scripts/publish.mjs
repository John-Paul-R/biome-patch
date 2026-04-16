import { execSync } from "node:child_process";
import * as fs from "node:fs";
import * as path from "node:path";

const scope = requireEnv("SCOPE");
const version = requireEnv("VERSION");
const repoSlug = requireEnv("GITHUB_REPOSITORY");
const serverUrl = process.env.GITHUB_SERVER_URL || "https://github.com";
const registry = "https://npm.pkg.github.com";
const oldScope = "@biomejs/";
const newScope = `@${scope}/`;

const biomeDir = path.resolve("biome");
const pkgRoot = path.join(biomeDir, "packages/@biomejs");
const rootManifestPath = path.join(pkgRoot, "biome/package.json");

// Packages to publish. biome's own publish workflow skips js-api / plugin-api;
// we additionally skip backend-jsonrpc and wasm-* to keep the personal
// registry scoped to the CLI.
const publishDirs = [
    "biome",
    "cli-win32-x64",
    "cli-win32-arm64",
    "cli-darwin-x64",
    "cli-darwin-arm64",
    "cli-linux-x64",
    "cli-linux-arm64",
    "cli-linux-x64-musl",
    "cli-linux-arm64-musl",
];

// Set version in the biome root manifest so generate-packages.mjs propagates it.
const rootManifest = readJson(rootManifestPath);
rootManifest.version = version;
writeJson(rootManifestPath, rootManifest);

// Assemble per-platform packages using biome's own script. Expects binaries at
// biomeDir/biome-<code-target>[.exe] -- matching what upload-artifact places.
execSync("node packages/@biomejs/biome/scripts/generate-packages.mjs", {
    cwd: biomeDir,
    stdio: "inherit",
});

// Rewrite every text file in the published dirs: swap @biomejs/ for @<scope>/,
// repoint `repository`, drop provenance (requires npmjs.org), and pin the
// registry via publishConfig.
const repoUrl = `${serverUrl}/${repoSlug}`;
const textExtensions = new Set([".js", ".mjs", ".cjs", ".json", ".ts", ".md"]);

for (const dir of publishDirs) {
    const pkgDir = path.join(pkgRoot, dir);
    rewriteScopeInTree(pkgDir);
    const manifestPath = path.join(pkgDir, "package.json");
    const manifest = readJson(manifestPath);
    manifest.repository = { type: "git", url: `git+${repoUrl}.git` };
    manifest.publishConfig = { registry };
    writeJson(manifestPath, manifest);
    console.info(`Prepared ${manifest.name}@${manifest.version}`);
}

for (const dir of publishDirs) {
    const pkgDir = path.join(pkgRoot, dir);
    if (process.env.DRY_RUN === "1") {
        console.info(`\nDRY_RUN: would publish ${pkgDir}`);
        continue;
    }
    console.info(`\nPublishing from ${pkgDir}`);
    execSync("npm publish", { cwd: pkgDir, stdio: "inherit" });
}

function rewriteScopeInTree(dir) {
    for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
        const full = path.join(dir, entry.name);
        if (entry.isDirectory()) {
            if (entry.name === "node_modules" || entry.name === "scripts") continue;
            rewriteScopeInTree(full);
            continue;
        }
        const ext = path.extname(entry.name).toLowerCase();
        const isTextLike = textExtensions.has(ext) || ext === "";
        if (!isTextLike) continue;
        const buf = fs.readFileSync(full);
        if (!buf.includes(oldScope)) continue;
        const rewritten = buf.toString("utf8").replaceAll(oldScope, newScope);
        fs.writeFileSync(full, rewritten);
        console.info(`  rewrote ${path.relative(biomeDir, full)}`);
    }
}

function readJson(p) {
    return JSON.parse(fs.readFileSync(p, "utf8"));
}

function writeJson(p, obj) {
    fs.writeFileSync(p, JSON.stringify(obj, null, 2) + "\n");
}

function requireEnv(name) {
    const v = process.env[name];
    if (!v) {
        console.error(`error: ${name} env var is required`);
        process.exit(1);
    }
    return v;
}
