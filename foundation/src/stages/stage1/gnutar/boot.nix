{
  lib,
  config,
}: let
  cfg = config.aux.foundation.stages.stage1.gnutar.boot;

  platform = config.aux.platform;
  builders = config.aux.foundation.builders;

  stage1 = config.aux.foundation.stages.stage1;
in {
  options.aux.foundation.stages.stage1.gnutar.boot = {
    package = lib.options.create {
      type = lib.types.derivation;
      description = "The package to use for gnutar-boot.";
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
    aux.foundation.stages.stage1.gnutar.boot = {
      version = "1.12";

      src = builtins.fetchurl {
        url = "https://ftpmirror.gnu.org/tar/tar-${cfg.version}.tar.gz";
        sha256 = "02m6gajm647n8l9a5bnld6fnbgdpyi4i3i83p7xcwv0kif47xhy6";
      };

      package = let
      in
        builders.bash.boot.build {
          name = "gnutar-boot-${cfg.version}";

          meta = stage1.gnutar.meta;

          deps.build.host = [
            stage1.tinycc.mes.compiler.package
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

            chmod 0755 missing mkinstalldirs install-sh

            # Configure
            export CC="tcc -B ${stage1.tinycc.mes.libs.package}/lib"
            bash ./configure \
              --build=${platform.build} \
              --host=${platform.host} \
              --disable-nls \
              --prefix=$out

            # Build
            make AR="tcc -ar"

            # Install
            make install
          '';
        };
    };
  };
}
