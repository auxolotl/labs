{
  lib,
  config,
}: let
  cfg = config.aux.foundation.stages.stage1.nyacc;

  builders = config.aux.foundation.builders;

  stage0 = config.aux.foundation.stages.stage0;

  pname = "nyacc";
  version = "1.00.2";
in {
  options.aux.foundation.stages.stage1.nyacc = {
    meta = {
      description = lib.options.create {
        type = lib.types.string;
        description = "Description for the package.";
        default.value = "Modules for generating parsers and lexical analyzers.";
      };

      homepage = lib.options.create {
        type = lib.types.string;
        description = "Homepage for the package.";
        default.value = "https://savannah.nongnu.org/projects/nyacc";
      };

      license = lib.options.create {
        # TODO: Add a proper type for licenses.
        type = lib.types.attrs.any;
        description = "License for the package.";
        default.value = lib.licenses.lgpl3Plus;
      };

      platforms = lib.options.create {
        type = lib.types.list.of lib.types.string;
        description = "Platforms the package supports.";
        default.value = ["i686-linux"];
      };
    };

    src = lib.options.create {
      type = lib.types.derivation;
      description = "Source for the package.";
    };

    package = lib.options.create {
      type = lib.types.derivation;
      description = "The package to use for nyacc.";
    };
  };

  config = {
    aux.foundation.stages.stage1.nyacc = {
      src = builtins.fetchurl {
        url = "https://mirror.easyname.at/nongnu/nyacc/nyacc-${version}.tar.gz";
        sha256 = "065ksalfllbdrzl12dz9d9dcxrv97wqxblslngsc6kajvnvlyvpk";
      };

      package = builders.kaem.build {
        name = "${pname}-${version}";
        meta = cfg.meta;
        src = cfg.src;

        script = ''
          ungz --file ${cfg.src} --output nyacc.tar
          mkdir -p ''${out}/share
          cd ''${out}/share
          untar --file ''${NIX_BUILD_TOP}/nyacc.tar
        '';

        extras = {
          guileModule = "${cfg.package}/share/${pname}-${version}/module";
        };
      };
    };
  };
}
