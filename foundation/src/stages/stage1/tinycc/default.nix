{
  lib,
  config,
}: let
  cfg = config.aux.foundation.stages.stage1.tinycc;

  builders = config.aux.foundation.builders;

  stage1 = config.aux.foundation.stages.stage1;
in {
  includes = [
    ./boot.nix
    ./mes.nix
    ./musl.nix
  ];

  options.aux.foundation.stages.stage1.tinycc = {
    meta = {
      description = lib.options.create {
        type = lib.types.string;
        description = "Description for the package.";
        default.value = "Small, fast, embeddable C compiler and interpreter";
      };

      homepage = lib.options.create {
        type = lib.types.string;
        description = "Homepage for the package.";
        default.value = "https://repo.or.cz/w/tinycc.git";
      };

      license = lib.options.create {
        # TODO: Add a proper type for licenses.
        type = lib.types.attrs.any;
        description = "License for the package.";
        default.value = lib.licenses.lgpl21Only;
      };

      platforms = lib.options.create {
        type = lib.types.list.of lib.types.string;
        description = "Platforms the package supports.";
        default.value = ["i686-linux"];
      };
    };

    version = lib.options.create {
      type = lib.types.string;
      description = "Version of the package.";
    };
  };

  config = {
    aux.foundation.stages.stage1.tinycc = {
      version = "unstable-2023-04-20";
    };
  };
}
