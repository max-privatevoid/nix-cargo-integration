{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    rustOverlay = {
      url = "github:oxalica/rust-overlay";
      flake = false;
    };

    dream2nix = {
      url = "github:nix-community/dream2nix/main";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.gomod2nix.follows = "nixpkgs";
      inputs.mach-nix.follows = "nixpkgs";
      inputs.node2nix.follows = "nixpkgs";
      inputs.poetry2nix.follows = "nixpkgs";
      inputs.alejandra.follows = "nixpkgs";
      inputs.pre-commit-hooks.follows = "nixpkgs";
      inputs.flake-utils-pre-commit.follows = "nixpkgs";
    };
  };

  outputs = inputs:
    with inputs; let
      preCommitHooks = builtins.fetchGit {
        url = "https://github.com/cachix/pre-commit-hooks.nix.git";
        ref = "master";
        rev = "b6bc0b21e1617e2b07d8205e7fae7224036dfa4b";
      };

      sources = {inherit rustOverlay devshell nixpkgs dream2nix preCommitHooks;};
      lib = import ./src/lib.nix {
        lib = import "${nixpkgs}/lib";
      };
      l = lib;

      makeOutputs = import ./src/makeOutputs.nix {inherit sources lib;};

      cliOutputs = makeOutputs {
        root = ./cli;
        overrides = {
          crateOverrides = common: _: {
            nci-cli = prev: {
              NCI_SRC = builtins.toString inputs.self;
              # Make sure the src doesnt get garbage collected
              postInstall = "ln -s $NCI_SRC $out/nci_src";
            };
          };
        };
      };

      mkTests = builder: let
        testNames = l.remove null (l.mapAttrsToList (name: type:
          if type == "directory"
          then
            if name != "broken"
            then name
            else null
          else null) (builtins.readDir ./tests));
        tests = l.genAttrs testNames (test:
          makeOutputs {
            inherit builder;
            root = ./tests + "/${test}";
          });
        flattenAttrs = attrs:
          l.mapAttrsToList (n: v:
            l.mapAttrs (_:
              l.mapAttrs' (n:
                l.nameValuePair (n
                  + (
                    if l.hasInfix "workspace" n
                    then "-${n}"
                    else ""
                  ))))
            v.${attrs})
          tests;
        checks = builtins.map (l.mapAttrs (n: attrs: builtins.removeAttrs attrs [])) (flattenAttrs "checks");
        packages = builtins.map (l.mapAttrs (n: attrs: builtins.removeAttrs attrs [])) (flattenAttrs "packages");
        shells = l.mapAttrsToList (name: test: l.mapAttrs (_: drv: {"${name}-shell" = drv;}) test.devShell) tests;
      in {
        checks = l.foldAttrs l.recursiveUpdate {} checks;
        packages = l.foldAttrs l.recursiveUpdate {} packages;
        shells = l.foldAttrs l.recursiveUpdate {} shells;
      };

      craneTests = mkTests "crane";
      brpTests = mkTests "buildRustPackage";
    in {
      lib = {
        inherit makeOutputs;
      };
      inherit craneTests brpTests;
      inherit (cliOutputs) apps packages defaultApp defaultPackage devShell;
    };
}
