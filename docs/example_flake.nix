{
  inputs = {
    nixCargoIntegration.url = "github:yusdacra/nix-cargo-integration";
  };

  outputs = inputs: inputs.nixCargoIntegration.lib.makeOutputs {
    root = ./.;
    # `cargoVendorHash` is only used for buildRustPackage platform.
    # cargoVendorHash = "";
    # Which package outputs to rename to what.
    # This renames both their package names and the generated output names.
    # Applies to generated apps too.
    renameOutputs = { };
    # Default outputs to set.
    defaultOutputs = {
      # Set the `defaultPackage` output to the "example` package from `packages`.
      # package = "example";
      # Set the `defaultApp` output to the "example` app from `apps`.
      # app = "example";
    };
    # Overrides provided here will apply to *every crate*,
    # for *every system*. To selectively override per crate,
    # one can use `common.cargoPkg.name` attribute. To selectively
    # override per system one can use `common.system` attribute.
    overrides =
      let
        lib = inputs.nixpkgs.lib;
      in
      {
        # Mutate the systems to generate outputs for here.
        systems = def: def;
        # Override sources used by nixCargoIntegration in common.
        # This can be used to provide sources that are only needed for
        # specific systems or crates.
        sources = common: prev: {
          # rustOverlay = inputs.rustOverlay;
        };
        # Override nixpkgs configuration in common. This can be used 
        # to add overlays for specific systems or crates.
        pkgs = common: prev: {
          # overlays = prev.overlays ++ [ inputs.someInput.someOverlay ];
        };
        # Override for the root that will be used.
        # Note that it may cause inconsistency if the changed root includes different
        # dependencies in it's Cargo.lock.
        root = common: prev: prev;
        # Override crate overrides.
        crateOverrides = common: prevv: {
          # test = prev: {
          #   buildInputs = (prev.buildInputs or []) ++ [ common.pkgs.hello ];
          #   TEST_ENV = "test";
          # }
        };
        # Common attribute overrides.
        common = prev: {
          # Package set used can be overriden here; note that changing
          # the package set here will not change the already set
          # runtimeLibs, buildInputs and nativeBuildInputs.
          pkgs = prev.pkgs;
          # Packages put here will have their libraries exported in
          # $LD_LIBRARY_PATH environment variable.
          runtimeLibs = prev.runtimeLibs ++ [ ];
          # Packages put here will be used as build inputs for build
          # derivation and packages for development shell. For development
          # shell, they will be exported to $LIBRARY_PATH and $PKG_CONFIG_PATH.
          buildInputs = prev.buildInputs ++ [ ];
          # Packages put here will be used as native build inputs
          # for build derivation and packages for development shell.
          nativeBuildInputs = prev.nativeBuildInputs ++ [ ];
          # Key-value pairs put here will be exported as environment
          # variables in build and development shell.
          env = prev.env // {
            # PROTOC_INCLUDE = "${prev.pkgs.protobuf}/include";
          };
        };
        # Development shell overrides.
        shell = common: prev: {
          # Packages to be put in $PATH.
          packages = prev.packages ++ [ ];
          # Commands that will be shown in the `menu`. These also get added
          # to packages.
          commands = prev.commands ++ [
            # { package = common.pkgs.git; }
            # { name = "helloworld"; command = "echo 'Hello world'"; }
          ];
          # Environment variables to be exported.
          env = prev.env ++ [
            # lib.nameValuePair "PROTOC" "protoc"
            # { name = "HOME_DIR"; eval = "$HOME"; }
          ];
        };
      };
  };
}
