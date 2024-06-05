{
  lib,
  config,
}: let
  system = config.aux.system;

  architecture = config.aux.foundation.stages.stage0.architecture.base;
in {
  options.aux.foundation.stages.stage0.sources = {
    base = lib.options.create {
      type = lib.types.string;
      description = "The source for the hex0 build files.";
    };

    m2libc = lib.options.create {
      type = lib.types.string;
      description = "The source for the M2libc build files.";
    };

    m2planet = lib.options.create {
      type = lib.types.string;
      description = "The source for the M2-Planet build files.";
    };

    m2mesoplanet = lib.options.create {
      type = lib.types.string;
      description = "The source for the M2-Mesoplanet build files.";
    };

    mescc-tools = lib.options.create {
      type = lib.types.string;
      description = "The source for the mescc-tools build files.";
    };

    mescc-tools-extra = lib.options.create {
      type = lib.types.string;
      description = "The source for the mescc-tools-extra build files.";
    };
  };

  config = {
    aux.foundation.stages.stage0.sources = {
      # All sources are combined a central repository via submodules. Due to potential quirks surrounding
      # fetching that, we are instead fetching each submodule directly. The central repository is located
      # here: https://github.com/oriansj/stage0-posix
      base =
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

      m2libc = builtins.fetchTarball {
        url = "https://github.com/oriansj/M2libc/archive/de7c75f144176c3b9be77695d9bf94440445aeae.tar.gz";
        sha256 = "01k81zn8yx4jg6fbcjgkrf9rp074yikkmwqykdgi9143yfb2k3yv";
      };

      m2planet = builtins.fetchTarball {
        url = "https://github.com/oriansj/M2-Planet/archive/51dc63b349ca13fa57b345964254cf26930c0a7d.tar.gz";
        sha256 = "1kksk260dh6qd0dzgl9vgs67fs0lsxs9w0gniy0ii5fgmqxi8p65";
      };

      m2mesoplanet = builtins.fetchTarball {
        url = "https://github.com/oriansj/M2-Mesoplanet/archive/c80645f06b035debaa08e95da3206346a9f61b97.tar.gz";
        sha256 = "02vzqln38ylfnd88p87935yf26i60gkbv93ns5j7parqgyyz2kl4";
      };

      mescc-tools = builtins.fetchTarball {
        url = "https://github.com/oriansj/mescc-tools/archive/5d37991e22d1e4147411a766f4410508ba872962.tar.gz";
        sha256 = "1xgpqhc5diim3rr9a00939976svrbhfp4v5970548a137fdynl4c";
      };

      mescc-tools-extra = builtins.fetchTarball {
        url = "https://github.com/oriansj/mescc-tools-extra/archive/c1bd4ab4c5b994d8167c1e6dfc14050dc151a911.tar.gz";
        sha256 = "0v8vxn3a8rxbgi6vcw73jqkw9j5vg3qlvd4sxk2w0fpybjml8brd";
      };
    };
  };
}
