# wasm-upstream

The upstream WebAssembly builds that LibrePaper runs in the browser, unmodified.
Each comes from its project's own release, pinned by sha256 in `sources.lock`.

| Module | Upstream | Licence |
|---|---|---|
| `pandoc.wasm` | the WebAssembly build attached to each [Pandoc release](https://github.com/jgm/pandoc/releases) | GPL-2.0-or-later (`pandoc-COPYING.md`, `pandoc-COPYRIGHT`) |
| `harper.wasm` | `dist/harper_wasm_slim_bg.wasm` from the [harper.js](https://www.npmjs.com/package/harper.js) npm package | Apache-2.0 (`harper-LICENSE`) |

Only the file names change, so that one release can hold every module. Each
module's source is the upstream release with the same version. LibrePaper
fetches them as separate programs from its asset mirror. The build scripts
here are MIT licensed.

## Build

Run the build in a Nix shell that provides curl and unzip:

```sh
# Downloads and checks the upstream archives, then copies the files into dist/.
nix-shell -p curl unzip --run make
```

## Release

One release carries every module. Bump the version whenever any upstream changes:

```sh
# Needs the gh CLI, logged in with write access to LibrePaper/wasm-upstream.
make release TAG=v1.0.0
```

Then pin it in LibrePaper's `assets.lock` and publish it to the mirror:

```sh
# Run from the librepaper repository.
node tools/assets/pins.mjs update release --repo wasm-upstream --tag v1.0.0
tools/assets/mirror publish
```

Harper's wasm only works with the JavaScript glue of the same harper.js
release, so bump the `harper.js` dependency in LibrePaper's `web/package.json`
at the same time.
