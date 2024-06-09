{
  lib,
  config,
}: let
  cfg = config.aux.foundation.stages.stage1.gnumake;

  platform = config.aux.platform;
  builders = config.aux.foundation.builders;

  stage1 = config.aux.foundation.stages.stage1;
in {
  includes = [
    ./boot.nix
  ];

  options.aux.foundation.stages.stage1.gnumake = {
    meta = {
      description = lib.options.create {
        type = lib.types.string;
        description = "Description for the package.";
        default.value = "A tool to control the generation of non-source files from sources";
      };

      homepage = lib.options.create {
        type = lib.types.string;
        description = "Homepage for the package.";
        default.value = "https://www.gnu.org/software/make";
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
      description = "The package to use for gnumake.";
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
    aux.foundation.stages.stage1.gnumake = {
      version = "4.4.1";

      src = builtins.fetchurl {
        url = "https://ftpmirror.gnu.org/make/make-${cfg.version}.tar.gz";
        sha256 = "3Rb7HWe/q3mnL16DkHNcSePo5wtJRaFasfgd23hlj7M=";
      };

      package = let
        patches = [
          # Replaces /bin/sh with sh, see patch file for reasoning
          ./patches/0001-No-impure-bin-sh.patch
          # Purity: don't look for library dependencies (of the form `-lfoo') in /lib
          # and /usr/lib. It's a stupid feature anyway. Likewise, when searching for
          # included Makefiles, don't look in /usr/include and friends.
          ./patches/0002-remove-impure-dirs.patch
        ];
      in
        builders.bash.boot.build {
          name = "gnumake-${cfg.version}";

          meta = cfg.meta;

          deps.build.host = [
            stage1.tinycc.musl.compiler.package
            stage1.gnumake.boot.package
            stage1.gnupatch.package
            stage1.gnused.package
            stage1.gnugrep.package
            stage1.gawk.boot.package
            stage1.gnutar.boot.package
            stage1.gzip.package
          ];

          script = ''
            # Unpack
            tar xzf ${cfg.src}
            cd make-${cfg.version}

            # Patch
            ${lib.strings.concatMapSep "\n" (file: "patch -Np1 -i ${file}") patches}

            # Configure
            export CC="tcc -B ${stage1.tinycc.musl.libs.package}/lib"
            export LD=tcc
            bash ./configure \
              --prefix=$out \
              --build=${platform.build} \
              --host=${platform.host}

            # Build
            make AR="tcc -ar"

            # Install
            make install
          '';
        };
    };
  };
}
