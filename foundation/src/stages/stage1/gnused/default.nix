{
  lib,
  config,
}: let
  cfg = config.aux.foundation.stages.stage1.gnused;

  platform = config.aux.platform;
  builders = config.aux.foundation.builders;

  stage1 = config.aux.foundation.stages.stage1;
in {
  includes = [
    ./boot.nix
  ];

  options.aux.foundation.stages.stage1.gnused = {
    package = lib.options.create {
      type = lib.types.package;
      description = "The package to use for gnumake.";
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
        default.value = "GNU sed, a batch stream editor.";
      };

      homepage = lib.options.create {
        type = lib.types.string;
        description = "Homepage for the package.";
        default.value = "https://www.gnu.org/software/sed";
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

      mainProgram = lib.options.create {
        type = lib.types.string;
        description = "The main program of the package.";
        default.value = "sed";
      };
    };
  };

  config = {
    aux.foundation.stages.stage1.gnused = {
      version = "4.2";

      src = builtins.fetchurl {
        url = "https://ftpmirror.gnu.org/sed/sed-${cfg.version}.tar.gz";
        sha256 = "20XNY/0BDmUFN9ZdXfznaJplJ0UjZgbl5ceCk3Jn2YM=";
      };

      package = builders.bash.boot.build {
        name = "gnused-${cfg.version}";

        meta = cfg.meta;

        deps.build.host = [
          stage1.tinycc.musl.compiler.package
          stage1.gnumake.boot.package
          stage1.gnused.boot.package
          stage1.gnugrep.package
          stage1.gnutar.boot.package
          stage1.gzip.package
        ];

        script = ''
          # Unpack
          tar xzf ${cfg.src}
          cd sed-${cfg.version}

          # Configure
          export CC="tcc -B ${stage1.tinycc.musl.libs.package}/lib"
          export LD=tcc
          ./configure \
            --build=${platform.build} \
            --host=${platform.host} \
            --disable-shared \
            --disable-nls \
            --disable-dependency-tracking \
            --prefix=$out

          # Build
          make AR="tcc -ar"

          # Install
          make install
        '';
      };
    };
  };
}
