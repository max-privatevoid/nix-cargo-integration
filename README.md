# nix-cargo-integration

Utility to integrate Cargo projects with Nix.

- Uses [naersk] to build Cargo packages and [devshell] to provide development shell.
- Allows configuration from `Cargo.toml` via `package.metadata.nix` attribute.

## Usage

### With flakes

Add:
```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixCargoIntegration = {
      url = "github:yusdacra/nix-cargo-integration";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = inputs: inputs.nixCargoIntegration.lib.makeOutputs { root = ./.; };
}
```
to your `flake.nix`.

### Without flakes

You can use [flake-compat] to provide the default outputs of the flake for non-flake users.

If you aren't using flakes, you can do:
```nix
let
  nixCargoIntegrationSrc = builtins.fetchGit { url = "https://github.com/yusdacra/nix-cargo-integration.git"; rev = <something>; sha256 = <something>; };
  nixCargoIntegration = import "${nixCargoIntegrationSrc}/lib.nix" {
      sources = { inherit flakeUtils rustOverlay devshell naersk nixpkgs; };
  };
  outputs = nixCargoIntegration.makeOutputs { root = ./.; };
in
```

## Library documentation

### `makeOutputs = { root, overrides ? { }}: { ... }`

Runs `makeOutput` for all systems specified in `Cargo.toml` (defaults to `defaultSystems` of `nixpkgs`).

#### Arguments

- `root`: directory where `Cargo.toml` is in (type: path)
- `overrides`: overrides for devshell, build and common (type: attrset)
    - `overrides.build`: override for build (type: `common: prev: { }`)
        - this will override the [naersk] build derivation, refer to it for more information
    - `overrides.shell`: override for devshell (type: `common: prev: { }`)
        - this will override the [devshell] configuration, refer to it for more information
    - `overrides.common`: override for common (type: `prev: { }`)
        - this overrides the common attribute set, refer to [common.nix](./common.nix) for more information

### `makeOutput = { root, cargoPkg, system, overrides ? { }}: { ... }`

Makes `packages`, `apps`, `checks` and `devShell` output for one system.

#### Arguments

- `root`: see `makeOutputs`' `root` argument
- `overrides`: see `makeOutputs`' `overrides` argument
- `cargoPkg`: `package` attribute set of the `Cargo.toml` that reside in `root`. (type: attrset)
- `system`: machine system to build for (type: string)

### `importCargoTOML = root: { ... }`

Imports a `Cargo.toml` file from the specified root as an attribute set.

#### Arguments

- `root`: see `makeOutput`'s `root` argument

## `package.metadata.nix` attributes

- `systems`: systems to enable for the flake (type: list)
    - defaults to `defaultSystems` of `nixpkgs`
- `executable`: executable name of the build binary (type: string)
- `build`: whether to enable outputs which build the package (type: boolean)
    - defaults to `false` if not specified
- `library`: whether to copy built library to package output (type: boolean)
    - defaults to `false` if not specified
- `app`: whether to enable the application output (type: boolean)
    - defaults to `false` if not specified
- `toolchain`: rust toolchain to use (type: one of "stable", "beta" or "nightly")
    - if not specified, `rust-toolchain` file will be used
- `longDescription`: a longer description (type: string)
- `runtimeLibs`: libraries that will be put in `LD_LIBRARY_PRELOAD` for both dev and build env (type: list)
- `buildInputs`: common build inputs (type: list)
- `nativeBuildInputs`: common native build inputs (type: list)

### `package.metadata.nix.env` attributes

Key-value pairings that are put here will be exported into the development and build environment.
For example:
```toml
[package.metadata.nix.env]
PROTOC = "protoc"
```

### `package.metadata.nix.cachix` attributes

- `name`: name of the cachix cache (type: string)
- `key`: public key of the cachix cache (type: string)

### `package.metadata.nix.xdg` attributes

- `enable`: whether to enable desktop file generation (type: boolean)
- `icon`: icon string according to XDG (type: string)
    - strings starting with "./" will be treated as relative to project directory
    - everything else will be put into the desktop file as-is
- `comment`: comment for the desktop file (type: string)
    - defaults to `package.description` if not specified
- `name`: desktop name for the desktop file (type: string)
    - defaults to `package.name` if not specified
- `genericName`: generic name for the desktop file (type: string)
- `categories`: categories for the desktop file according to XDG specification (type: string)

### `package.metadata.nix.devshell` attributes

Refer to [devshell] documentation.

NOTE: Attributes specified here **will not** be used if a top-level `devshell.toml` file exists.

[devshell]: https://github.com/numtide/devshell "devshell"
[naersk]: https://github.com/nmattia/naersk "naersk"
[flake-compat]: https://github.com/edolstra/flake-compat "flake-compat"