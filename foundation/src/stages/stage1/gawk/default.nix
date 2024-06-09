{
  lib,
  config,
}: let
  cfg = config.aux.foundation.stages.stage1.gawk;

  platform = config.aux.platform;
  builders = config.aux.foundation.builders;

  stage1 = config.aux.foundation.stages.stage1;
in {
  includes = [
    ./boot.nix
  ];

  options.aux.foundation.stages.stage1.gawk = {
    meta = {
      description = lib.options.create {
        type = lib.types.string;
        description = "Description for the package.";
        default.value = "GNU implementation of the Awk programming language";
      };

      homepage = lib.options.create {
        type = lib.types.string;
        description = "Homepage for the package.";
        default.value = "https://www.gnu.org/software/gawk";
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
        default.value = ["i686-linux"];
      };

      mainProgram = lib.options.create {
        type = lib.types.string;
        description = "The main program of the package.";
        default.value = "awk";
      };
    };

    package = lib.options.create {
      type = lib.types.derivation;
      description = "The package to use for gawk.";
    };

    version = lib.options.create {
      type = lib.types.string;
      description = "Version of the package.";
    };

    src = lib.options.create {
      type = lib.types.derivation;
      description = "Source for the package.";
    };
  };

  config = {
    aux.foundation.stages.stage1.gawk = {
      version = "5.2.2";

      src = builtins.fetchurl {
        url = "https://ftpmirror.gnu.org/gawk/gawk-${cfg.version}.tar.gz";
        sha256 = "lFrvfM/xAfILIqEIArwAXplKsrjqPnJMwaGXxi9B9lA=";
      };

      package = builders.bash.boot.build {
        name = "gawk-${cfg.version}";

        meta = cfg.meta;

        deps.build.host = [
          stage1.tinycc.musl.compiler.package
          stage1.gnumake.package
          stage1.gnused.package
          stage1.gnugrep.package
          stage1.gnutar.musl.package
          stage1.gzip.package
          stage1.gawk.boot.package
        ];

        script = ''
          # Unpack
          tar xzf ${cfg.src}
          cd gawk-${cfg.version}

          # Configure
          export CC="tcc -B ${stage1.tinycc.musl.libs.package}/lib"
          export AR="tcc -ar"
          export LD=tcc
          bash ./configure \
            --prefix=$out \
            --build=${platform.build} \
            --host=${platform.host}

          # Build
          make -j $NIX_BUILD_CORES

          # Install
          make -j $NIX_BUILD_CORES install
        '';
      };
    };
  };
}
