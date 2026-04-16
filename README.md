# biome-patch

a simple wrapper repository for patching the biome js/ts formatter with some simple extra features.

## Features

- feat: add config option objectDestructuringLineBreaks
  - Original Discussion: https://github.com/biomejs/biome/discussions/2026

## Usage

Build a patched biome source tree locally:

```sh
./build.sh
```

This shallow-fetches the biome commit pinned in `BIOME_REF` into `./biome` and applies every patch in `patches/`.

Bump the pin to the latest upstream `main`:

```sh
./update.sh
```

`update.sh` resolves the latest commit on `biomejs/biome` `main`, dry-runs every patch against it, and only updates `BIOME_REF` if they all apply. If any patch fails, it reports which one and leaves the pin unchanged -- rebase the failing patch, then re-run.

### Publishing to GitHub Packages

The `Publish biome to GitHub Packages` workflow (`.github/workflows/publish.yml`) is manually dispatched. It cross-compiles the patched biome CLI for 8 targets (linux / darwin / win32 x64+arm64, plus linux musl variants), then publishes 9 scoped npm packages to `npm.pkg.github.com`:

- `@<owner>/biome` -- the root package users install
- `@<owner>/cli-<platform>-<arch>[-musl]` -- one native binary per platform, pulled in automatically via `optionalDependencies`

Version is `<upstream-biome-version>-patch.<short-sha>`, scope is the repo owner lowercased.

Consumers install it by adding a scoped `.npmrc` entry pointing at GitHub Packages and an auth token with `read:packages`:

```
@<owner>:registry=https://npm.pkg.github.com
//npm.pkg.github.com/:_authToken=${GITHUB_TOKEN}
```

then `npm install @<owner>/biome`.

> Note: the linux-arm64 matrix jobs use GitHub-hosted ARM runners (`ubuntu-24.04-arm`). These are free for public repos; private repos may have tighter minute limits.
