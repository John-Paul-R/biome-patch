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
