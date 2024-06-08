{
  lib,
  config,
}: let
  cfg = config.aux.foundation.stages.stage2.glibc;

  platform = config.aux.platform;
  builders = config.aux.foundation.builders;

  stage1 = config.aux.foundation.stages.stage1;
  stage2 = config.aux.foundation.stages.stage2;
in {
  options.aux.foundation.stages.stage2.glibc = {
    meta = {
      description = lib.options.create {
        type = lib.types.string;
        description = "Description for the package.";
        default.value = "The GNU C Library.";
      };

      homepage = lib.options.create {
        type = lib.types.string;
        description = "Homepage for the package.";
        default.value = "https://www.gnu.org/software/libc";
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
      description = "The package to use for glibc.";
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
    aux.foundation.stages.stage2.glibc = {
      version = "2.38";

      src = builtins.fetchurl {
        url = "https://ftpmirror.gnu.org/libc/glibc-${cfg.version}.tar.xz";
        sha256 = "+4KZiZiyspllRnvBtp0VLpwwfSzzAcnq+0VVt3DvP9I=";
      };

      package = builders.bash.build {
        name = "glibc-${cfg.version}";
        meta = cfg.meta;

        deps.build.host = [
          stage1.gcc.package
          stage1.binutils.package
          stage1.gnumake.package
          stage1.gnused.package
          stage2.gnugrep.package
          stage2.gawk.package
          stage1.diffutils.package
          stage1.findutils.package
          stage1.python.package
          stage1.bison.package
          stage1.gnutar.package
          stage1.xz.package
        ];

        script = ''
          # Unpack
          tar xf ${cfg.src}
          cd glibc-${cfg.version}

          # Configure
          mkdir build
          cd build
          # libstdc++.so is built against musl and fails to link
          export CXX=false
          bash ../configure \
            --prefix=$out \
            --build=${platform.build} \
            --host=${platform.host} \
            --with-headers=${stage1.linux-headers.package}/include

          # Build
          make -j $NIX_BUILD_CORES

          # Install
          make -j $NIX_BUILD_CORES INSTALL_UNCOMPRESSED=yes install
          find $out/{bin,sbin,lib,libexec} -type f -exec strip --strip-unneeded {} + || true
        '';
      };
    };
  };
}
