{
  lib,
  config,
}: let
  cfg = config.aux.foundation.stages.stage1.gnutar.musl;

  platform = config.aux.platform;
  builders = config.aux.foundation.builders;

  stage1 = config.aux.foundation.stages.stage1;
in {
  options.aux.foundation.stages.stage1.gnutar.musl = {
    package = lib.options.create {
      type = lib.types.derivation;
      description = "The package to use for gnutar-musl.";
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
    aux.foundation.stages.stage1.gnutar.musl = {
      version = "1.12";

      src = builtins.fetchurl {
        url = "https://ftpmirror.gnu.org/tar/tar-${cfg.version}.tar.gz";
        sha256 = "xsN+iIsTbM76uQPFEUn0t71lnWnUrqISRfYQU6V6pgo=";
      };

      package = builders.bash.boot.build {
        name = "gnutar-musl-${cfg.version}";

        meta = stage1.gnutar.meta;

        deps.build.host = [
          stage1.tinycc.musl.compiler.package
          stage1.gnumake.boot.package
          stage1.gnused.boot.package
          stage1.gnugrep.package
        ];

        script = ''
          # Unpack
          ungz --file ${cfg.src} --output tar.tar
          untar --file tar.tar
          rm tar.tar
          cd tar-${cfg.version}

          # Configure
          export CC="tcc -B ${stage1.tinycc.musl.libs.package}/lib"
          export LD=tcc
          export ac_cv_sizeof_unsigned_long=4
          export ac_cv_sizeof_long_long=8
          export ac_cv_header_netdb_h=no
          bash ./configure \
            --prefix=$out \
            --build=${platform.build} \
            --host=${platform.host} \
            --disable-nls

          # Build
          make AR="tcc -ar"

          # Install
          make install

        '';
      };
    };
  };
}
