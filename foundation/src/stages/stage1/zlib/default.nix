{
  lib,
  config,
}: let
  cfg = config.aux.foundation.stages.stage1.zlib;

  platform = config.aux.platform;
  builders = config.aux.foundation.builders;

  stage1 = config.aux.foundation.stages.stage1;
in {
  options.aux.foundation.stages.stage1.zlib = {
    meta = {
      description = lib.options.create {
        type = lib.types.string;
        description = "Description for the package.";
        default.value = "Lossless data-compression library.";
      };

      homepage = lib.options.create {
        type = lib.types.string;
        description = "Homepage for the package.";
        default.value = "https://zlib.net";
      };

      license = lib.options.create {
        # TODO: Add a proper type for licenses.
        type = lib.types.attrs.any;
        description = "License for the package.";
        default.value = lib.licenses.zlib;
      };

      platforms = lib.options.create {
        type = lib.types.list.of lib.types.string;
        description = "Platforms the package supports.";
        default.value = ["i686-linux"];
      };
    };

    package = lib.options.create {
      type = lib.types.package;
      description = "The package to use for zlib.";
    };

    version = lib.options.create {
      type = lib.types.string;
      description = "Version of the package.";
    };

    src = lib.options.create {
      type = lib.types.package;
      description = "Source for the package.";
    };
  };

  config = {
    aux.foundation.stages.stage1.zlib = {
      version = "1.3";

      src = builtins.fetchurl {
        url = "https://github.com/madler/zlib/releases/download/v${cfg.version}/zlib-${cfg.version}.tar.xz";
        sha256 = "ipuiiY4dDXdOymultGJ6EeVYi6hciFEzbrON5GgwUKc=";
      };

      package = builders.bash.build {
        name = "zlib-${cfg.version}";
        meta = cfg.meta;

        deps.build.host = [
          stage1.gcc.package
          stage1.musl.package
          stage1.binutils.package
          stage1.gnumake.package
          stage1.gnused.package
          stage1.gnugrep.package
          stage1.gnutar.package
          stage1.xz.package
        ];

        script = ''
          # Unpack
          tar xf ${cfg.src}
          cd zlib-${cfg.version}

          # Configure
          export CC=musl-gcc
          bash ./configure --prefix=$out

          # Build
          make -j $NIX_BUILD_CORES

          # Install
          make -j $NIX_BUILD_CORES install
        '';
      };
    };
  };
}
