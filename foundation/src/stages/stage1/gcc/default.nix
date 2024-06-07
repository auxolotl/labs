{
  lib,
  config,
}: let
  cfg = config.aux.foundation.stages.stage1.gcc;

  platform = config.aux.platform;
  builders = config.aux.foundation.builders;

  stage1 = config.aux.foundation.stages.stage1;
in {
  includes = [
    ./v4.6.nix
  ];

  options.aux.foundation.stages.stage1.gcc = {
    meta = {
      description = lib.options.create {
        type = lib.types.string;
        description = "Description for the package.";
        default.value = "GNU Compiler Collection.";
      };

      homepage = lib.options.create {
        type = lib.types.string;
        description = "Homepage for the package.";
        default.value = "https://gcc.gnu.org";
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
  };
}
