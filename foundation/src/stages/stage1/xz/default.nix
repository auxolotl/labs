{
  lib,
  config,
}: let
  cfg = config.aux.foundation.stages.stage1.xz;

  platform = config.aux.platform;
  builders = config.aux.foundation.builders;

  stage1 = config.aux.foundation.stages.stage1;
in {
  options.aux.foundation.stages.stage1.xz = {
    package = lib.options.create {
      type = lib.types.package;
      description = "The package to use for xz.";
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
        default.value = "A general-purpose data compression software, successor of LZMA";
      };

      homepage = lib.options.create {
        type = lib.types.string;
        description = "Homepage for the package.";
        default.value = "https://tukaani.org/xz";
      };

      license = lib.options.create {
        # TODO: Add a proper type for licenses.
        type = lib.types.list.of lib.types.attrs.any;
        description = "License for the package.";
        default.value = [
          lib.licenses.gpl2Plus
          lib.licenses.lgpl21Plus
        ];
      };

      platforms = lib.options.create {
        type = lib.types.list.of lib.types.string;
        description = "Platforms the package supports.";
        default.value = ["i686-linux"];
      };
    };
  };

  config = {
    aux.foundation.stages.stage1.xz = {
      version = "5.4.3";

      src = builtins.fetchurl {
        url = "https://tukaani.org/xz/xz-${cfg.version}.tar.gz";
        sha256 = "HDguC8Lk4K9YOYqQPdYv/35RAXHS3keh6+BtFSjpt+k=";
      };

      package = builders.bash.boot.build {
        name = "xz-${cfg.version}";

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
          cd xz-${cfg.version}

          # Configure
          export CC="tcc -B ${stage1.tinycc.musl.libs.package}/lib"
          export AR="tcc -ar"
          export LD=tcc
          bash ./configure \
            --prefix=$out \
            --build=${platform.build} \
            --host=${platform.host} \
            --disable-shared \
            --disable-assembler

          # Build
          make -j $NIX_BUILD_CORES

          # Install
          make -j $NIX_BUILD_CORES install

        '';
      };
    };
  };
}
