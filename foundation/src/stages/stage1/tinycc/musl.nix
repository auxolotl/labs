args @ {
  lib,
  config,
}: let
  cfg = config.aux.foundation.stages.stage1.tinycc.musl;

  builders = config.aux.foundation.builders;

  stage1 = config.aux.foundation.stages.stage1;

  pname = "tinycc-musl";

  helpers = lib.fp.withDynamicArgs (import ./helpers.nix) args;
in {
  options.aux.foundation.stages.stage1.tinycc.musl = {
    compiler = {
      package = lib.options.create {
        type = lib.types.package;
        description = "The package to use for the tinycc-musl compiler.";
      };
    };

    libs = {
      package = lib.options.create {
        type = lib.types.package;
        description = "The package to use for the tinycc-musl libs.";
      };
    };

    src = lib.options.create {
      type = lib.types.string;
      description = "Source for the package.";
    };

    revision = lib.options.create {
      type = lib.types.string;
      description = "Revision of the package.";
    };
  };

  config = {
    aux.foundation.stages.stage1.tinycc.musl = let
      patches = [
        ./patches/ignore-duplicate-symbols.patch
        ./patches/ignore-static-inside-array.patch
        ./patches/static-link.patch
      ];

      tinycc-musl = builders.bash.boot.build {
        name = "${pname}-${stage1.tinycc.version}";

        meta = stage1.tinycc.meta;

        deps.build.host = [
          stage1.tinycc.boot.compiler.package
          stage1.gnupatch.package
          stage1.gnutar.boot.package
          stage1.gzip.package
        ];

        script = ''
          # Unpack
          tar xzf ${cfg.src}
          cd tinycc-${builtins.substring 0 7 cfg.revision}

          # Patch
          ${lib.strings.concatMapSep "\n" (file: "patch -Np0 -i ${file}") patches}

          # Configure
          touch config.h

          # Build
          # We first have to recompile using tcc-0.9.26 as tcc-0.9.27 is not self-hosting,
          # but when linked with musl it is.
          ln -s ${stage1.musl.boot.package}/lib/libtcc1.a ./libtcc1.a

          tcc \
            -B ${stage1.tinycc.boot.libs.package}/lib \
            -DC2STR \
            -o c2str \
            conftest.c
          ./c2str include/tccdefs.h tccdefs_.h

          tcc -v \
            -static \
            -o tcc-musl \
            -D TCC_TARGET_I386=1 \
            -D CONFIG_TCCDIR=\"\" \
            -D CONFIG_TCC_CRTPREFIX=\"{B}\" \
            -D CONFIG_TCC_ELFINTERP=\"/musl/loader\" \
            -D CONFIG_TCC_LIBPATHS=\"{B}\" \
            -D CONFIG_TCC_SYSINCLUDEPATHS=\"${stage1.musl.boot.package}/include\" \
            -D TCC_LIBGCC=\"libc.a\" \
            -D TCC_LIBTCC1=\"libtcc1.a\" \
            -D CONFIG_TCC_STATIC=1 \
            -D CONFIG_USE_LIBGCC=1 \
            -D TCC_VERSION=\"0.9.27\" \
            -D ONE_SOURCE=1 \
            -D TCC_MUSL=1 \
            -D CONFIG_TCC_PREDEFS=1 \
            -D CONFIG_TCC_SEMLOCK=0 \
            -B . \
            -B ${stage1.tinycc.boot.libs.package}/lib \
            tcc.c
          # libtcc1.a
          rm -f libtcc1.a
          tcc -c -D HAVE_CONFIG_H=1 lib/libtcc1.c
          tcc -ar cr libtcc1.a libtcc1.o

          # Rebuild tcc-musl with itself
          ./tcc-musl \
            -v \
            -static \
            -o tcc-musl \
            -D TCC_TARGET_I386=1 \
            -D CONFIG_TCCDIR=\"\" \
            -D CONFIG_TCC_CRTPREFIX=\"{B}\" \
            -D CONFIG_TCC_ELFINTERP=\"/musl/loader\" \
            -D CONFIG_TCC_LIBPATHS=\"{B}\" \
            -D CONFIG_TCC_SYSINCLUDEPATHS=\"${stage1.musl.boot.package}/include\" \
            -D TCC_LIBGCC=\"libc.a\" \
            -D TCC_LIBTCC1=\"libtcc1.a\" \
            -D CONFIG_TCC_STATIC=1 \
            -D CONFIG_USE_LIBGCC=1 \
            -D TCC_VERSION=\"0.9.27\" \
            -D ONE_SOURCE=1 \
            -D TCC_MUSL=1 \
            -D CONFIG_TCC_PREDEFS=1 \
            -D CONFIG_TCC_SEMLOCK=0 \
            -B . \
            -B ${stage1.musl.boot.package}/lib \
            tcc.c
          # libtcc1.a
          rm -f libtcc1.a
          ./tcc-musl -c -D HAVE_CONFIG_H=1 lib/libtcc1.c
          ./tcc-musl -c -D HAVE_CONFIG_H=1 lib/alloca.S
          ./tcc-musl -ar cr libtcc1.a libtcc1.o alloca.o

          # Install
          install -D tcc-musl $out/bin/tcc
          install -Dm444 libtcc1.a $out/lib/libtcc1.a
        '';
      };
    in {
      revision = "fd6d2180c5c801bb0b4c5dde27d61503059fc97d";

      src = builtins.fetchurl {
        url = "https://repo.or.cz/tinycc.git/snapshot/${cfg.revision}.tar.gz";
        sha256 = "R81SNbEmh4s9FNQxCWZwUiMCYRkkwOHAdRf0aMnnRiA=";
      };

      compiler.package = builders.bash.boot.build {
        name = "${pname}-${stage1.tinycc.version}-compiler";

        meta = stage1.tinycc.meta;

        script = ''
          install -D ${tinycc-musl}/bin/tcc $out/bin/tcc
        '';
      };

      libs.package = builders.bash.boot.build {
        name = "${pname}-${stage1.tinycc.version}-libs";

        meta = stage1.tinycc.meta;

        script = ''
          mkdir $out
          cp -r ${stage1.musl.boot.package}/* $out
          chmod +w $out/lib/libtcc1.a
          cp ${tinycc-musl}/lib/libtcc1.a $out/lib/libtcc1.a

        '';
      };
    };
  };
}
