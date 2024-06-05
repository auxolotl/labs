{
  lib,
  config,
}: let
  cfg = config.aux.foundation.stages.stage0.hex0;

  system = config.aux.system;
  builders = config.aux.foundation.builders;

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

    src = lib.options.create {
      type = lib.types.string;
      description = "The source for the hex0 build files.";
    };

    m2libc = {
      src = lib.options.create {
        type = lib.types.string;
        description = "The source for the M2libc build files.";
      };

      architecture = lib.options.create {
        type = lib.types.string;
        description = "The architecture to use for the M2libc source.";
        default = {
          value = lib.strings.lower architecture;
          text = ''"amd64" or "aarch64" or "x86"'';
        };
      };
    };

    m2planet = {
      src = lib.options.create {
        type = lib.types.string;
        description = "The source for the M2-Planet build files.";
      };
    };

    m2mesoplanet = {
      src = lib.options.create {
        type = lib.types.string;
        description = "The source for the M2-MesoPlanet build files.";
      };
    };

    mescc-tools = {
      src = lib.options.create {
        type = lib.types.string;
        description = "The source for the mescc-tools build files.";
      };
    };

    mescc-tools-extra = {
      src = lib.options.create {
        type = lib.types.string;
        description = "The source for the mescc-tools-extra build files.";
      };
    };

    architecture = lib.options.create {
      type = lib.types.string;
      description = "The architecture to use for the source.";
      default = {
        value = architecture;
        text = ''"AMD64" or "AArch64" or "x86"'';
      };
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
          "${cfg.src}/hex0_${architecture}.hex0"
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

      # All sources are combined a central repository via submodules. Due to potential quirks surrounding
      # fetching that, we are instead fetching each submodule directly. The central repository is located
      # here: https://github.com/oriansj/stage0-posix
      src =
        if architecture == "AMD64"
        then
          builtins.fetchTarball {
            url = "https://github.com/oriansj/stage0-posix-amd64/archive/93fbe4c08772d8df1412e2554668e24cf604088c.tar.gz";
            sha256 = "10d1xnjzqplpfip3pm89bydd501x1bcgkg7lkkadyq5bqpad5flp";
          }
        else if architecture == "AArch64"
        then
          # FIXME: We may need to patch the aarch64 variant.
          # https://github.com/oriansj/M2libc/pull/17
          builtins.fetchTarball {
            url = "https://github.com/oriansj/stage0-posix-aarch64/archive/39a43f803d572b53f95d42507202152eeda18361.tar.gz";
            sha256 = "1x607hr3n5j89394d156r23igpx8hifjd14ygksx7902rlwrrry2";
          }
        else if architecture == "x86"
        then
          builtins.fetchTarball {
            url = "https://github.com/oriansj/stage0-posix-x86/archive/e86bf7d304bae5ce5ccc88454bb60cf0837e941f.tar.gz";
            sha256 = "1c1fk793yzq8zbg60n2zd22fsmirc3zr26fj0iskap456g84nxv8";
          }
        else builtins.throw "Unsupported architecture for stage0: ${architecture}";

      m2libc = {
        src = builtins.fetchTarball {
          url = "https://github.com/oriansj/M2libc/archive/de7c75f144176c3b9be77695d9bf94440445aeae.tar.gz";
          sha256 = "01k81zn8yx4jg6fbcjgkrf9rp074yikkmwqykdgi9143yfb2k3yv";
        };
      };

      m2planet = {
        src = builtins.fetchTarball {
          url = "https://github.com/oriansj/M2-Planet/archive/51dc63b349ca13fa57b345964254cf26930c0a7d.tar.gz";
          sha256 = "1kksk260dh6qd0dzgl9vgs67fs0lsxs9w0gniy0ii5fgmqxi8p65";
        };
      };

      m2mesoplanet = {
        src = builtins.fetchTarball {
          url = "https://github.com/oriansj/M2-Mesoplanet/archive/c80645f06b035debaa08e95da3206346a9f61b97.tar.gz";
          sha256 = "02vzqln38ylfnd88p87935yf26i60gkbv93ns5j7parqgyyz2kl4";
        };
      };

      mescc-tools = {
        src = builtins.fetchTarball {
          url = "https://github.com/oriansj/mescc-tools/archive/5d37991e22d1e4147411a766f4410508ba872962.tar.gz";
          sha256 = "1xgpqhc5diim3rr9a00939976svrbhfp4v5970548a137fdynl4c";
        };
      };

      mescc-tools-extra = {
        src = builtins.fetchTarball {
          url = "https://github.com/oriansj/mescc-tools-extra/archive/c1bd4ab4c5b994d8167c1e6dfc14050dc151a911.tar.gz";
          sha256 = "0v8vxn3a8rxbgi6vcw73jqkw9j5vg3qlvd4sxk2w0fpybjml8brd";
        };
      };
    };
  };
}
