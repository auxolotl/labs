{
  lib,
  config,
}: let
  cfg = config.aux.foundation.stages.stage1.bzip2;

  platform = config.aux.platform;
  builders = config.aux.foundation.builders;

  stage1 = config.aux.foundation.stages.stage1;
in {
  options.aux.foundation.stages.stage1.bzip2 = {
    package = lib.options.create {
      type = lib.types.package;
      description = "The package to use for bzip2.";
    };

    version = lib.options.create {
      type = lib.types.string;
      description = "Version of the package.";
    };

    src = lib.options.create {
      type = lib.types.package;
      description = "Source for the package.";
    };

    meta = {
      description = lib.options.create {
        type = lib.types.string;
        description = "Description for the package.";
        default.value = "High-quality data compression program";
      };

      homepage = lib.options.create {
        type = lib.types.string;
        description = "Homepage for the package.";
        default.value = "https://www.sourceware.org/bzip2";
      };

      license = lib.options.create {
        # TODO: Add a proper type for licenses.
        type = lib.types.attrs.any;
        description = "License for the package.";
        default.value = lib.licenses.bsdOriginal;
      };

      platforms = lib.options.create {
        type = lib.types.list.of lib.types.string;
        description = "Platforms the package supports.";
        # TODO: Support more platforms.
        default.value = ["i686-linux"];
      };
    };
  };

  config = {
    aux.foundation.stages.stage1.bzip2 = {
      version = "1.0.8";

      src = builtins.fetchurl {
        url = "https://sourceware.org/pub/bzip2/bzip2-${cfg.version}.tar.gz";
        sha256 = "0s92986cv0p692icqlw1j42y9nld8zd83qwhzbqd61p1dqbh6nmb";
      };

      package = builders.bash.build {
        name = "bzip2-${cfg.version}";

        meta = cfg.meta;

        deps.build.host = [
          stage1.tinycc.musl.compiler.package
          stage1.gnumake.package
          stage1.gnutar.musl.package
          stage1.gzip.package
        ];

        script = ''
          # Unpack
          tar xzf ${cfg.src}
          cd bzip2-${cfg.version}

          # Build
          make \
            -j $NIX_BUILD_CORES \
            CC="tcc -B ${stage1.tinycc.musl.libs.package}/lib" \
            AR="tcc -ar" \
            bzip2 bzip2recover

          # Install
          make install -j $NIX_BUILD_CORES PREFIX=$out

        '';
      };
    };
  };
}
