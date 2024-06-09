{
  lib,
  config,
}: let
  cfg = config.aux.foundation.stages.stage1.binutils;

  platform = config.aux.platform;
  builders = config.aux.foundation.builders;

  stage1 = config.aux.foundation.stages.stage1;
in {
  options.aux.foundation.stages.stage1.binutils = {
    meta = {
      description = lib.options.create {
        type = lib.types.string;
        description = "Description for the package.";
        default.value = "Tools for manipulating binaries (linker, assembler, etc.)";
      };

      homepage = lib.options.create {
        type = lib.types.string;
        description = "Homepage for the package.";
        default.value = "https://www.gnu.org/software/binutils";
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
    };

    package = lib.options.create {
      type = lib.types.derivation;
      description = "The package to use for binutils.";
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
    aux.foundation.stages.stage1.binutils = {
      version = "2.41";

      src = builtins.fetchurl {
        url = "https://ftpmirror.gnu.org/binutils/binutils-${cfg.version}.tar.xz";
        sha256 = "rppXieI0WeWWBuZxRyPy0//DHAMXQZHvDQFb3wYAdFA=";
      };

      package = let
        patches = [
          # Make binutils output deterministic by default.
          ./patches/deterministic.patch
        ];

        configureFlags = [
          "--prefix=${builtins.placeholder "out"}"
          "--build=${platform.build}"
          "--host=${platform.host}"
          "--with-sysroot=/"
          "--enable-deterministic-archives"
          # depends on bison
          "--disable-gprofng"

          # Turn on --enable-new-dtags by default to make the linker set
          # RUNPATH instead of RPATH on binaries.  This is important because
          # RUNPATH can be overridden using LD_LIBRARY_PATH at runtime.
          "--enable-new-dtags"

          # By default binutils searches $libdir for libraries. This brings in
          # libbfd and libopcodes into a default visibility. Drop default lib
          # path to force users to declare their use of these libraries.
          "--with-lib-path=:"
        ];
      in
        builders.bash.boot.build {
          name = "binutils-${cfg.version}";

          meta = cfg.meta;

          deps.build.host = [
            stage1.tinycc.musl.compiler.package
            stage1.gnumake.package
            stage1.gnupatch.package
            stage1.gnused.package
            stage1.gnugrep.package
            stage1.gnutar.musl.package
            stage1.gzip.package
            stage1.gawk.package
            stage1.diffutils.package
            stage1.xz.package
          ];

          script = ''
            # Unpack
            cp ${cfg.src} binutils.tar.xz
            unxz binutils.tar.xz
            tar xf binutils.tar
            rm binutils.tar
            cd binutils-${cfg.version}

            # Patch
            ${lib.strings.concatMapSep "\n" (file: "patch -Np1 -i ${file}") patches}
            sed -i 's|/bin/sh|${stage1.bash.boot.package}/bin/bash|' \
              missing install-sh mkinstalldirs
            # see libtool's 74c8993c178a1386ea5e2363a01d919738402f30
            sed -i 's/| \$NL2SP/| sort | $NL2SP/' ltmain.sh
            # alias makeinfo to true
            mkdir aliases
            ln -s ${stage1.coreutils.package}/bin/true aliases/makeinfo
            export PATH="$(pwd)/aliases/:$PATH"

            # Configure
            export CC="tcc -B ${stage1.tinycc.musl.libs.package}/lib"
            export AR="tcc -ar"
            export lt_cv_sys_max_cmd_len=32768
            export CFLAGS="-D__LITTLE_ENDIAN__=1"
            bash ./configure ${builtins.concatStringsSep " " configureFlags}

            # Build
            make -j $NIX_BUILD_CORES all-libiberty all-gas all-bfd all-libctf all-zlib all-gprof
            make all-ld # race condition on ld/.deps/ldwrite.Po, serialize
            make -j $NIX_BUILD_CORES

            # Install
            make -j $NIX_BUILD_CORES install
          '';
        };
    };
  };
}
