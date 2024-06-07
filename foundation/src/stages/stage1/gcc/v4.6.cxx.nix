{
  lib,
  config,
}: let
  cfg = config.aux.foundation.stages.stage1.gcc.v46.cxx;

  platform = config.aux.platform;
  builders = config.aux.foundation.builders;

  stage1 = config.aux.foundation.stages.stage1;
in {
  options.aux.foundation.stages.stage1.gcc.v46.cxx = {
    package = lib.options.create {
      type = lib.types.package;
      description = "The package to use for gcc-cxx.";
    };

    version = lib.options.create {
      type = lib.types.string;
      description = "Version of the package.";
    };

    src = lib.options.create {
      type = lib.types.package;
      description = "Source for the package.";
    };

    cc = {
      src = lib.options.create {
        type = lib.types.package;
        description = "The cc source for the package.";
      };
    };

    gmp = {
      src = lib.options.create {
        type = lib.types.package;
        description = "The gmp source for the package.";
      };

      version = lib.options.create {
        type = lib.types.string;
        description = "Version of gmp.";
      };
    };

    mpfr = {
      src = lib.options.create {
        type = lib.types.package;
        description = "The mpfr source for the package.";
      };

      version = lib.options.create {
        type = lib.types.string;
        description = "Version of mpfr.";
      };
    };

    mpc = {
      src = lib.options.create {
        type = lib.types.package;
        description = "The mpc source for the package.";
      };

      version = lib.options.create {
        type = lib.types.string;
        description = "Version of mpc.";
      };
    };
  };

  config = {
    aux.foundation.stages.stage1.gcc.v46.cxx = {
      version = "4.6.4";

      src = builtins.fetchurl {
        url = "https://ftpmirror.gnu.org/gcc/gcc-${cfg.version}/gcc-core-${cfg.version}.tar.gz";
        sha256 = "173kdb188qg79pcz073cj9967rs2vzanyjdjyxy9v0xb0p5sad75";
      };

      cc = {
        src = builtins.fetchurl {
          url = "https://ftpmirror.gnu.org/gcc/gcc-${cfg.version}/gcc-g++-${cfg.version}.tar.gz";
          sha256 = "1fqqk5zkmdg4vmqzdmip9i42q6b82i3f6yc0n86n9021cr7ms2k9";
        };
      };

      gmp = {
        version = "4.3.2";

        src = builtins.fetchurl {
          url = "https://ftpmirror.gnu.org/gmp/gmp-${cfg.gmp.version}.tar.gz";
          sha256 = "15rwq54fi3s11izas6g985y9jklm3xprfsmym3v1g6xr84bavqvv";
        };
      };

      mpfr = {
        version = "2.4.2";

        src = builtins.fetchurl {
          url = "https://ftpmirror.gnu.org/mpfr/mpfr-${cfg.mpfr.version}.tar.gz";
          sha256 = "0dxn4904dra50xa22hi047lj8kkpr41d6vb9sd4grca880c7wv94";
        };
      };

      mpc = {
        version = "1.0.3";

        src = builtins.fetchurl {
          url = "https://ftpmirror.gnu.org/mpc/mpc-${cfg.mpc.version}.tar.gz";
          sha256 = "1hzci2zrrd7v3g1jk35qindq05hbl0bhjcyyisq9z209xb3fqzb1";
        };
      };

      package = let
        patches = [
          # Remove hardcoded NATIVE_SYSTEM_HEADER_DIR
          ./patches/no-system-headers.patch
        ];
      in
        builders.bash.build {
          name = "gcc-cxx-${cfg.version}";

          meta = stage1.gcc.meta;

          deps.build.host = [
            stage1.gcc.v46.package
            stage1.binutils.package
            stage1.gnumake.package
            stage1.gnupatch.package
            stage1.gnused.package
            stage1.gnugrep.package
            stage1.gawk.boot.package
            stage1.diffutils.package
            stage1.findutils.package
            stage1.gnutar.musl.package
            stage1.gzip.package
          ];

          script = ''
            # Unpack
            tar xzf ${cfg.src}
            tar xzf ${cfg.cc.src}
            tar xzf ${cfg.gmp.src}
            tar xzf ${cfg.mpfr.src}
            tar xzf ${cfg.mpc.src}
            cd gcc-${cfg.version}

            ln -s ../gmp-${cfg.gmp.version} gmp
            ln -s ../mpfr-${cfg.mpfr.version} mpfr
            ln -s ../mpc-${cfg.mpc.version} mpc

            # Patch
            ${lib.strings.concatMapSep "\n" (file: "patch -Np1 -i ${file}") patches}
            # doesn't recognise musl
            sed -i 's|"os/gnu-linux"|"os/generic"|' libstdc++-v3/configure.host

            # Configure
            export CC="gcc -Wl,-dynamic-linker -Wl,${stage1.musl.package}/lib/libc.so"
            export CFLAGS_FOR_TARGET="-Wl,-dynamic-linker -Wl,${stage1.musl.package}/lib/libc.so"
            export C_INCLUDE_PATH="${stage1.musl.package}/include"
            export CPLUS_INCLUDE_PATH="$C_INCLUDE_PATH"
            export LIBRARY_PATH="${stage1.musl.package}/lib"

            bash ./configure \
              --prefix=$out \
              --build=${platform.build} \
              --host=${platform.host} \
              --with-native-system-header-dir=${stage1.musl.package}/include \
              --with-build-sysroot=${stage1.musl.package} \
              --enable-languages=c,c++ \
              --disable-bootstrap \
              --disable-libmudflap \
              --disable-libstdcxx-pch \
              --disable-lto \
              --disable-multilib

            # Build
            make -j $NIX_BUILD_CORES

            # Install
            make -j $NIX_BUILD_CORES install
          '';
        };
    };
  };
}
