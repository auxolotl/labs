{
  lib,
  config,
}: let
  cfg = config.aux.foundation.stages.stage2.busybox;

  platform = config.aux.platform;
  builders = config.aux.foundation.builders;

  stage1 = config.aux.foundation.stages.stage1;
  stage2 = config.aux.foundation.stages.stage2;
in {
  options.aux.foundation.stages.stage2.busybox = {
    meta = {
      description = lib.options.create {
        type = lib.types.string;
        description = "Description for the package.";
        default.value = "Tiny versions of common UNIX utilities in a single small executable.";
      };

      homepage = lib.options.create {
        type = lib.types.string;
        description = "Homepage for the package.";
        default.value = "https://busybox.net/";
      };

      license = lib.options.create {
        # TODO: Add a proper type for licenses.
        type = lib.types.attrs.any;
        description = "License for the package.";
        default.value = lib.licenses.gpl2Only;
      };

      platforms = lib.options.create {
        type = lib.types.list.of lib.types.string;
        description = "Platforms the package supports.";
        default.value = ["i686-linux"];
      };
    };

    package = lib.options.create {
      type = lib.types.package;
      description = "The package to use for busybox.";
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
    aux.foundation.stages.stage2.busybox = {
      version = "1.36.1";

      src = builtins.fetchurl {
        url = "https://busybox.net/downloads/busybox-${cfg.version}.tar.bz2";
        sha256 = "uMwkyVdNgJ5yecO+NJeVxdXOtv3xnKcJ+AzeUOR94xQ=";
      };

      package = let
        patches = [
          ./patches/busybox-in-store.patch
        ];

        busyboxConfig = [
          "CC=musl-gcc"
          "HOSTCC=musl-gcc"
          "CFLAGS=-I${stage1.linux-headers.package}/include"
          "KCONFIG_NOTIMESTAMP=y"
          "CONFIG_PREFIX=${builtins.placeholder "out"}"
          "CONFIG_STATIC=y"
        ];
      in
        builders.bash.build {
          name = "busybox-static-${cfg.version}";
          meta = cfg.meta;

          deps.build.host = [
            stage1.gcc.package
            stage1.musl.package
            stage1.binutils.package
            stage1.gnumake.package
            stage1.gnupatch.package
            stage1.gnused.package
            stage2.gnugrep.package
            stage2.gawk.package
            stage1.diffutils.package
            stage1.findutils.package
            stage1.gnutar.package
            stage1.bzip2.package
          ];

          script = ''
            # Unpack
            tar xf ${cfg.src}
            cd busybox-${cfg.version}

            # Patch
            ${lib.strings.concatMapSep "\n" (file: "patch -Np1 -i ${file}") patches}

            # Configure
            BUSYBOX_FLAGS="${builtins.concatStringsSep " " busyboxConfig}"
            make -j $NIX_BUILD_CORES $BUSYBOX_FLAGS defconfig

            # Build
            make -j $NIX_BUILD_CORES $BUSYBOX_FLAGS

            # Install
            cp busybox $out

          '';
        };
    };
  };
}
