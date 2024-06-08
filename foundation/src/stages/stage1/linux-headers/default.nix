{
  lib,
  config,
}: let
  cfg = config.aux.foundation.stages.stage1.linux-headers;

  platform = config.aux.platform;
  builders = config.aux.foundation.builders;

  stage1 = config.aux.foundation.stages.stage1;
in {
  options.aux.foundation.stages.stage1.linux-headers = {
    meta = {
      description = lib.options.create {
        type = lib.types.string;
        description = "Description for the package.";
        default.value = "Header files and scripts for Linux kernel.";
      };

      license = lib.options.create {
        # TODO: Add a proper type for licenses.
        type = lib.types.attrs.any;
        description = "License for the package.";
        default.value = lib.licenses.lgpl2Plus;
      };

      platforms = lib.options.create {
        type = lib.types.list.of lib.types.string;
        description = "Platforms the package supports.";
        default.value = ["i686-linux"];
      };
    };

    package = lib.options.create {
      type = lib.types.package;
      description = "The package to use for linux-headers.";
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
    aux.foundation.stages.stage1.linux-headers = {
      version = "6.5.6";

      src = builtins.fetchurl {
        url = "https://cdn.kernel.org/pub/linux/kernel/v${lib.versions.major cfg.version}.x/linux-${cfg.version}.tar.xz";
        sha256 = "eONtQhRUcFHCTfIUD0zglCjWxRWtmnGziyjoCUqV0vY=";
      };

      package = builders.bash.build {
        name = "linux-headers-${cfg.version}";
        meta = cfg.meta;

        deps.build.host = [
          stage1.gcc.package
          stage1.musl.package
          stage1.binutils.package
          stage1.gnumake.package
          stage1.gnused.package
          stage1.gnugrep.package
          stage1.gawk.package
          stage1.diffutils.package
          stage1.findutils.package
          stage1.gnutar.package
          stage1.xz.package
        ];

        script = ''
          # Unpack
          tar xf ${cfg.src}
          cd linux-${cfg.version}

          # Build
          make -j $NIX_BUILD_CORES CC=musl-gcc HOSTCC=musl-gcc ARCH=x86 headers

          # Install
          find usr/include -name '.*' -exec rm {} +
          mkdir -p $out
          cp -rv usr/include $out/
        '';
      };
    };
  };
}
