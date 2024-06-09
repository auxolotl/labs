{
  lib,
  config,
}: let
  cfg = config.aux.foundation.stages.stage1.gcc.v8;

  platform = config.aux.platform;
  builders = config.aux.foundation.builders;

  stage1 = config.aux.foundation.stages.stage1;
in {
  options.aux.foundation.stages.stage1.gcc.v8 = {
    package = lib.options.create {
      type = lib.types.derivation;
      description = "The package to use for gcc.";
    };

    version = lib.options.create {
      type = lib.types.string;
      description = "Version of the package.";
    };

    src = lib.options.create {
      type = lib.types.derivation;
      description = "Source for the package.";
    };

    cc = {
      src = lib.options.create {
        type = lib.types.derivation;
        description = "The cc source for the package.";
      };
    };

    gmp = {
      src = lib.options.create {
        type = lib.types.derivation;
        description = "The gmp source for the package.";
      };

      version = lib.options.create {
        type = lib.types.string;
        description = "Version of gmp.";
      };
    };

    mpfr = {
      src = lib.options.create {
        type = lib.types.derivation;
        description = "The mpfr source for the package.";
      };

      version = lib.options.create {
        type = lib.types.string;
        description = "Version of mpfr.";
      };
    };

    mpc = {
      src = lib.options.create {
        type = lib.types.derivation;
        description = "The mpc source for the package.";
      };

      version = lib.options.create {
        type = lib.types.string;
        description = "Version of mpc.";
      };
    };

    isl = {
      src = lib.options.create {
        type = lib.types.derivation;
        description = "The isl source for the package.";
      };
      version = lib.options.create {
        type = lib.types.string;
        description = "Version of isl.";
      };
    };
  };

  config = {
    aux.foundation.stages.stage1.gcc.v8 = {
      version = "8.5.0";

      src = builtins.fetchurl {
        url = "https://ftpmirror.gnu.org/gcc/gcc-${cfg.version}/gcc-${cfg.version}.tar.xz";
        sha256 = "0wiEGlEbuDCmEAOXsAQtskzhH2Qtq26m7kSELlMl7VA=";
      };

      gmp = {
        # last version to compile with gcc 4.6
        version = "6.2.1";
        src = builtins.fetchurl {
          url = "https://ftpmirror.gnu.org/gmp/gmp-${cfg.gmp.version}.tar.xz";
          sha256 = "/UgpkSzd0S+EGBw0Ucx1K+IkZD6H+sSXtp7d2txJtPI=";
        };
      };

      mpfr = {
        version = "4.2.1";
        src = builtins.fetchurl {
          url = "https://ftpmirror.gnu.org/mpfr/mpfr-${cfg.mpfr.version}.tar.xz";
          sha256 = "J3gHNTpnJpeJlpRa8T5Sgp46vXqaW3+yeTiU4Y8fy7I=";
        };
      };

      mpc = {
        version = "1.3.1";
        src = builtins.fetchurl {
          url = "https://ftpmirror.gnu.org/mpc/mpc-${cfg.mpc.version}.tar.gz";
          sha256 = "q2QkkvXPiCt0qgy3MM1BCoHtzb7IlRg86TDnBsHHWbg=";
        };
      };

      isl = {
        version = "0.24";
        src = builtins.fetchurl {
          url = "https://gcc.gnu.org/pub/gcc/infrastructure/isl-${cfg.isl.version}.tar.bz2";
          sha256 = "/PeN2WVsEOuM+fvV9ZoLawE4YgX+GTSzsoegoYmBRcA=";
        };
      };

      package = builders.bash.build {
        name = "gcc-${cfg.version}";

        meta = stage1.gcc.meta;

        deps.build.host = [
          stage1.gcc.v46.cxx.package
          stage1.binutils.package
          stage1.gnumake.package
          stage1.gnused.package
          stage1.gnugrep.package
          stage1.gawk.boot.package
          stage1.diffutils.package
          stage1.findutils.package
          stage1.gnutar.package
          stage1.gzip.package
          stage1.bzip2.package
          stage1.xz.package
        ];

        script = ''
          # Unpack
          tar xf ${cfg.src}
          tar xf ${cfg.gmp.src}
          tar xf ${cfg.mpfr.src}
          tar xf ${cfg.mpc.src}
          tar xf ${cfg.isl.src}
          cd gcc-${cfg.version}

          ln -s ../gmp-${cfg.gmp.version} gmp
          ln -s ../mpfr-${cfg.mpfr.version} mpfr
          ln -s ../mpc-${cfg.mpc.version} mpc
          ln -s ../isl-${cfg.isl.version} isl

          # Patch
          # doesn't recognise musl
          sed -i 's|"os/gnu-linux"|"os/generic"|' libstdc++-v3/configure.host

          # Configure
          export CC="gcc -Wl,-dynamic-linker -Wl,${stage1.musl.package}/lib/libc.so"
          export CXX="g++ -Wl,-dynamic-linker -Wl,${stage1.musl.package}/lib/libc.so"
          export CFLAGS_FOR_TARGET="-Wl,-dynamic-linker -Wl,${stage1.musl.package}/lib/libc.so"
          export C_INCLUDE_PATH="${stage1.musl.package}/include"
          export CPLUS_INCLUDE_PATH="$C_INCLUDE_PATH"
          export LIBRARY_PATH="${stage1.musl.package}/lib"

          bash ./configure \
            --prefix=$out \
            --build=${platform.build} \
            --host=${platform.host} \
            --with-native-system-header-dir=/include \
            --with-sysroot=${stage1.musl.package} \
            --enable-languages=c,c++ \
            --disable-bootstrap \
            --disable-libmpx \
            --disable-libsanitizer \
            --disable-lto \
            --disable-multilib \
            --disable-plugin

          # Build
          make -j $NIX_BUILD_CORES

          # Install
          make -j $NIX_BUILD_CORES install-strip

        '';
      };
    };
  };
}
