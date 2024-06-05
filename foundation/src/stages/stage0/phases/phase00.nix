{
  lib,
  config,
}: let
  cfg = config.aux.foundation.stages.stage0.hex0;

  system = config.aux.system;
  builders = config.aux.foundation.builders;
  sources = config.aux.foundation.stages.stage0.sources;

  architecture =
    if system == "x86_64-linux"
    then "AMD64"
    else if system == "aarch64-linux"
    then "AArch64"
    else if system == "i686-linux"
    then "x86"
    else builtins.throw "Unsupported system for stage0: ${system}";
in {
  options.aux.foundation.stages.stage0.hex0 = {
    package = lib.options.create {
      type = lib.types.package;
      description = "The package to use for hex0.";
    };

    meta = {
      description = lib.options.create {
        type = lib.types.string;
        description = "Description for the package.";
        default.value = "Minimal assembler for bootstrapping.";
      };

      homepage = lib.options.create {
        type = lib.types.string;
        description = "Homepage for the package.";
        default.value = "https://github.com/oriansj/stage0-posix";
      };

      license = lib.options.create {
        # TODO: Add a proper type for licenses.
        type = lib.types.attrs.any;
        description = "License for the package.";
        default.value = lib.licenses.gpl3Plus;
      };

      platforms = lib.options.create {
        type = lib.types.list.of lib.types.string;
        description = "Platforms the package supports.";
        default.value = ["x86_64-linux" "aarch64-linux" "i686-linux"];
      };
    };

    hash = lib.options.create {
      type = lib.types.nullish lib.types.string;
      default = {
        text = "<sha256 hash>";
        value = null;
      };
    };

    executable = lib.options.create {
      type = lib.types.package;
      description = "The derivation to use to build hex0.";
    };
  };

  config = {
    aux.foundation.stages.stage0.hex0 = {
      package = lib.modules.overrides.default (builders.raw.build {
        pname = "hex0";
        version = "1.6.0";

        meta = cfg.meta;

        executable = cfg.executable;

        args = [
          "${sources.base}/hex0_${architecture}.hex0"
          (builtins.placeholder "out")
        ];

        outputHashMode = "recursive";
        outputHashAlgo = "sha256";
        outputHash = cfg.hash;
      });

      hash = lib.modules.overrides.default (
        if system == "x86_64-linux"
        then "sha256-XTPsoKeI6wTZAF0UwEJPzuHelWOJe//wXg4HYO0dEJo="
        else if system == "aarch64-linux"
        then "sha256-RCgK9oZRDQUiWLVkcIBSR2HeoB+Bh0czthrpjFEkCaY="
        else if system == "i686-linux"
        then "sha256-QU3RPGy51W7M2xnfFY1IqruKzusrSLU+L190ztN6JW8="
        else null
      );

      executable = lib.modules.overrides.default (import <nix/fetchurl.nix> {
        name = "hex0-seed";
        url = "https://github.com/oriansj/bootstrap-seeds/raw/b1263ff14a17835f4d12539226208c426ced4fba/POSIX/${architecture}/hex0-seed";
        executable = true;
        hash = cfg.hash;
      });
    };
  };
}
