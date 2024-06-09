{
  lib,
  config,
}: let
  cfg = config.aux.foundation.stages.stage1.gcc.v46;

  platform = config.aux.platform;
  builders = config.aux.foundation.builders;

  stage1 = config.aux.foundation.stages.stage1;
in {
  options.aux.foundation.stages.stage1.gcc.v46 = {
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
  };

  config = {
    aux.foundation.stages.stage1.gcc.v46 = {
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
          name = "gcc-${cfg.version}";

          meta = stage1.gcc.meta;

          deps.build.host = [
            stage1.tinycc.musl.compiler.package
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

            # Configure
            export CC="tcc -B ${stage1.tinycc.musl.libs.package}/lib"
            export C_INCLUDE_PATH="${stage1.tinycc.musl.libs.package}/include:$(pwd)/mpfr/src"
            export CPLUS_INCLUDE_PATH="$C_INCLUDE_PATH"

            # Avoid "Link tests are not allowed after GCC_NO_EXECUTABLES"
            export lt_cv_shlibpath_overrides_runpath=yes
            export ac_cv_func_memcpy=yes
            export ac_cv_func_strerror=yes

            bash ./configure \
              --prefix=$out \
              --build=${platform.build} \
              --host=${platform.host} \
              --with-native-system-header-dir=${stage1.tinycc.musl.libs.package}/include \
              --with-build-sysroot=${stage1.tinycc.musl.libs.package}/include \
              --disable-bootstrap \
              --disable-decimal-float \
              --disable-libatomic \
              --disable-libcilkrts \
              --disable-libgomp \
              --disable-libitm \
              --disable-libmudflap \
              --disable-libquadmath \
              --disable-libsanitizer \
              --disable-libssp \
              --disable-libvtv \
              --disable-lto \
              --disable-lto-plugin \
              --disable-multilib \
              --disable-plugin \
              --disable-threads \
              --enable-languages=c \
              --enable-static \
              --disable-shared \
              --enable-threads=single \
              --disable-libstdcxx-pch \
              --disable-build-with-cxx

            # Build
            make -j $NIX_BUILD_CORES

            # Install
            make -j $NIX_BUILD_CORES install
          '';
        };
    };
  };
}
